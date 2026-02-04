# Getting Started with Jarvis

## What is Jarvis?

Jarvis is a native macOS menubar app that gives you instant access to Clawdbot via keyboard shortcuts:

- **⌃⌃ (Double Control)** → Quick chat window
- **⌥⌥ (Double Option + hold)** → Context-aware voice input

## Quick Start

### 1. Open in Xcode

```bash
cd ~/Developer/jarvis
open Jarvis.xcodeproj
```

### 2. Build & Run

Press `⌘R` in Xcode, or click the Play button.

The app will appear in your menubar with a microphone icon.

### 3. Grant Permissions

On first launch:
1. **Accessibility**: System Settings → Privacy & Security → Accessibility → Enable Jarvis
2. **Microphone**: Will prompt automatically

### 4. Install Dependencies

Jarvis needs Peekaboo for screen context:

```bash
npm install -g peekaboo
```

Make sure Clawdbot is running:

```bash
clawdbot gateway start
```

## Using Jarvis

### Chat Mode (⌃⌃)
1. Double-tap Control key quickly
2. Chat window appears
3. Type your message
4. Press Enter to send
5. Clawdbot responds in the window

### Voice Mode (⌥⌥)
1. Double-tap and **hold** Option key
2. Recording indicator appears
3. Speak naturally
4. Release Option when done
5. Jarvis:
   - Transcribes your audio
   - Captures current screen
   - Asks Clawdbot to rewrite based on context
   - Auto-pastes into active app

## Example Use Cases

### Voice Mode Examples

**Filling a form:**
- Screen shows: "Email address: ______"
- You say: "david at example dot com"
- Pastes: "david@example.com"

**Writing email:**
- Screen shows: Gmail compose window
- You say: "tell them the meeting is tomorrow at 3"
- Pastes: "Hi, I wanted to let you know the meeting is scheduled for tomorrow at 3 PM. Looking forward to it!"

**Taking notes:**
- Screen shows: Notes app
- You say: "remind me to call john about the project"
- Pastes: "• Call John about the project"

### Chat Mode Examples

- Quick questions
- File operations
- System commands
- Long conversations
- Research tasks

## Project Structure

```
jarvis/
├── Jarvis.xcodeproj           # Xcode project
├── Jarvis/
│   ├── JarvisApp.swift        # Main app & menubar
│   ├── KeyMonitor.swift       # Double-tap detection
│   ├── ChatWindow.swift       # Chat UI
│   ├── VoiceRecorder.swift    # Audio recording
│   ├── ClawdbotAPI.swift      # Clawdbot integration
│   ├── Info.plist             # App metadata
│   ├── Jarvis.entitlements    # Permissions
│   └── Assets.xcassets/       # Icons & assets
├── README.md                  # Main documentation
├── GETTING_STARTED.md         # This file
└── build.sh                   # Build script (optional)

## How It Works

### Double-Tap Detection
- `KeyMonitor` listens for flag changes
- Tracks time between key taps
- < 0.3s = double-tap
- Triggers appropriate action

### Voice Recording
- AVFoundation captures audio
- Saves to temp file (.m4a)
- Shows floating recording indicator
- Stops on Option key release

### Context Awareness
1. Peekaboo captures screen text
2. Audio transcribed via Whisper
3. Both sent to Clawdbot
4. Clawdbot rewrites based on context
5. Result auto-pasted

### Auto-Paste
- Uses CGEvent API
- Copies to clipboard
- Simulates Cmd+V
- Works in any app

## Building for Distribution

If you want to share Jarvis or install it permanently:

### Option 1: Build Script
```bash
./build.sh
```

This builds a Release version and optionally installs to /Applications.

### Option 2: Archive in Xcode
1. Product → Archive
2. Distribute App
3. Copy App
4. Save to /Applications

### Option 3: Export from Xcode
1. Product → Build For → Running
2. Find in: `~/Library/Developer/Xcode/DerivedData/Jarvis-.../Build/Products/Debug/`
3. Copy Jarvis.app to /Applications

## Troubleshooting

### "Jarvis wants to control this computer"
→ Grant Accessibility permission in System Settings

### Shortcuts don't work
→ Check Accessibility permission
→ Make sure no other app is intercepting the keys

### Voice recording fails
→ Check microphone permission
→ Test with Voice Memos app

### Transcription fails
→ Make sure Clawdbot is running
→ Check that Whisper is available

### Can't paste
→ Grant Accessibility permission
→ Some apps block programmatic paste

### Peekaboo not found
→ Install: `npm install -g peekaboo`
→ Check PATH in app's environment

## Advanced Configuration

### Change Shortcuts
Edit `KeyMonitor.swift`:
- Change `doubleTapInterval` for timing sensitivity
- Add new key combinations in `handleFlagsChanged`

### Customize Chat UI
Edit `ChatWindow.swift`:
- Adjust window size
- Change colors/fonts
- Add custom features

### Modify Voice Processing
Edit `ClawdbotAPI.swift`:
- Change prompt for context processing
- Add custom preprocessing
- Integrate different transcription

## Tips & Tricks

1. **Use voice for forms** - Much faster than typing
2. **Chat for research** - Full conversation history
3. **Combine both** - Chat for context, voice for input
4. **Screen context is powerful** - It sees what you see
5. **Release Option early** - Don't need long holds

## Security & Privacy

- No network calls except to localhost Clawdbot
- Audio files stored temporarily, deleted after use
- Screen captures only for context (not saved)
- No telemetry or analytics
- Open source - audit the code!

## Next Steps

- Try both modes
- Customize to your workflow
- Report bugs or suggest features
- Build cool integrations!

---

Need help? Check the main README.md or ask Clawdbot directly! 🚀
