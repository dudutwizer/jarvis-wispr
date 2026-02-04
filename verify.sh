#!/bin/bash
# Verify Jarvis setup

echo "🔍 Verifying Jarvis Setup"
echo "=========================="
echo ""

# Check Swift files exist
echo "✓ Checking Swift files..."
for file in JarvisApp.swift KeyMonitor.swift ChatWindow.swift VoiceRecorder.swift ClawdbotAPI.swift ContentView.swift; do
    if [ -f "Jarvis/$file" ]; then
        echo "  ✓ $file"
    else
        echo "  ✗ $file MISSING"
        exit 1
    fi
done
echo ""

# Check dependencies
echo "✓ Checking dependencies..."

if command -v clawdbot &> /dev/null; then
    echo "  ✓ clawdbot installed: $(which clawdbot)"
else
    echo "  ✗ clawdbot NOT FOUND (required)"
fi

if command -v whisper &> /dev/null; then
    echo "  ✓ whisper installed: $(which whisper)"
else
    echo "  ⚠ whisper NOT installed (needed for voice)"
    echo "    Install: brew install openai-whisper"
fi

if command -v peekaboo &> /dev/null; then
    echo "  ✓ peekaboo installed: $(which peekaboo)"
else
    echo "  ⚠ peekaboo NOT installed (needed for screen context)"
    echo "    Install: npm install -g peekaboo"
fi

echo ""
echo "✓ Checking Clawdbot gateway..."
if curl -s http://localhost:8888/health &> /dev/null; then
    echo "  ✓ Gateway running on localhost:8888"
else
    echo "  ⚠ Gateway not responding"
    echo "    Start: clawdbot gateway start"
fi

echo ""
echo "=========================="
echo "To build: open Jarvis.xcodeproj and press ⌘R"
echo ""
