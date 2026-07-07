-- metadata.lua
-- MoonBit 插件元数据和配置
-- 参考: https://vfox.dev/plugins/create/howto.html

PLUGIN = { -- luacheck: ignore
    -- 插件名称（小写，无空格）
    name = "moonbit",

    -- 插件版本
    version = "1.0.0",

    -- 插件描述
    description = "MoonBit 编程语言工具链。MoonBit 是一个用于云和边缘计算的端到端编程语言工具链，使用 WebAssembly。",

    -- 插件作者/维护者
    author = "mise-plugins",

    -- 插件仓库地址
    homepage = "https://github.com/mise-plugins/mise-moonbit",

    -- 最低 mise 运行时版本
    minRuntimeVersion = "0.2.0",

    -- 可选：许可证
    license = "MIT",

    -- 可选：注意事项
    notes = {
        "安装完成后会自动下载并编译 MoonBit 核心库。",
        "可通过环境变量 MOONBIT_INSTALL_DEV=1 安装开发版本。",
    },

    -- 旧版版本文件支持（如 .moon-version、.moonbitrc）
    -- legacyFilenames = {
    --     ".moon-version",
    --     ".moonbitrc",
    -- }
}