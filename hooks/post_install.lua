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

    -- vfox 已自动下载并解压附加的核心库
    local core_sdk = ctx.sdkInfo["core"]
    if core_sdk == nil then
        log.warn("核心库未找到，跳过 bundle 步骤。")
        return
    end
    local core_dir = core_sdk.path
    if not file.exists(core_dir) then
        log.warn("核心库解压后未找到目录，跳过 bundle 步骤。")
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