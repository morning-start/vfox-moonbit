--- 安装后处理：下载核心库并执行 moon bundle 编译
--- 参考: https://vfox.dev/plugins/create/howto.html#postinstall
--- @param ctx table 上下文
--- @field ctx.rootPath string SDK 安装根目录
function PLUGIN:PostInstall(ctx)
    local util = require("util")
    local file = require("file")
    local cmd = require("cmd")
    local log = require("log")

    local sdkInfo = ctx.sdkInfo[PLUGIN.name]
    local path = sdkInfo.path
    local version = sdkInfo.version

    -- 确保 bin 目录中的可执行文件有执行权限（Unix 系统）
    if RUNTIME.osType ~= "windows" then
        pcall(cmd.exec, "chmod -R +x " .. path .. "/bin/")
        -- 显式确保 internal/tcc 可执行（见官方 unix.sh）
        pcall(cmd.exec, "chmod +x " .. path .. "/bin/internal/tcc")
    end

    local bin_dir = path .. "/bin"
    local moon_bin = bin_dir .. "/moon"
    if RUNTIME.osType == "windows" then
        moon_bin = moon_bin .. ".exe"
    end

    -- 核心库目标位置：<MOON_HOME>/lib/core/
    -- 与官方安装脚本行为一致
    local lib_dir = path .. "/lib"
    local core_dir = lib_dir .. "/core"

    -- 1) 优先使用附加机制提供的核心库（vfox 兼容）
    local core_sdk = ctx.sdkInfo["core"]
    if core_sdk ~= nil and file.exists(core_sdk.path) then
        core_dir = core_sdk.path
        log.info("使用附加机制提供的核心库")
    end

    -- 2) 如果核心库不存在，直接下载到标准位置
    if not file.exists(core_dir) then
        log.info("正在下载 MoonBit 核心库...")

        local encoded_version = util.encode_version(version)
        local ext = util.get_archive_ext()
        local core_url = util.CLI_MOONBIT .. "/cores/core-" .. encoded_version .. ext

        if RUNTIME.osType == "windows" then
            -- Windows: 用 PowerShell 下载并解压
            local tmp_archive = path .. "/core" .. ext
            pcall(cmd.exec, 'if not exist "' .. lib_dir .. '" mkdir "' .. lib_dir .. '"')

            local ok, err = pcall(cmd.exec,
                "powershell -NoProfile -Command \"Invoke-WebRequest -Uri '"
                .. core_url .. "' -OutFile '" .. tmp_archive .. "' -UseBasicParsing\""
            )
            if ok then
                ok, err = pcall(cmd.exec,
                    "powershell -NoProfile -Command \"Expand-Archive -Path '"
                    .. tmp_archive .. "' -DestinationPath '" .. lib_dir .. "' -Force\""
                )
                pcall(cmd.exec,
                    "powershell -NoProfile -Command \"Remove-Item -Path '"
                    .. tmp_archive .. "' -Force\""
                )
            end
            if not ok then
                log.warn("核心库下载或解压失败: " .. tostring(err))
                return
            end
        else
            -- Unix: 用 curl 下载 + tar 解压
            pcall(cmd.exec, 'mkdir -p "' .. lib_dir .. '"')
            local ok, err = pcall(cmd.exec,
                'curl -fsSL "' .. core_url .. '" | tar -xz -C "' .. lib_dir .. '"'
            )
            if not ok then
                log.warn("核心库下载或解压失败: " .. tostring(err))
                return
            end
        end

        log.info("核心库下载完成")
    end

    -- 3) 编译核心库
    if file.exists(core_dir) then
        log.info("正在编译 MoonBit 核心库...")

        local function bundle(args)
            local ok, result = pcall(cmd.exec, moon_bin .. " bundle --warn-list -a " .. args, {
                cwd = core_dir,
            })
            if not ok then
                log.warn("moon bundle " .. args .. " 执行失败: " .. tostring(result))
            end
            return ok
        end

        -- bundle --all（默认目标）
        bundle("--all")

        -- bundle --target wasm-gc（WebAssembly GC 支持）
        bundle("--target wasm-gc --quiet")

        -- nightly 版本额外编译 LLVM 后端（见官方 unix.sh）
        if version == "nightly" then
            bundle("--target llvm")
        end

        log.info("MoonBit " .. version .. " 安装完成。")
    else
        log.warn("核心库未找到，跳过 bundle 步骤。")
    end
end