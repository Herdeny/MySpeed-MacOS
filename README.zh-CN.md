[![macOS](https://img.shields.io/badge/macOS-13%2B-111111?logo=apple)](MACOS.zh-CN.md)
[![Apple Silicon](https://img.shields.io/badge/Apple%20Silicon-native-0a84ff)](MACOS.zh-CN.md)
[![Intel](https://img.shields.io/badge/Intel-supported-0a84ff)](MACOS.zh-CN.md)
[![MIT License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

<div align="center">
  <a href="https://github.com/Herdeny/myspeed-macos">
    <img src="https://i.imgur.com/aCmA6rH.png" alt="MySpeed 标志" width="80" height="80">
  </a>
  <h2>MySpeed macOS</h2>
  <p>原生菜单栏网络质量监测工具 · 无需 Docker</p>
  <p><a href="README.md">English</a> · <strong>简体中文</strong></p>
</div>

MySpeed macOS 是基于 [MySpeed](https://github.com/gnmyt/myspeed) 开发的非官方原生 macOS 版本，把控制面板、定时任务、历史数据库和测速提供商打包为可直接安装的 Apple Silicon 与 Intel 菜单栏应用。

## 主要功能

- 原生 macOS 菜单栏应用，不占用 Dock，无需 Docker。
- 菜单栏界面支持英文和简体中文，自动跟随 macOS 系统语言。
- 自动定时测速并记录下载、上传、延迟和抖动。
- 支持 LibreSpeed、Cloudflare 和 Ookla 三类测速提供商。
- 内置来自 [MySpeed-CN](https://github.com/macrwfuse/myspeed-cn) 的中国教育网及运营商节点，节点名称支持中英文。
- 首次运行自动选择适合语言区域的默认值：简体中文使用南京大学 LibreSpeed，英文及其他语言使用 Cloudflare。
- 支持登录时自动启动、服务重启、数据目录、运行日志和浏览器控制面板。
- 数据保存在 `~/Library/Application Support/MySpeed`，更新应用不会覆盖历史记录。

## 下载安装

前往 [Releases](https://github.com/Herdeny/myspeed-macos/releases) 下载与你的 Mac 匹配的安装包：

- Apple M1、M2、M3、M4、M5 及后续机型：`MySpeed-macOS-arm64.dmg`
- Intel Mac：`MySpeed-macOS-x64.dmg`

打开 DMG，把 `MySpeed.app` 拖入“应用程序”即可。首次运行的安全提示、数据目录和卸载方法请查看 [macOS 安装与构建说明](MACOS.zh-CN.md)。

> 当前公开包使用临时签名，尚未经过 Apple 公证。若 macOS 阻止首次启动，请在“系统设置 → 隐私与安全性”中选择“仍要打开”。

## 从源码构建

需要 macOS 13 或更高版本、Xcode Command Line Tools 和 [Bun](https://bun.sh/)：

```sh
git clone https://github.com/Herdeny/myspeed-macos.git
cd myspeed-macos
bun run build:macos
```

也可以指定目标架构：

```sh
bash scripts/build-macos-app.sh arm64
bash scripts/build-macos-app.sh x64
```

生成的应用、DMG 和 ZIP 位于 `dist/`。GitHub Actions 也可以构建两个架构。

## 从 MySpeed CN for macOS 升级

先退出并删除旧的 `MySpeed CN.app`，然后安装新的 `MySpeed.app`。两者使用相同的数据目录，因此历史测速记录会保留。如果旧版启用了登录时自动启动，请在新应用菜单中重新启用一次。

## 已知限制

- Ookla 官方 macOS CLI 目前仅提供 Intel 版本；Apple Silicon 使用 Ookla 时需要 Rosetta 2。
- 部分网络无法访问 Ookla 官方下载域名。此时构建仍会完成，LibreSpeed 与 Cloudflare 不受影响。
- 公共测速节点可能因维护、限流或网络策略暂时不可用，可以在控制面板中切换节点。

## 上游与致谢

本项目保留 MySpeed 的提交历史和 MIT 许可证。中国测速节点及相关兼容逻辑参考自 MySpeed-CN。完整来源和第三方组件信息见 [ACKNOWLEDGEMENTS.zh-CN.md](ACKNOWLEDGEMENTS.zh-CN.md)。本项目与 MySpeed、LibreSpeed、Cloudflare 或 Ookla 官方均无隶属关系。

## 许可证

本项目依据 [MIT License](LICENSE) 开源。MySpeed 原始版权归 Mathias Wagner 及其贡献者所有；各测速组件遵循其各自许可证和服务条款。
