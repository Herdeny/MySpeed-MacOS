[![macOS](https://img.shields.io/badge/macOS-13%2B-111111?logo=apple)](MACOS.md)
[![Apple Silicon](https://img.shields.io/badge/Apple%20Silicon-native-0a84ff)](MACOS.md)
[![Intel](https://img.shields.io/badge/Intel-supported-0a84ff)](MACOS.md)
[![MIT License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

<div align="center">
  <a href="https://github.com/Herdeny/myspeed-macos-cn">
    <img src="https://i.imgur.com/aCmA6rH.png" alt="MySpeed Logo" width="80" height="80">
  </a>
  <h2>MySpeed CN for macOS</h2>
  <p>原生菜单栏网络质量监测工具 · 无需 Docker · 内置中国测速节点</p>
</div>

这是基于 [MySpeed](https://github.com/gnmyt/myspeed) 开发的非官方 macOS 版本，针对 Apple Silicon 和 Intel Mac 提供可直接安装的应用，并采用 [MySpeed-CN](https://github.com/macrwfuse/myspeed-cn) 的中国测速提供商配置。

## 主要功能

- 原生 macOS 菜单栏应用，不占用 Dock，无需 Docker。
- 自动定时测速并记录下载、上传、延迟和抖动。
- 支持 LibreSpeed、Cloudflare 和 Ookla 三类测速提供商。
- 内置中国大陆教育网及运营商节点；首次启动默认使用南京大学 LibreSpeed 节点。
- 测速历史保存在 `~/Library/Application Support/MySpeed`，升级应用不会覆盖数据。
- 支持开机自动启动、服务重启、日志查看和浏览器控制面板。

## 下载安装

前往 [Releases](https://github.com/Herdeny/myspeed-macos-cn/releases) 下载与你的 Mac 匹配的安装包：

- Apple M1、M2、M3、M4、M5：`MySpeed-CN-macOS-arm64.dmg`
- Intel Mac：`MySpeed-CN-macOS-x64.dmg`

打开 DMG 后，把 `MySpeed CN.app` 拖入“应用程序”即可。首次运行的安全提示、数据目录和卸载方法请查看 [macOS 使用与构建说明](MACOS.md)。

> 当前公开包使用临时签名，尚未经过 Apple 公证。若 macOS 阻止首次启动，请在“系统设置 → 隐私与安全性”中选择“仍要打开”。

## 从源码构建

需要 macOS 13 或更高版本、Xcode Command Line Tools 和 [Bun](https://bun.sh/)：

```sh
git clone https://github.com/Herdeny/myspeed-macos-cn.git
cd myspeed-macos-cn
bun run build:macos
```

也可以指定目标架构：

```sh
bash scripts/build-macos-app.sh arm64
bash scripts/build-macos-app.sh x64
```

生成的 DMG、ZIP 和 `.app` 位于 `dist/`。GitHub Actions 也会分别构建 Apple Silicon 与 Intel 安装包。

## 已知限制

- Ookla 官方 macOS CLI 目前仅提供 Intel 版本；Apple Silicon 上使用 Ookla 需要 Rosetta 2。
- 部分中国大陆网络无法访问 Ookla 官方下载域名。此时构建仍会完成，LibreSpeed 与 Cloudflare 不受影响。
- 内置公共测速节点可能因维护、限流或网络策略暂时不可用，可以在控制面板中切换节点。

## 上游与致谢

本项目保留 MySpeed 的提交历史和 MIT 许可证。国内测速节点及相关兼容逻辑参考自 MySpeed-CN。完整来源和第三方组件信息见 [ACKNOWLEDGEMENTS.md](ACKNOWLEDGEMENTS.md)。本项目与 MySpeed、LibreSpeed、Cloudflare 或 Ookla 官方均无隶属关系。

## 许可证

本项目依据 [MIT License](LICENSE) 开源。MySpeed 原始版权归 Mathias Wagner 及其贡献者所有；各测速组件遵循其各自许可证和服务条款。
