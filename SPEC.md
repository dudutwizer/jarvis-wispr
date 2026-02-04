# JARVIS Whisper - macOS Voice Assistant

## Overview
A **lightweight, FAST** SwiftUI macOS menubar app for voice-to-JARVIS communication.

## Core Requirements

### Recording
- Menubar icon with click-to-record
- Visual indicator when recording (icon change + optional small window)
- Save ALL recordings locally (`~/Library/Application Support/JarvisWhispr/recordings/`)
- Never delete recordings - they're a backup in case transcription fails

### Transcription
- Use OpenAI Whisper API for transcription
- API key stored in UserDefaults/Keychain
- Show transcription result briefly before sending

### Screenshot Context
- Capture current screen when recording starts
- Compress to reasonable size (not full resolution)
- Send along with transcription for context

### Webhook Integration
- POST to configurable webhook URL
- Payload:
```json
{
  "transcription": "user's spoken text",
  "screenshot": "base64 encoded image",
  "timestamp": "ISO8601",
  "mode": "auto"  // let JARVIS decide: "task" or "clipboard"
}
```

### Response Handling
- Listen for webhook response
- If response contains `"action": "telegram"` → show notification "Sent to Telegram"
- If response contains `"action": "clipboard"` + `"text": "..."` → 
  - Copy text to clipboard
  - Show notification "Copied to clipboard"
  - Optionally auto-paste (accessibility permission)

## Settings
- Webhook URL (default: openclaw iOS webhook)
- OpenAI API key for Whisper
- Recording quality (low/medium/high)
- Auto-paste toggle
- Keyboard shortcut customization

## Technical Stack
- SwiftUI for UI
- AVFoundation for recording
- ScreenCaptureKit for screenshots
- URLSession for HTTP

## Priority
1. FAST - minimize latency at every step
2. Native - pure SwiftUI, no Electron
3. Reliable - save recordings as backup
4. Simple - minimal UI, just works

## NOT in v1
- Chat window
- Conversation history
- Multiple profiles
- Complex settings

Keep it SIMPLE and FAST!
