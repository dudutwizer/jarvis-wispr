#!/bin/bash
# Quick syntax check

cd ~/Developer/jarvis

echo "Checking Swift files for syntax errors..."
for file in Jarvis/*.swift; do
    echo "Checking $file..."
    swiftc -typecheck "$file" \
        -sdk $(xcrun --show-sdk-path --sdk macosx) \
        -target arm64-apple-macos14.0 \
        -import-objc-header /dev/null \
        2>&1 | grep -i error || echo "  ✓ OK"
done

echo ""
echo "To build in Xcode: open Jarvis.xcodeproj and press ⌘B"
