--- !!! DO NOT EDIT OR RENAME !!!
PLUGIN = {}

--- !!! MUST BE SET !!!
PLUGIN.name = "moonbit"
PLUGIN.version = "1.4.0"
PLUGIN.homepage = "https://github.com/morning-start/moonbit"
PLUGIN.license = "MIT"
PLUGIN.description = "MoonBit 编程语言工具链。MoonBit 是一个用于云和边缘计算的端到端编程语言工具链，使用 WebAssembly。"

--- !!! OPTIONAL !!!
PLUGIN.minRuntimeVersion = "0.3.0"
PLUGIN.manifestUrl = "https://github.com/morning-start/moonbit/releases/download/manifest/manifest.json"
PLUGIN.notes = {
    "首次正式发布",
    "平台支持与官方安装脚本一致：macOS ARM64、Linux x86_64/aarch64、Windows x86_64/ARM64",
    "支持 ~/.moon 软链接，版本切换时自动更新",
    "支持 GitHub Token 认证，提高 API 速率限制",
    "支持 gh CLI 自动获取 Token",
    "Windows 使用目录交接点 (junction) 避免管理员权限问题",
}
