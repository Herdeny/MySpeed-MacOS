# MySpeed macOS

[English](MACOS.md) · [简体中文](MACOS.zh-CN.md)

MySpeed macOS 是 MySpeed 的原生菜单栏版本，基于 `gnmyt/myspeed`，并包含从 `macrwfuse/myspeed-cn` 适配的中国测速节点及中英文名称。

## 运行方式

- 不依赖 Docker，也不要求用户单独安装 Bun。
- 数据保存在 `~/Library/Application Support/MySpeed`，升级应用不会覆盖历史记录。
- 菜单栏界面自动跟随 macOS 系统语言，内置英文和简体中文。
- 新安装在简体中文系统上默认使用南京大学 LibreSpeed；英文及其他语言系统默认使用 Cloudflare。
- 内置 LibreSpeed 与 Cloudflare 测速组件；Ookla 仅在构建时能够访问其官方下载源时一并打包。
- 菜单栏可以打开控制面板、重启服务、打开数据目录、查看日志、设置登录时启动和退出应用。

## 安装

打开对应架构的 DMG，把 `MySpeed.app` 拖入“应用程序”，然后启动。应用只显示在菜单栏，后端准备完成后会打开 `http://127.0.0.1:5216`。

公开构建采用临时签名，尚未经过 Apple 公证。若 macOS 阻止首次启动，请在“系统设置 → 隐私与安全性”中选择“仍要打开”。

从 `MySpeed CN.app` 升级时，请先退出并删除旧应用。测速历史会保留在共用的数据目录中。如果旧版启用了登录时自动启动，请在新应用中重新启用一次。

## 构建

需要 macOS 13 或更高版本、Xcode Command Line Tools 和 Bun：

```sh
bun run build:macos
```

也可以显式指定架构：

```sh
bash scripts/build-macos-app.sh arm64
bash scripts/build-macos-app.sh x64
```

产物位于 `dist/`。构建脚本会下载固定版本的上游测速组件，并对应用执行临时签名。若当前网络无法访问 Ookla 官方下载域名，构建仍会成功，LibreSpeed 与 Cloudflare 不受影响。

## 数据与卸载

从菜单栏退出 MySpeed 后删除应用即可。若需要同时删除历史数据和设置，再删除：

```text
~/Library/Application Support/MySpeed
```

Ookla 官方目前只提供 Intel macOS CLI；Apple Silicon 使用该提供商时需要 Rosetta 2。
