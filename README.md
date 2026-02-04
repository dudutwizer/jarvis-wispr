# JARVIS Whispr

A fast, native macOS menubar app for voice-to-JARVIS communication. Like WisprFlow, but better - it talks directly to JARVIS.

## Features

- **Click to Record** - Menubar icon, one click starts/stops recording
- **Instant Transcription** - Uses OpenAI Whisper API
- **Screenshot Context** - Captures screen when you start recording
- **Smart Responses** - JARVIS decides: Telegram reply or clipboard paste
- **Recording Backup** - All recordings saved locally (never re-record!)

## Requirements

- macOS 13.0+
- OpenAI API key (for Whisper transcription)
- JARVIS/OpenClaw instance with webhook

## Build & Run

### Option 1: Xcode (Recommended)

1. Open folder in Xcode: `File > Open > select jarvis-wispr folder`
2. Xcode will recognize the Package.swift
3. Select "My Mac" as destination
4. Build and Run (⌘R)

### Option 2: Command Line

```bash
swift build -c release
# Binary will be in .build/release/JarvisWhispr
```

### Create App Bundle (Optional)

To make a proper .app bundle, use Xcode's Archive feature or create manually:

```bash
mkdir -p JarvisWhispr.app/Contents/MacOS
cp .build/release/JarvisWhispr JarvisWhispr.app/Contents/MacOS/
cp JarvisWhispr/Info.plist JarvisWhispr.app/Contents/
```

## Setup

1. **First Launch** - Grant microphone permission when prompted
2. **Settings** (right-click menubar icon > Settings)
   - Enter your OpenAI API key
   - Webhook URL is pre-configured for JARVIS

## Usage

1. **Click** the mic icon in menubar to start recording
2. **Speak** your request or text
3. **Click** again to stop
4. Wait for transcription + JARVIS response:
   - **Task/Question**: Response sent to Telegram
   - **Text to refine**: Rephrased text copied to clipboard

## Response Modes

JARVIS automatically detects your intent:

- **"Send an email to..."** → Drafts text, copies to clipboard
- **"What's on my calendar?"** → Responds via Telegram
- **"Rephrase this paragraph"** → Improved text to clipboard
- **"Remind me to..."** → Confirms via Telegram

## Recordings Storage

All recordings are saved to:
```
~/Library/Application Support/JarvisWhispr/recordings/
```

Never deleted automatically - your backup in case transcription fails.

## Webhook Format

The app sends POST requests to the webhook:

```json
{
  "transcription": "user's spoken text",
  "screenshot": "base64 encoded JPEG",
  "timestamp": "2026-02-04T01:20:00Z",
  "mode": "auto"
}
```

Expected response for clipboard mode:
```json
{
  "action": "clipboard",
  "text": "refined text to paste"
}
```

Expected response for Telegram mode:
```json
{
  "action": "telegram",
  "message": "confirmation message"
}
```

## Troubleshooting

**No transcription?**
- Check OpenAI API key in Settings
- Verify microphone permission

**Screenshot not captured?**
- Grant Screen Recording permission in System Settings > Privacy

**Webhook not working?**
- Verify webhook URL in Settings
- Check JARVIS/OpenClaw is running

## License

MIT
