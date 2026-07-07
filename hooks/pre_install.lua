--- 返回指定版本的预安装信息（下载地址、校验和等）
--- 参考: https://vfox.dev/plugins/create/howto.html#preinstall
--- @param ctx table 上下文
--- @field ctx.version string 用户请求的版本
--- @return table 版本信息和下载地址
function PLUGIN:PreInstall(ctx)
    local http = require("http")
    local util = require("util")

    local version = ctx.version

    -- 检测平台支持
    local platform = util.get_platform()
    if platform == nil then
        error("不支持当前平台: " .. RUNTIME.osType .. " " .. RUNTIME.archType
            .. "。支持的平台: " .. util.get_supported_platforms())
    end

    -- 处理 "latest" 和部分版本匹配（合并为一次 API 调用）
    -- nightly 版本直接使用，无需解析
    local needs_resolve = (version ~= "nightly" and (version == "latest" or not version:find("%+")))
    local available = nil

    if needs_resolve then
        available = self:Available({ args = {} })
        if #available == 0 then
            error("无法获取可用版本列表")
        end
    end

    if version == "latest" then
        version = available[1].version
    elseif version ~= "nightly" and not version:find("%+") and available then
        local resolved = util.resolve_version(version, available)
        if resolved then
            version = resolved
        else
            error("找不到匹配的版本: " .. version)
        end
    end

    -- 是否安装开发版本
    local dev_suffix = ""
    if os.getenv("MOONBIT_INSTALL_DEV") == "1" then
        dev_suffix = "-dev"
    end

    -- 构建下载 URL
    local encoded_version = util.encode_version(version)
    local ext = util.get_archive_ext()
    local filename = "moonbit-" .. platform .. dev_suffix .. ext
    local url = util.CLI_MOONBIT .. "/binaries/" .. encoded_version .. "/" .. filename

    -- 尝试获取 SHA256 校验和
    local sha256 = nil
    local sha256_url = util.CLI_MOONBIT .. "/binaries/" .. encoded_version .. "/moonbit-" .. platform .. dev_suffix .. ".sha256"
    local resp, err = http.get({ url = sha256_url })
    if err == nil and resp.status_code == 200 then
        sha256 = resp.body:match("^(%x+)")
    end

    return {
        version = version,
        url = url,
        sha256 = sha256,
        note = "正在下载 MoonBit " .. version .. " (" .. platform .. ")",
    }
end