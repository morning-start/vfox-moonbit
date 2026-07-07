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

# 安装 nightly 版本
mise install moonbit@nightly

# 设置全局版本
mise use -g moonbit@latest

# 查看可用版本
mise ls-remote moonbit
```

## 环境变量

| 变量 | 说明 |
|------|------|
| `MOONBIT_INSTALL_DEV` | 设置为 `1` 安装开发版本（下载 `-dev` 后缀的构建） |
| `MOONBIT_INSTALL_VERSION` | 指定要安装的版本，优先级高于命令行参数 |
| `VFOX_MOONBIT_MIRROR` | 下载镜像地址，默认 `https://cli.moonbitlang.cn` |

## 支持的平台

| 操作系统 | 架构 |
|----------|------|
| macOS | arm64 (Apple Silicon) |
| Linux | x86_64、aarch64 |
| Windows | x86_64、arm64（通过 x86_64 模拟运行） |

> 平台支持与官方安装脚本一致：
> - `unix.sh`：macOS ARM64、Linux x86_64/aarch64
> - `powershell.ps1`：Windows AMD64/ARM64

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