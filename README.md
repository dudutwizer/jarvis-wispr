# Jarvis - Context-Aware Voice Assistant for macOS

A lightweight menubar app that gives you instant access to Clawdbot with keyboard shortcuts.

## Features

### 🎙️ Double-Tap Shortcuts
- **Double Control** → Open chat window
- **Double Option** → Start voice recording (hold, release to finish)

### 🧠 Context-Aware Transcription
When you record with Option:
1. Records your voice
2. Captures current screen context (via Peekaboo)
3. Sends both to Clawdbot
4. Gets back context-aware text
5. Auto-pastes into active app

Perfect for:
- Filling forms
- Writing emails
- Taking notes
- Any text input with visual context

## Setup

### 1. Build & Run
```bash
cd ~/Developer/jarvis
open Jarvis.xcodeproj
```

Build and run from Xcode (⌘R)

### 2. Grant Permissions
On first launch, you'll be prompted for:
- **Accessibility** (for keyboard monitoring & auto-paste)
- **Microphone** (for voice recording)

### 3. Dependencies
Jarvis uses:
- `clawdbot` CLI (for messaging)
- `peekaboo` (for screen context) - install via: `npm install -g peekaboo`

## Usage

### Chat Window
- Double-tap **Control** anywhere
- Type and press Enter
- Window stays on top (floating)

### Voice Recording
- Double-tap and **hold Option**
- Speak your message
- Release Option to finish
- Text auto-pastes to active window

## Architecture

```
Jarvis (menubar app)
├── KeyMonitor → double-tap detection
├── ChatWindow → SwiftUI chat interface
├── VoiceRecorder → AVFoundation recording
└── ClawdbotAPI → CLI/HTTP communication
```

## Tips

- Voice recording captures screen context automatically
- Chat window remembers conversation history
- Minimal resource usage (runs as accessory app)
- Uses system mic permissions (no separate entitlements needed)

## Troubleshooting

**Keyboard shortcuts not working?**
→ Grant Accessibility permission in System Settings

**Voice recording fails?**
→ Check microphone permissions

**Can't connect to Clawdbot?**
→ Make sure `clawdbot gateway start` is running

## Future Ideas

- Customizable shortcuts
- Multiple voice profiles
- Screen recording instead of snapshots
- Persistent chat history
- Quick actions menu
# jarvis-wispr
