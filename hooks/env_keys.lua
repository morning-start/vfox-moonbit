--- 配置 MoonBit 所需的环境变量
--- 参考: https://vfox.dev/plugins/create/howto.html#envkeys
--- @param ctx table 上下文
--- @field ctx.path string SDK 安装目录
--- @return table[] 环境变量配置列表
function PLUGIN:EnvKeys(ctx)
    local mainPath = ctx.path

    return {
        {
            key = "MOON_HOME",
            value = mainPath,
        },
        {
            key = "PATH",
            value = mainPath .. "/bin",
        },
    }
end