--- 安装后处理：下载核心库并执行 moon bundle 编译
--- 参考: https://vfox.dev/plugins/create/howto.html#postinstall
--- @param ctx table 上下文
--- @field ctx.rootPath string SDK 安装根目录
function PLUGIN:PostInstall(ctx)
    local util = require("util")
    local file = require("file")
    local cmd = require("cmd")
    local log = require("log")
    local http = require("http")
    local archiver = require("archiver")

    local sdkInfo = ctx.sdkInfo[PLUGIN.name]
    local path = sdkInfo.path
    local version = sdkInfo.version

    local bin_dir = file.join_path(path, "bin")
    local lib_dir = file.join_path(path, "lib")
    local core_dir = file.join_path(lib_dir, "core")
    local moon_bin = file.join_path(bin_dir, "moon")
    if RUNTIME.osType == "windows" then
        moon_bin = moon_bin .. ".exe"
    end

    local function run_host_command(windows_cmd, unix_cmd)
        local command = (RUNTIME.osType == "windows") and windows_cmd or unix_cmd
        return pcall(cmd.exec, command)
    end

    local function ensure_dir(dir)
        return run_host_command(
            'powershell -NoProfile -Command "New-Item -ItemType Directory -Force -Path \'' .. dir .. '\' | Out-Null"',
            'mkdir -p "' .. dir .. '"'
        )
    end

    local function remove_dir(dir)
        if not file.exists(dir) then
            return true
        end
        return run_host_command(
            'powershell -NoProfile -Command "Remove-Item -Force -Recurse -Path \'' .. dir .. '\'"',
            'rm -rf "' .. dir .. '"'
        )
    end

    local function make_unix_binaries_executable()
        if RUNTIME.osType == "windows" then
            return true
        end

        local ok, err = pcall(cmd.exec, "chmod -R +x " .. bin_dir .. "/")
        if not ok then
            return ok, err
        end
        return pcall(cmd.exec, "chmod +x " .. file.join_path(bin_dir, "internal", "tcc"))
    end

    local function extract_core_archive(archive)
        if RUNTIME.osType == "windows" then
            local _, err = archiver.decompress(archive, lib_dir)
            if err ~= nil then
                return false, "解压核心库失败: " .. tostring(err)
            end
            return true
        end

        local ok, err = pcall(cmd.exec, 'tar xf "' .. archive .. '" --directory="' .. lib_dir .. '"')
        if not ok then
            return false, "解压核心库失败: " .. tostring(err)
        end
        return true
    end

    local function download_and_extract_core()
        local encoded_version = util.encode_version(version)
        local ext = util.get_archive_ext()
        local archive = file.join_path(path, "core" .. ext)
        local core_url = util.CLI_MOONBIT .. "/cores/core-" .. encoded_version .. ext

        local ok, err = ensure_dir(lib_dir)
        if not ok then
            return ok, "创建 lib 目录失败: " .. tostring(err)
        end

        ok, err = remove_dir(core_dir)
        if not ok then
            return ok, "删除旧核心库失败: " .. tostring(err)
        end

        _, err = http.download_file({ url = core_url }, archive)
        if err ~= nil then
            pcall(os.remove, archive)
            return false, "下载核心库失败: " .. tostring(err)
        end

        ok, err = extract_core_archive(archive)
        pcall(os.remove, archive)
        if not ok then
            return false, err
        end

        return true
    end

    local function bundle_core()
        local path_sep = (RUNTIME.osType == "windows") and ";" or ":"
        local bundle_env = {
            MOON_HOME = path,
            PATH = bin_dir .. path_sep .. (os.getenv("PATH") or ""),
        }

        local function bundle(args)
            local ok, result = pcall(cmd.exec, moon_bin .. " bundle --warn-list -a " .. args, {
                cwd = core_dir,
                env = bundle_env,
            })
            if not ok then
                log.warn("moon bundle " .. args .. " 执行失败: " .. tostring(result))
            end
            return ok
        end

        bundle("--all")
        bundle("--target wasm-gc --quiet")
        if version == "nightly" then
            bundle("--target llvm")
        end
    end

    -- 确保 bin 目录中的可执行文件有执行权限（Unix 系统）
    do
        local ok, err = make_unix_binaries_executable()
        if not ok then
            log.warn("设置可执行权限失败: " .. tostring(err))
        end
    end

    -- 1) 按官方安装脚本处理核心库：删除已有 core，再下载并解压到 <MOON_HOME>/lib
    log.info("正在下载 MoonBit 核心库...")
    local ok, err = download_and_extract_core()
    if not ok then
        log.warn(tostring(err))
        return
    end

    log.info("核心库下载完成")

    -- 2) 编译核心库
    if file.exists(core_dir) then
        log.info("正在编译 MoonBit 核心库...")
        bundle_core()
        log.info("MoonBit " .. version .. " 安装完成。")
        log.info("请手动运行 `moon update` 更新缓存。")
    else
        log.warn("核心库未找到，跳过 bundle 步骤。")
    end
end
