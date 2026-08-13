# Sources and acknowledgements

[English](ACKNOWLEDGEMENTS.md) · [简体中文](ACKNOWLEDGEMENTS.zh-CN.md)

MySpeed macOS is a derivative work built with the following open-source projects and services.

## MySpeed

- Project: https://github.com/gnmyt/myspeed
- Used for: backend, web dashboard, scheduling, history, integrations, and other core functionality.
- License: MIT License. The original copyright notice remains in this repository's `LICENSE` file.

## MySpeed-CN

- Project: https://github.com/macrwfuse/myspeed-cn
- Reference revision: `fdb24d2de7dc95771248dc18c695056e21d05997`
- Used for: China Ookla and LibreSpeed node configuration, plus LibreSpeed string node ID compatibility.

## Speed-test components

The build script obtains pinned versions from official release channels and places available components in the macOS bundle:

- LibreSpeed CLI: https://github.com/librespeed/speedtest-cli
- Cloudflare Speed Test CLI: https://github.com/code-inflation/cfspeedtest
- Ookla Speedtest CLI: https://www.speedtest.net/apps/cli

These components are not part of this project and remain subject to their own licenses, copyright notices, and terms. An Ookla download failure does not block the application build; LibreSpeed and Cloudflare remain available.
