[![macOS](https://img.shields.io/badge/macOS-13%2B-111111?logo=apple)](MACOS.md)
[![Apple Silicon](https://img.shields.io/badge/Apple%20Silicon-native-0a84ff)](MACOS.md)
[![Intel](https://img.shields.io/badge/Intel-supported-0a84ff)](MACOS.md)
[![MIT License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

<div align="center">
  <a href="https://github.com/Herdeny/myspeed-macos">
    <img src="https://i.imgur.com/aCmA6rH.png" alt="MySpeed logo" width="80" height="80">
  </a>
  <h2>MySpeed macOS</h2>
  <p>Native menu bar network quality monitoring · No Docker required</p>
  <p><strong>English</strong> · <a href="README.zh-CN.md">简体中文</a></p>
</div>

MySpeed macOS is an unofficial native macOS edition of [MySpeed](https://github.com/gnmyt/myspeed). It packages the dashboard, scheduler, database, and speed-test providers into an installable menu bar application for Apple Silicon and Intel Macs.

## Features

- Native macOS menu bar application with no Dock icon and no Docker dependency.
- English and Simplified Chinese menu bar interface, selected from the macOS language setting.
- Scheduled tests and long-term history for download, upload, latency, and jitter.
- LibreSpeed, Cloudflare, and Ookla provider support.
- Curated China education and carrier nodes from [MySpeed-CN](https://github.com/macrwfuse/myspeed-cn), localized in English and Chinese.
- Locale-aware first-run defaults: Cloudflare for English and other languages; Nanjing University LibreSpeed for Simplified Chinese.
- Launch at login, service restart, data directory, runtime log, and browser dashboard controls.
- Persistent data in `~/Library/Application Support/MySpeed`, retained across application upgrades.

## Download

Download the package for your Mac from [Releases](https://github.com/Herdeny/myspeed-macos/releases):

- Apple M1, M2, M3, M4, M5, and later: `MySpeed-macOS-arm64.dmg`
- Intel Mac: `MySpeed-macOS-x64.dmg`

Open the DMG and drag `MySpeed.app` to Applications. See the [macOS installation and build guide](MACOS.md) for Gatekeeper instructions, storage locations, and uninstall details.

> Public packages use ad-hoc signing and are not Apple-notarized yet. If macOS blocks the first launch, open System Settings → Privacy & Security and select **Open Anyway**.

## Build from source

Building requires macOS 13 or later, Xcode Command Line Tools, and [Bun](https://bun.sh/):

```sh
git clone https://github.com/Herdeny/myspeed-macos.git
cd myspeed-macos
bun run build:macos
```

You can also target one architecture explicitly:

```sh
bash scripts/build-macos-app.sh arm64
bash scripts/build-macos-app.sh x64
```

The application, DMG, and ZIP are written to `dist/`. GitHub Actions can build both architectures as well.

## Pictures
<img width="2924" height="2447" alt="becc0745aff37448ea9d4640dacc6f8d" src="https://github.com/user-attachments/assets/60493b31-4000-4790-bb1b-6a052b01152e" />



## Known limitations

- Ookla currently distributes only an Intel macOS CLI. Apple Silicon requires Rosetta 2 when using Ookla.
- The Ookla download host is unavailable on some networks. A build still succeeds with native LibreSpeed and Cloudflare support.
- Public test nodes may be temporarily unavailable because of maintenance, rate limits, or network policy.

## Attribution

This repository preserves MySpeed's history and MIT license. China node configuration and related compatibility work were adapted from MySpeed-CN. See [ACKNOWLEDGEMENTS.md](ACKNOWLEDGEMENTS.md) for source and third-party component details. This project is not affiliated with MySpeed, LibreSpeed, Cloudflare, or Ookla.

## License

Released under the [MIT License](LICENSE). Original MySpeed copyright belongs to Mathias Wagner and contributors. Bundled speed-test components remain subject to their own licenses and terms.
