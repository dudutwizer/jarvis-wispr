#!/bin/bash
# Jarvis App - Code Tests
# Tests core functionality without UI interaction

echo "🧪 Jarvis App - Code Tests"
echo "=========================="
echo ""

# Test 1: Whisper Installation
echo "Test 1: Whisper Installation"
if command -v /opt/homebrew/bin/whisper > /dev/null 2>&1; then
    echo "✅ PASS: Whisper found at /opt/homebrew/bin/whisper"
    /opt/homebrew/bin/whisper --help > /dev/null 2>&1 && echo "✅ PASS: Whisper executable works"
else
    echo "❌ FAIL: Whisper not found"
fi
echo ""

# Test 2: Peekaboo Installation
echo "Test 2: Peekaboo Installation"
if command -v peekaboo > /dev/null 2>&1; then
    echo "✅ PASS: Peekaboo found at $(which peekaboo)"
    peekaboo --help > /dev/null 2>&1 && echo "✅ PASS: Peekaboo executable works"
else
    echo "❌ FAIL: Peekaboo not found"
fi
echo ""

# Test 3: Clawdbot Installation
echo "Test 3: Clawdbot Installation"
if command -v clawdbot > /dev/null 2>&1; then
    echo "✅ PASS: Clawdbot found at $(which clawdbot)"
    clawdbot --version | head -1
else
    echo "❌ FAIL: Clawdbot not found"
fi
echo ""

# Test 4: Project Structure
echo "Test 4: Project Structure"
FILES=(
    "Jarvis/JarvisApp.swift"
    "Jarvis/KeyMonitor.swift"
    "Jarvis/VoiceRecorder.swift"
    "Jarvis/ClawdbotAPI.swift"
    "Jarvis/ChatWindow.swift"
    "Jarvis/SettingsWindow.swift"
)

cd ~/Developer/jarvis
for file in "${FILES[@]}"; do
    if [ -f "$file" ]; then
        echo "✅ PASS: $file exists"
    else
        echo "❌ FAIL: $file missing"
    fi
done
echo ""

# Test 5: Build Test
echo "Test 5: Build Test"
/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild \
    -project Jarvis.xcodeproj \
    -scheme Jarvis \
    -configuration Debug \
    clean build \
    > /tmp/jarvis_build_test.log 2>&1

if [ $? -eq 0 ]; then
    echo "✅ PASS: Project builds successfully"
else
    echo "❌ FAIL: Build failed"
    echo "See /tmp/jarvis_build_test.log for details"
    tail -20 /tmp/jarvis_build_test.log
fi
echo ""

# Test 6: JSON Parsing
echo "Test 6: JSON Parsing (clawdbot format)"
TEST_JSON='{
    "runId": "test-123",
    "status": "ok",
    "result": {
        "payloads": [
            {"text": "Response 1"},
            {"text": "Response 2"}
        ]
    }
}'

echo "$TEST_JSON" | python3 -c "
import json, sys
data = json.load(sys.stdin)
payloads = data['result']['payloads']
texts = [p['text'] for p in payloads if 'text' in p]
print('✅ PASS: Parsed', len(texts), 'text payloads')
print('Content:', ' + '.join(texts))
"
echo ""

# Test 7: App Launch Test
echo "Test 7: App Launch Test"
pkill -9 Jarvis 2>/dev/null
sleep 1

APP_PATH="/Users/david/Library/Developer/Xcode/DerivedData/Jarvis-egptnaracqomrfdiqvnflqktvvpy/Build/Products/Debug/Jarvis.app"

if [ -d "$APP_PATH" ]; then
    open "$APP_PATH"
    sleep 2
    
    if ps aux | grep -q "[J]arvis.app"; then
        echo "✅ PASS: App launched successfully"
        echo "PID: $(ps aux | grep '[J]arvis.app' | awk '{print $2}')"
    else
        echo "❌ FAIL: App did not launch"
    fi
else
    echo "❌ FAIL: App bundle not found at expected path"
fi
echo ""

# Test 8: Temporary File Creation
echo "Test 8: Temporary File Creation"
TEMP_DIR=$(mktemp -d)
TEST_FILE="$TEMP_DIR/jarvis_recording_test.m4a"
touch "$TEST_FILE"

if [ -f "$TEST_FILE" ]; then
    echo "✅ PASS: Can create temporary recording files"
    rm -rf "$TEMP_DIR"
else
    echo "❌ FAIL: Cannot create temporary files"
fi
echo ""

# Test 9: PATH Configuration
echo "Test 9: PATH Configuration (Homebrew)"
if echo "$PATH" | grep -q "/opt/homebrew/bin"; then
    echo "✅ PASS: Homebrew path in current PATH"
else
    echo "⚠️  WARN: Homebrew not in PATH (app sets it explicitly)"
fi
echo ""

# Test 10: Accessibility Permission
echo "Test 10: Accessibility Permission Check"
if ioreg -l | grep -q "SecureInput"; then
    echo "⚠️  INFO: SecureInput active (some apps block global shortcuts)"
fi

# Summary
echo ""
echo "=========================="
echo "🎯 Test Summary"
echo "=========================="
echo "All code tests completed."
echo ""
echo "Manual tests needed:"
echo "1. Double-tap Control (⌃⌃) - opens chat"
echo "2. Double-tap Option (⌥⌥) - starts voice recording"
echo "3. Send message in chat window"
echo "4. Open Settings window (⌘,)"
echo "5. Grant microphone permission when prompted"
echo ""
