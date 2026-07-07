-- lib/util.lua
-- MoonBit 插件辅助函数

local UTIL = {}

-- MoonBit 下载基地址（支持 VFOX_MOONBIT_MIRROR 环境变量覆盖）
UTIL.CLI_MOONBIT = os.getenv("VFOX_MOONBIT_MIRROR") or "https://cli.moonbitlang.cn"

--- 获取 MoonBit 平台标识字符串
--- 例如: darwin-aarch64, linux-x86_64, windows-x86_64
--- @return string|nil 平台标识字符串，不支持的平台返回 nil
function UTIL.get_platform()
    local os_type = RUNTIME.osType
    local arch = RUNTIME.archType

    local platform_map = {
        ["darwin"] = {
            -- 注意: 官方 unix.sh 仅支持 ARM64 (Apple Silicon)
            ["arm64"] = "darwin-aarch64",
        },
        ["linux"] = {
            ["amd64"] = "linux-x86_64",
            ["arm64"] = "linux-aarch64",
        },
        ["windows"] = {
            ["amd64"] = "windows-x86_64",
            -- ARM64 Windows 通过 x86_64 模拟运行
            ["arm64"] = "windows-x86_64",
        },
    }

    local os_map = platform_map[os_type]
    if os_map then
        return os_map[arch]
    end

    return nil
end

--- 获取支持的平台列表（用于错误提示）
--- @return string 可读的平台列表
function UTIL.get_supported_platforms()
    local platforms = {}
    for os, archs in pairs({
        darwin = { "amd64", "arm64" },
        linux = { "amd64", "arm64" },
        windows = { "amd64", "arm64" },
    }) do
        for _, arch in ipairs(archs) do
            table.insert(platforms, os .. "/" .. arch)
        end
    end
    return table.concat(platforms, ", ")
end

--- 获取归档文件扩展名
--- @return string ".tar.gz" (Linux/macOS) 或 ".zip" (Windows)
function UTIL.get_archive_ext()
    if RUNTIME.osType == "windows" then
        return ".zip"
    else
        return ".tar.gz"
    end
end

--- 对版本号中的 + 进行 URL 编码
--- 例如 "0.10.3+16975d007" -> "0.10.3%2B16975d007"
--- @param version string 版本号
--- @return string URL 编码后的版本号
function UTIL.encode_version(version)
    return version:gsub("%+", "%%2B")
end

--- 比较两个版本号（降序排列，新版本在前）
--- @param v1 table 包含 version 字段的版本对象
--- @param v2 table 包含 version 字段的版本对象
--- @return boolean v1 是否比 v2 新
function UTIL.compare_versions(v1, v2)
    local semver = require("semver")
    -- 提取纯语义版本部分（去掉 +hash 后缀）
    local v1_clean = v1.version:match("^(%d+%.%d+%.%d+)")
    local v2_clean = v2.version:match("^(%d+%.%d+%.%d+)")

    if v1_clean and v2_clean then
        local cmp = semver.compare(v1_clean, v2_clean)
        if cmp ~= 0 then
            return cmp > 0
        end
    end

    -- 如果语义版本相同，按原始字符串排序
    return v1.version > v2.version
end

--- 根据用户输入的版本号，从可用版本列表中匹配完整版本
--- 支持完整版本号（如 "0.10.3+16975d007"）和语义版本号（如 "0.10.3"、"0.10"）
--- @param version string 用户输入的版本号
--- @param available table[] 可用版本列表
--- @return string|nil 匹配到的完整版本号
function UTIL.resolve_version(version, available)
    -- 先尝试精确匹配
    for _, v in ipairs(available) do
        if v.version == version then
            return v.version
        end
    end

    -- 如果版本号包含 +，说明已是完整版本号但精确匹配失败
    if version:find("%+") then
        return nil
    end

    -- 尝试前缀匹配：
    -- 用户输入 "0.10.3" → 匹配 "0.10.3+..."
    -- 用户输入 "0.10"   → 匹配 "0.10.x+..."（最新的）
    local prefix_dot = version .. "."
    local prefix_plus = version .. "+"
    local best_match = nil

    for _, v in ipairs(available) do
        if v.version:sub(1, #prefix_plus) == prefix_plus then
            -- 精确前缀匹配（如 "0.10.3+" 匹配 "0.10.3+xxx"）
            return v.version
        elseif v.version:sub(1, #prefix_dot) == prefix_dot then
            -- 部分前缀匹配（如 "0.10." 匹配 "0.10.3+xxx"）
            if best_match == nil then
                best_match = v.version
            end
        end
    end

    return best_match
end

return UTIL