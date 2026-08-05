#!/usr/bin/env bash
#
# 构建 & 打包 diu-diu-diu（断舍离计划助手）为 .app
# 说明：本机当前只有 Command Line Tools，没有完整 Xcode，
# 因此用 swiftc 直接编译 SwiftUI 源码，再手工组装 .app bundle。
# 装了完整 Xcode 后，也可改用 xcodebuild + .xcodeproj。
#
set -euo pipefail

cd "$(dirname "$0")/DiuDiuDiu"

OUT_DIR="${BUILD_DIR:-$(pwd)/../build}"
APP="$OUT_DIR/DiuDiuDiu.app"
BIN_NAME="DiuDiuDiu"

echo "==> 用 swiftc 编译 Swift 源码"
SOURCES=$(ls Models/*.swift Data/*.swift Views/*.swift *.swift)
mkdir -p "$OUT_DIR"
swiftc $SOURCES \
    -target arm64-apple-macos26.0 \
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
    <key>CFBundleName</key><string>DiuDiuDiu</string>
    <key>CFBundleDisplayName</key><string>断舍离计划助手</string>
    <key>CFBundleIdentifier</key><string>com.zenx.diudiudiu</string>
    <key>CFBundleVersion</key><string>1</string>
    <key>CFBundleShortVersionString</key><string>1.0.0</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>CFBundleExecutable</key><string>DiuDiuDiu</string>
    <key>LSMinimumSystemVersion</key><string>14.0</string>
    <key>LSApplicationCategoryType</key><string>public.app-category.lifestyle</string>
    <key>NSHighResolutionCapable</key><true/>
    <key>NSSupportsAutomaticGraphicsSwitching</key><true/>
</dict>
</plist>
PLIST

echo "==> 完成"
echo "    产物: $APP"
echo "    运行: open \"$APP\""
