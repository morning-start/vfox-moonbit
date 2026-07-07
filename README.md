# mise-moonbit

[vfox](https://vfox.dev/) / [mise](https://mise.jdx.dev/) 的 MoonBit 插件。

## 安装

安装 [mise](https://mise.jdx.dev/) 后，运行以下命令添加插件：

```bash
mise plugin add moonbit
```

或通过 GitHub 仓库安装：

```bash
mise plugin add moonbit https://github.com/mise-plugins/mise-moonbit.git
```

## 使用

```bash
# 安装最新版本
mise install moonbit@latest

# 安装指定版本
mise install moonbit@0.10.3+16975d007

# 安装最新的 0.10.x 版本
mise install moonbit@0.10

# 设置全局版本
mise use -g moonbit@latest

# 查看可用版本
mise ls-remote moonbit
```

## 环境变量

| 变量 | 说明 |
|------|------|
| `MOONBIT_INSTALL_DEV` | 设置为 `1` 安装开发版本 |

## 镜像

可通过设置 `VFOX_MOONBIT_MIRROR` 环境变量来配置下载镜像。默认值为 `https://cli.moonbitlang.cn`。

## 支持的平台

| 操作系统 | 架构 |
|----------|------|
| macOS | arm64 (Apple Silicon)、x86_64 (Intel) |
| Linux | x86_64、aarch64 |
| Windows | x86_64 |

## 开发

```bash
# 链接本地插件
mise plugin link --force moonbit .

# 运行测试
mise run test

# 运行 lint
mise run lint

# 调试模式
MISE_DEBUG=1 mise install moonbit@latest
```

## 许可证

MIT