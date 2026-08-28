#!/usr/bin/env bash
set -e

echo "==> Building CursorCompanion in release mode..."
swift build -c release
swift build -c release --product CursorCompanionWidget

APP_DIR=".build/CursorCompanion.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

echo "==> Creating macOS App Bundle ($APP_DIR)..."
rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR" "$CONTENTS_DIR/PlugIns" "$CONTENTS_DIR/Frameworks"

cp .build/release/CursorCompanion "$MACOS_DIR/CursorCompanion"

# Sparkle Framework kopieren (dynamisch verlinkt)
echo "==> Copying Sparkle.framework..."
cp -R .build/artifacts/sparkle/Sparkle/Sparkle.xcframework/macos-arm64_x86_64/Sparkle.framework "$CONTENTS_DIR/Frameworks/"

# App Icon kopieren falls vorhanden
if [ -f "Resources/AppIcon.icns" ]; then
    cp "Resources/AppIcon.icns" "$RESOURCES_DIR/AppIcon.icns"
fi
if [ -f "Resources/AppIcon.png" ]; then
    cp "Resources/AppIcon.png" "$RESOURCES_DIR/AppIcon.png"
fi

cat << 'EOF' > "$CONTENTS_DIR/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>CursorCompanion</string>
    <key>CFBundleIdentifier</key>
    <string>dev.cursorcompanion.app</string>
    <key>CFBundleName</key>
    <string>CursorCompanion</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>SUFeedURL</key>
    <string>https://github.com/clezcoding/cursor-companion/releases/latest/download/appcast.xml</string>
    <key>SUPublicEDKey</key>
    <string>dgdFoXX2bcwC4XRKedJP6xJZAXggbB1xL2AXCGjv574=</string>
</dict>
</plist>
EOF

echo "==> Packaging Widget Extension..."
APPEX_DIR="$CONTENTS_DIR/PlugIns/CursorCompanionWidget.appex"
mkdir -p "$APPEX_DIR/Contents/MacOS"

cp .build/release/CursorCompanionWidget "$APPEX_DIR/Contents/MacOS/CursorCompanionWidget"

cat << 'EOF' > "$APPEX_DIR/Contents/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>CursorCompanionWidget</string>
    <key>CFBundleIdentifier</key>
    <string>dev.cursorcompanion.app.widget</string>
    <key>CFBundleName</key>
    <string>CursorCompanionWidget</string>
    <key>CFBundlePackageType</key>
    <string>XPC!</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>NSExtension</key>
    <dict>
        <key>NSExtensionPointIdentifier</key>
        <string>com.apple.widgetkit-extension</string>
    </dict>
</dict>
</plist>
EOF

echo "==> Signing Widget and App locally..."
codesign -f -s - "$APPEX_DIR"
codesign -f -s - "$APP_DIR"

echo "==> App bundle built successfully at $APP_DIR"
echo "==> Run with: open $APP_DIR"
