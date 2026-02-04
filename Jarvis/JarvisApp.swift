import SwiftUI
import AppKit
import AVFoundation

@main
struct JarvisApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    var statusItem: NSStatusItem!
    var keyMonitor: KeyMonitor!
    var chatWindow: NSWindow?
    var settingsWindow: NSWindow?
    var voiceRecorder: VoiceRecorder!
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        print("🚀 [JARVIS] applicationDidFinishLaunching called")
        
        // Hide from Dock
        NSApp.setActivationPolicy(.accessory)
        print("✅ [JARVIS] Activation policy set to accessory")
        
        // Create menubar item with explicit error handling
        let bar = NSStatusBar.system
        let item = bar.statusItem(withLength: NSStatusItem.variableLength)
        
        self.statusItem = item
        print("✅ [JARVIS] statusItem created successfully")
        
        guard let button = item.button else {
            print("❌ [JARVIS] CRITICAL: Status item has no button!")
            fatalError("Status item has no button!")
        }
        print("✅ [JARVIS] statusItem.button available")
        
        // Set image with fallback
        if let image = NSImage(systemSymbolName: "mic.circle", accessibilityDescription: "Jarvis") {
            button.image = image
            print("✅ [JARVIS] Button image set (SF Symbol)")
        } else {
            button.title = "🎤"
            print("⚠️  [JARVIS] Using fallback emoji icon")
        }
        
        // Configure button
        button.action = #selector(toggleChatWindow)
        button.target = self
        print("✅ [JARVIS] Button action configured")
        
        // Create and attach menu
        let menu = createMenu()
        item.menu = menu
        print("✅ [JARVIS] Menu attached to statusItem")
        
        // Initialize voice recorder
        voiceRecorder = VoiceRecorder()
        print("✅ [JARVIS] Voice recorder initialized")
        
        // Start key monitoring
        keyMonitor = KeyMonitor()
        keyMonitor.onDoubleControl = { [weak self] in
            self?.showChatWindow()
        }
        keyMonitor.onDoubleOption = { [weak self] in
            self?.startVoiceRecording()
        }
        keyMonitor.start()
        print("✅ [JARVIS] Key monitor started")
        
        // Request permissions
        requestPermissions()
        print("🎉 [JARVIS] Setup complete")
    }
    
    func createMenu() -> NSMenu {
        let menu = NSMenu()
        let chatItem = NSMenuItem(title: "Chat", action: #selector(toggleChatWindow), keyEquivalent: "")
        chatItem.target = self
        menu.addItem(chatItem)
        let settingsItem = NSMenuItem(title: "Settings", action: #selector(showSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)
        menu.addItem(NSMenuItem.separator())
        let quitItem = NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        return menu
    }
    
    func requestPermissions() {
        // Request accessibility permission
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as String: true]
        AXIsProcessTrustedWithOptions(options)
        
        // Microphone permission on macOS is requested automatically when AVAudioRecorder is used
        // No explicit pre-request needed like iOS
    }
    
    @objc func toggleChatWindow() {
        if let window = chatWindow, window.isVisible {
            window.close()
        } else {
            showChatWindow()
        }
    }
    
    func showChatWindow() {
        if let window = chatWindow, window.isVisible {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        
        // Create new window
        let contentView = ChatWindow()
        let hostingView = NSHostingView(rootView: contentView)
        
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 500),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Jarvis"
        window.contentView = hostingView
        window.center()
        window.level = .floating
        window.isReleasedWhenClosed = false
        
        // Set delegate to handle close
        window.delegate = self
        
        chatWindow = window
        
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    func startVoiceRecording() {
        print("🎙️ [VOICE] startVoiceRecording() called")
        voiceRecorder.startRecording { [weak self] audioFilePath in
            print("🎙️ [VOICE] Recording callback triggered")
            guard let audioFilePath = audioFilePath else {
                print("❌ [VOICE] No audio file path returned")
                self?.showAlert(title: "Recording Failed", message: "Could not save audio recording")
                return
            }
            
            print("✅ [VOICE] Audio saved to: \(audioFilePath)")
            self?.processVoiceRecording(audioPath: audioFilePath)
        }
    }
    
    func processVoiceRecording(audioPath: String) {
        print("🔄 [VOICE] Starting processVoiceRecording")
        print("📁 [VOICE] Audio path: \(audioPath)")
        
        Task {
            do {
                print("📸 [VOICE] Step 1: Capturing screen context...")
                let screenContext = await captureScreenContext()
                print("✅ [VOICE] Screen context: \(screenContext.isEmpty ? "empty" : "\(screenContext.count) chars")")
                
                print("🤖 [VOICE] Step 2: Sending to Clawdbot...")
                let response = try await ClawdbotAPI.shared.processVoiceWithContext(
                    audioPath: audioPath,
                    screenContext: screenContext
                )
                print("✅ [VOICE] Got response: \(response.prefix(100))...")
                
                print("📋 [VOICE] Step 3: Pasting response...")
                await pasteText(response)
                print("✅ [VOICE] Paste complete")
                
                print("🗑️  [VOICE] Step 4: Cleaning up audio file...")
                try? FileManager.default.removeItem(atPath: audioPath)
                print("✅ [VOICE] Complete!")
                
            } catch {
                print("❌ [VOICE] Error: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.showAlert(title: "Processing Failed", message: error.localizedDescription)
                }
            }
        }
    }
    
    func captureScreenContext() async -> String {
        // Try to capture screen context, but don't fail if peekaboo isn't installed
        do {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/bin/bash")
            
            // Set PATH to include homebrew
            let shellCommand = """
            export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"
            if command -v peekaboo > /dev/null 2>&1; then
                peekaboo snap --format text
            else
                echo ""
            fi
            """
            process.arguments = ["-c", shellCommand]
            
            let pipe = Pipe()
            process.standardOutput = pipe
            process.standardError = Pipe() // Suppress errors
            
            try process.run()
            process.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""
            
            if output.isEmpty {
                print("⚠️ Peekaboo not available, skipping screen context")
            } else {
                print("✅ Screen context captured: \(output.prefix(100))...")
            }
            
            return output
        } catch {
            print("⚠️ Failed to capture screen context: \(error.localizedDescription)")
            return ""
        }
    }
    
    func pasteText(_ text: String) async {
        print("📋 [PASTE] Starting paste operation")
        print("📋 [PASTE] Text to paste: \(text)")
        
        // Copy to clipboard
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        let success = pasteboard.setString(text, forType: .string)
        
        if success {
            print("✅ [PASTE] Text copied to clipboard")
        } else {
            print("❌ [PASTE] Failed to copy to clipboard")
            return
        }
        
        // Verify clipboard
        if let clipboardContent = pasteboard.string(forType: .string) {
            print("✅ [PASTE] Clipboard verified: \(clipboardContent.prefix(50))...")
        } else {
            print("❌ [PASTE] Clipboard verification failed")
        }
        
        // Small delay
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1s
        
        print("⌨️  [PASTE] Simulating Cmd+V...")
        
        // Simulate Cmd+V
        let source = CGEventSource(stateID: .hidSystemState)
        
        // Cmd down
        let cmdDown = CGEvent(keyboardEventSource: source, virtualKey: 0x37, keyDown: true)
        cmdDown?.flags = .maskCommand
        
        // V down
        let vDown = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: true)
        vDown?.flags = .maskCommand
        
        // V up
        let vUp = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: false)
        vUp?.flags = .maskCommand
        
        // Cmd up
        let cmdUp = CGEvent(keyboardEventSource: source, virtualKey: 0x37, keyDown: false)
        
        cmdDown?.post(tap: .cghidEventTap)
        vDown?.post(tap: .cghidEventTap)
        vUp?.post(tap: .cghidEventTap)
        cmdUp?.post(tap: .cghidEventTap)
        
        print("✅ [PASTE] Cmd+V events posted")
    }
    
    func showAlert(title: String, message: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
    
    @objc func showSettings() {
        if let window = settingsWindow, window.isVisible {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        
        // Create new settings window
        let contentView = SettingsWindow()
        let hostingView = NSHostingView(rootView: contentView)
        
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 550),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Jarvis Settings"
        window.contentView = hostingView
        window.center()
        window.isReleasedWhenClosed = false
        window.delegate = self
        
        settingsWindow = window
        
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    @objc func quit() {
        NSApplication.shared.terminate(nil)
    }
    
    // MARK: - NSWindowDelegate
    
    func windowWillClose(_ notification: Notification) {
        // Keep reference to window but allow it to close
        // This prevents crashes on reopen
    }
}
