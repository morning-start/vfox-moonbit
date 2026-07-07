--- 安装后处理：下载核心库并执行 moon bundle 编译
--- 参考: https://vfox.dev/plugins/create/howto.html#postinstall
--- @param ctx table 上下文
--- @field ctx.rootPath string SDK 安装根目录
function PLUGIN:PostInstall(ctx)
    local http = require("http")
    local util = require("util")
    local archiver = require("archiver")
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

    -- 下载并编译核心库
    local encoded_version = util.encode_version(version)
    local ext = util.get_archive_ext()
    local core_filename = "core-" .. encoded_version .. ext
    local core_url = util.CLI_MOONBIT .. "/cores/" .. core_filename
    local core_archive = path .. "/core_archive" .. ext

    log.info("正在下载 MoonBit 核心库...")
    local dl_err = http.download_file({ url = core_url }, core_archive)
    if dl_err ~= nil then
        log.warn("核心库下载失败 (" .. tostring(dl_err) .. ")，跳过 bundle 步骤。")
        log.warn("URL: " .. core_url)
        return
    end

    -- 解压核心库到 lib 目录
    local lib_dir = path .. "/lib"
    log.info("正在解压核心库...")
    archiver.decompress(core_archive, lib_dir)

    -- 删除临时文件
    os.remove(core_archive)

    -- 执行 moon bundle 编译核心库
    local core_dir = lib_dir .. "/core"
    if not file.exists(core_dir) then
        log.warn("核心库解压后未找到 core 目录，跳过 bundle 步骤。")
        return
    end

    log.info("正在编译 MoonBit 核心库...")

    local bin_dir = path .. "/bin"
    local moon_bin = bin_dir .. "/moon"
    if RUNTIME.osType == "windows" then
        moon_bin = moon_bin .. ".exe"
    end

    -- bundle --all
    local ok, result = pcall(cmd.exec, moon_bin .. " bundle --warn-list -a --all", {
        cwd = core_dir,
    })
    if not ok then
        log.warn("moon bundle --all 执行失败: " .. tostring(result))
    end

    -- bundle --target wasm-gc
    ok, result = pcall(cmd.exec, moon_bin .. " bundle --warn-list -a --target wasm-gc --quiet", {
        cwd = core_dir,
    })
    if not ok then
        log.warn("moon bundle --target wasm-gc 执行失败: " .. tostring(result))
    end

    -- nightly 版本额外编译 LLVM 后端（见官方 unix.sh）
    if version == "nightly" then
        ok, result = pcall(cmd.exec, moon_bin .. " bundle --warn-list -a --target llvm", {
            cwd = core_dir,
        })
        if not ok then
            log.warn("moon bundle --target llvm 执行失败: " .. tostring(result))
        end
    end

    log.info("MoonBit " .. version .. " 安装完成。")
end