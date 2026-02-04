#!/bin/bash
# Quick build script for Jarvis

set -e

echo "🔨 Building Jarvis..."

# Check if Xcode is installed
if ! command -v xcodebuild &> /dev/null; then
    echo "❌ Xcode not found. Please open Jarvis.xcodeproj in Xcode and build manually."
    echo "Or install full Xcode from the App Store."
    exit 1
fi

# Build
xcodebuild -project Jarvis.xcodeproj \
    -scheme Jarvis \
    -configuration Release \
    -derivedDataPath ./build \
    CODE_SIGN_IDENTITY="" \
    CODE_SIGNING_REQUIRED=NO \
    CODE_SIGNING_ALLOWED=NO

# Copy to Applications if build succeeded
if [ -d "./build/Build/Products/Release/Jarvis.app" ]; then
    echo "✅ Build successful!"
    echo "📦 App location: ./build/Build/Products/Release/Jarvis.app"
    
    read -p "Install to /Applications? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        cp -R ./build/Build/Products/Release/Jarvis.app /Applications/
        echo "✅ Installed to /Applications/Jarvis.app"
        echo "🚀 Launch it from Applications or run: open /Applications/Jarvis.app"
    fi
else
    echo "❌ Build failed"
    exit 1
fi
