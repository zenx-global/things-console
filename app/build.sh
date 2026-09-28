#!/usr/bin/env bash
#
# 构建 & 打包 Things Console（个人物品管理工作台）为 .app
# 说明：本机当前只有 Command Line Tools，没有完整 Xcode，
# 因此用 swiftc 直接编译 SwiftUI 源码，再手工组装 .app bundle。
# 装了完整 Xcode 后，也可改用 xcodebuild + .xcodeproj。
#
set -euo pipefail

cd "$(dirname "$0")/ThingsConsole"

OUT_DIR="${BUILD_DIR:-$(pwd)/../build}"
APP="$OUT_DIR/ThingsConsole.app"
BIN_NAME="ThingsConsole"

echo "==> 用 swiftc 编译 Swift 源码"
SOURCES=$(ls Models/*.swift Data/*.swift Services/*.swift Views/*.swift *.swift)
mkdir -p "$OUT_DIR"
# 说明：CLT 默认 SDK（26.x+）的 SwiftUI 宏插件（SwiftUIMacros）缺失，
# 编译 @State 等会报 "plugin for module 'SwiftUIMacros' not found"。
# 因此固定使用本机较旧的 MacOSX15.2.sdk；装了完整 Xcode 后可去掉 -sdk 改回默认。
SDK_PATH="/Library/Developer/CommandLineTools/SDKs/MacOSX15.2.sdk"
swiftc $SOURCES \
    -sdk "$SDK_PATH" \
    -target arm64-apple-macos14.0 \
    -parse-as-library \
    -O \
    -o "$OUT_DIR/$BIN_NAME"

echo "==> 组装 .app bundle"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
mkdir -p "$APP/Contents/Resources"
cp "$OUT_DIR/$BIN_NAME" "$APP/Contents/MacOS/$BIN_NAME"

cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key><string>ThingsConsole</string>
    <key>CFBundleDisplayName</key><string>物品管理台</string>
    <key>CFBundleIdentifier</key><string>com.zenx.thingsconsole</string>
    <key>CFBundleVersion</key><string>4</string>
    <key>CFBundleShortVersionString</key><string>2.2.0</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>CFBundleExecutable</key><string>ThingsConsole</string>
    <key>LSMinimumSystemVersion</key><string>14.0</string>
    <key>LSApplicationCategoryType</key><string>public.app-category.lifestyle</string>
    <key>NSHighResolutionCapable</key><true/>
    <key>NSSupportsAutomaticGraphicsSwitching</key><true/>
    <key>NSLocalNetworkUsageDescription</key>
    <string>用于在局域网内为你的手机提供速录页面。数据只在你的设备之间传输，不经过任何云端。</string>
</dict>
</plist>
PLIST

echo "==> 完成"
echo "    产物: $APP"
echo "    运行: open \"$APP\""
