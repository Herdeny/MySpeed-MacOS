# MySpeed CN for macOS

这是 MySpeed 的 macOS 菜单栏版本，基于官方 `gnmyt/myspeed`，并合并了
`macrwfuse/myspeed-cn` 的国内 Ookla 与 LibreSpeed 节点。

## 功能

- 原生 macOS 菜单栏应用，不依赖 Docker，也不要求用户安装 Bun。
- 数据保存在 `~/Library/Application Support/MySpeed`，更新应用不会覆盖历史记录。
- 内置原生 LibreSpeed 与通用 Cloudflare 测速组件；Ookla CLI 仅在构建时能访问其官方下载源时一并打包。
- Apple Silicon 首次运行默认使用南京大学 LibreSpeed 节点，不依赖 Rosetta。
- 可从菜单栏打开控制面板、重启服务、查看日志和设置登录时自动启动。

## 安装

打开对应架构的 DMG，把 `MySpeed CN.app` 拖入“应用程序”，然后启动。浏览器会自动打开
`http://127.0.0.1:5216`。应用启动后会出现在菜单栏，不会占用 Dock。

若 macOS 提示应用来自身份不明的开发者，请在“系统设置 → 隐私与安全性”中选择“仍要打开”。
正式发布时可通过设置开发者签名与公证步骤消除此提示。

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

产物位于 `dist/`。构建脚本会下载经过上游项目固定版本的测速组件，并对应用执行临时签名。若当前网络无法访问 Ookla 官方下载域名，构建仍会成功，原生 LibreSpeed 与 Cloudflare 不受影响；此时界面中的 Ookla 模式需要手动把官方 `speedtest` 程序放入数据目录的 `bin` 文件夹后使用。

## 数据与卸载

退出菜单栏中的 MySpeed 后删除应用即可卸载程序。若需要同时删除历史数据，再删除：

```text
~/Library/Application Support/MySpeed
```

Ookla 官方只提供 Intel macOS CLI；Apple Silicon 用户选择 Ookla 时需要安装 Rosetta 2。
