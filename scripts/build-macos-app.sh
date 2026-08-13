#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_DIR"

BUN_BIN="${BUN_BIN:-$(command -v bun || true)}"
if [[ -z "$BUN_BIN" ]]; then
    echo "Bun is required. Set BUN_BIN=/path/to/bun or install Bun from https://bun.sh"
    exit 1
fi

ARCH="${1:-$(uname -m)}"
case "$ARCH" in
    arm64|aarch64)
        ARCH="arm64"
        NATIVE_ARCH="arm64"
        BUN_TARGET="bun-darwin-arm64"
        LIBRE_SUFFIX="darwin_arm64.tar.gz"
        ;;
    x86_64|x64)
        ARCH="x64"
        NATIVE_ARCH="x86_64"
        BUN_TARGET="bun-darwin-x64"
        LIBRE_SUFFIX="darwin_amd64.tar.gz"
        ;;
    *)
        echo "Unsupported macOS architecture: $ARCH"
        exit 1
        ;;
esac

DIST_DIR="$PROJECT_DIR/dist/macos-$ARCH"
APP_DIR="$DIST_DIR/MySpeed.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"
CACHE_DIR="$PROJECT_DIR/dist/downloads"

rm -rf "$DIST_DIR" "$PROJECT_DIR/build" "$PROJECT_DIR/client/build" "$PROJECT_DIR/MySpeed"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR/bin" "$CACHE_DIR"

echo "==> Installing dependencies"
"$BUN_BIN" install --frozen-lockfile
(cd client && "$BUN_BIN" install)

echo "==> Building MySpeed web interface"
"$BUN_BIN" run generate-migrations
"$BUN_BIN" run generate-integrations
(cd client && "$BUN_BIN" run build)
mv client/build build
"$BUN_BIN" run generate-client-embed

echo "==> Compiling MySpeed backend ($ARCH)"
"$BUN_BIN" build --compile --compile-autoload-package-json \
    --external pg-hstore --external pg --target="$BUN_TARGET" \
    server/index.js --outfile "$MACOS_DIR/MySpeedBackend"

echo "==> Compiling native menu bar application"
clang -arch "$NATIVE_ARCH" -fobjc-arc -O2 -mmacosx-version-min=13.0 \
    -framework Cocoa -framework ServiceManagement \
    macos/MySpeedMac/main.m -o "$MACOS_DIR/MySpeed"
cp macos/Info.plist "$CONTENTS_DIR/Info.plist"
cp -R macos/en.lproj macos/zh-Hans.lproj "$RESOURCES_DIR/"

download() {
    local url="$1"
    local destination="$2"
    if [[ ! -s "$destination" ]]; then
        rm -f "$destination.part"
        curl -fL --retry 3 --retry-all-errors --connect-timeout 15 "$url" -o "$destination.part"
        mv "$destination.part" "$destination"
    fi
}

echo "==> Bundling speed test providers"
download "https://github.com/librespeed/speedtest-cli/releases/download/v1.0.10/librespeed-cli_1.0.10_$LIBRE_SUFFIX" "$CACHE_DIR/librespeed-$ARCH.tar.gz"
download "https://github.com/code-inflation/cfspeedtest/releases/download/v2.2.2/cfspeedtest-universal-apple-darwin.tar.gz" "$CACHE_DIR/cloudflare-universal.tar.gz"

tar -xzf "$CACHE_DIR/librespeed-$ARCH.tar.gz" -C "$RESOURCES_DIR/bin" librespeed-cli
tar -xzf "$CACHE_DIR/cloudflare-universal.tar.gz" -C "$RESOURCES_DIR/bin" cfspeedtest

# Ookla publishes only an Intel macOS CLI and its download host is unavailable
# on some mainland networks. Keep it optional so native providers still ship.
if [[ "${SKIP_OOKLA:-0}" != "1" ]] && download "https://install.speedtest.net/app/cli/ookla-speedtest-1.2.0-macosx-x86_64.tgz" "$CACHE_DIR/ookla-macos-x64.tgz"; then
    tar -xzf "$CACHE_DIR/ookla-macos-x64.tgz" -C "$RESOURCES_DIR/bin" speedtest
else
    rm -f "$CACHE_DIR/ookla-macos-x64.tgz.part"
    echo "Warning: Ookla CLI was not bundled. LibreSpeed and Cloudflare remain available."
fi
chmod 755 "$MACOS_DIR/MySpeed" "$MACOS_DIR/MySpeedBackend" "$RESOURCES_DIR/bin/"*

echo "==> Creating application icon"
SOURCE_ICON="$PROJECT_DIR/client/public/assets/img/logo.png"
sips -s format icns "$SOURCE_ICON" --out "$RESOURCES_DIR/AppIcon.icns" >/dev/null

echo "==> Signing and packaging"
codesign --force --deep --sign - "$APP_DIR"
codesign --verify --deep --strict "$APP_DIR"

DMG_PATH="$PROJECT_DIR/dist/MySpeed-macOS-$ARCH.dmg"
ZIP_PATH="$PROJECT_DIR/dist/MySpeed-macOS-$ARCH.zip"
rm -f "$DMG_PATH" "$ZIP_PATH"
ditto -c -k --sequesterRsrc --keepParent "$APP_DIR" "$ZIP_PATH"
hdiutil create -volname "MySpeed macOS" -srcfolder "$APP_DIR" -ov -format UDZO "$DMG_PATH" >/dev/null

echo "Built: $APP_DIR"
echo "Built: $DMG_PATH"
echo "Built: $ZIP_PATH"
