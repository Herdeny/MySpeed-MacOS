# MySpeed macOS

[English](MACOS.md) · [简体中文](MACOS.zh-CN.md)

MySpeed macOS is a native menu bar edition of MySpeed. It is based on `gnmyt/myspeed` and includes localized China provider nodes adapted from `macrwfuse/myspeed-cn`.

## Runtime behavior

- The application does not require Docker or a separately installed Bun runtime.
- Data is stored in `~/Library/Application Support/MySpeed` and survives application upgrades.
- The menu bar interface follows the macOS language setting, with English and Simplified Chinese included.
- New English and other non-Chinese installations default to Cloudflare. New Simplified Chinese installations default to the Nanjing University LibreSpeed node.
- LibreSpeed and Cloudflare binaries are bundled. Ookla is bundled only when its official download is reachable during the build.
- The menu provides dashboard, restart, data directory, log, Launch at Login, and quit actions.

## Install

Open the DMG for your architecture, drag `MySpeed.app` to Applications, and launch it. The application appears only in the menu bar and opens `http://127.0.0.1:5216` when the backend is ready.

Public builds are ad-hoc signed rather than Apple-notarized. If Gatekeeper blocks the first launch, open System Settings → Privacy & Security and select **Open Anyway**.

When upgrading from `MySpeed CN.app`, quit and remove the old application first. Your history remains in the shared Application Support directory. Re-enable Launch at Login from the new application if needed.

## Build

Building requires macOS 13 or later, Xcode Command Line Tools, and Bun:

```sh
bun run build:macos
```

To select an architecture explicitly:

```sh
bash scripts/build-macos-app.sh arm64
bash scripts/build-macos-app.sh x64
```

Outputs are written to `dist/`. The build script downloads pinned upstream provider components and ad-hoc signs the finished application. If Ookla's official host is unreachable, the build still completes with LibreSpeed and Cloudflare.

## Data and uninstall

Quit MySpeed from the menu bar and delete the application. To remove test history and settings as well, delete:

```text
~/Library/Application Support/MySpeed
```

Ookla currently publishes only an Intel macOS CLI. Apple Silicon requires Rosetta 2 when using that provider.
