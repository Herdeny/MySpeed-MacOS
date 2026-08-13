# 来源与致谢

[English](ACKNOWLEDGEMENTS.md) · [简体中文](ACKNOWLEDGEMENTS.zh-CN.md)

MySpeed macOS 是在以下开源项目和服务基础上完成的衍生作品。

## MySpeed

- 项目：https://github.com/gnmyt/myspeed
- 用途：应用的服务端、Web 控制面板、任务调度、历史记录、集成及其他核心功能。
- 许可证：MIT License，原始版权声明保留在本仓库的 `LICENSE` 文件中。

## MySpeed-CN

- 项目：https://github.com/macrwfuse/myspeed-cn
- 参考版本：`fdb24d2de7dc95771248dc18c695056e21d05997`
- 用途：中国 Ookla、LibreSpeed 节点配置以及 LibreSpeed 字符串节点 ID 兼容逻辑。

## 测速组件

构建脚本会从各组件的官方发布渠道获取固定版本，并将可用组件放入 macOS 应用包：

- LibreSpeed CLI：https://github.com/librespeed/speedtest-cli
- Cloudflare Speed Test CLI：https://github.com/code-inflation/cfspeedtest
- Ookla Speedtest CLI：https://www.speedtest.net/apps/cli

这些组件不是本项目的一部分，分别受其自身许可证、版权声明和服务条款约束。Ookla CLI 下载失败不会阻止应用构建，LibreSpeed 和 Cloudflare 仍可正常使用。
