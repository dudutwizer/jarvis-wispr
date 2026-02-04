# Fixes Applied to Jarvis

## Issues Fixed

### 1. **Recording Won't Stop** ✅
**Problem:** Global event monitor doesn't capture events when app has focus

**Fix:** Added BOTH global AND local event monitors in VoiceRecorder.swift
- Global monitor: catches Option release when app is background
- Local monitor: catches Option release when app has focus
- Both call the same handler

### 2. **iOS-only APIs** ✅
**Problem:** Used AVAudioSession and AVCaptureDevice (iOS-only)

**Fix:** 
- Removed AVAudioSession (not needed on macOS)
- Removed AVCaptureDevice.requestAccess (macOS requests mic permission automatically)
- Uses pure AVFoundation AVAudioRecorder (macOS compatible)

### 3. **Missing SwiftUI Import** ✅
**Problem:** VoiceRecorder.swift had SwiftUI views without import

**Fix:** Added `import SwiftUI` to VoiceRecorder.swift

### 4. **Transcription Won't Work** ✅
**Problem:** Was trying to send audio path as text to Clawdbot

**Fix:** 
- Primary: Use openai-whisper CLI directly if installed
- Fallback: Show helpful error about installing whisper
- Command: `brew install openai-whisper`

### 5. **Recording Timer Added** ✅
**Enhancement:** Added elapsed time counter in recording indicator
- Shows seconds elapsed
- Better user feedback

### 6. **Better Logging** ✅
**Enhancement:** Added debug prints throughout VoiceRecorder
- "Stopping recording..."
- "Recording saved to: <path>"
- "Option released, stopping recording"

## How to Test

### Build in Xcode
```bash
cd ~/Developer/jarvis
open Jarvis.xcodeproj
# Press ⌘B to build
# Press ⌘R to run
```

### Test Recording
1. Double-tap and **HOLD** Option key
2. See recording indicator with timer
3. Speak something
4. **RELEASE** Option key
5. Should stop automatically

### Install Whisper (Required for Voice)
```bash
brew install openai-whisper
```

### Check Permissions
- System Settings > Privacy & Security > Accessibility → Enable Jarvis
- System Settings > Privacy & Security > Microphone → Enable Jarvis

## Known Limitations

1. **Whisper Required:** Voice transcription needs openai-whisper CLI
2. **Peekaboo Required:** Screen context needs peekaboo npm package
3. **Clawdbot Required:** Chat needs clawdbot gateway running

## Architecture

```
Double Option Hold
     ↓
VoiceRecorder.startRecording()
     ↓
AVAudioRecorder starts (macOS will ask for mic permission)
     ↓
Event monitors watch for Option release
     ↓
Option released → stopRecording()
     ↓
Audio saved to /tmp/jarvis_recording_<timestamp>.m4a
     ↓
JarvisApp.processVoiceRecording()
     ↓
1. Capture screen with peekaboo
2. Transcribe audio with whisper
3. Send both to Clawdbot
4. Get context-aware response
5. Auto-paste with Cmd+V simulation
```

## Next Steps if Still Not Working

1. Check Console.app for errors
2. Enable verbose logging in VoiceRecorder
3. Test mic permissions with Voice Memos app
4. Verify Accessibility permission granted
5. Make sure Clawdbot gateway is running

## Files Changed

- `Jarvis/VoiceRecorder.swift` - Complete rewrite
- `Jarvis/ClawdbotAPI.swift` - Fixed transcription
- `Jarvis/JarvisApp.swift` - Removed iOS-only APIs

Build again and it should work! 🚀
