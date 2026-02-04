import SwiftUI
import AVFoundation

@main
struct JarvisWhisprApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            SettingsView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var recordingManager = RecordingManager.shared
    var popover = NSPopover()
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        setupMenuBar()
        
        // Request microphone permission
        AVCaptureDevice.requestAccess(for: .audio) { granted in
            print("Microphone access: \(granted)")
        }
    }
    
    func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "mic.fill", accessibilityDescription: "JARVIS Whispr")
            button.action = #selector(toggleRecording)
            button.target = self
        }
        
        // Setup right-click menu
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Settings...", action: #selector(openSettings), keyEquivalent: ","))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q"))
        statusItem.menu = menu
    }
    
    @objc func toggleRecording() {
        // Left click - hide menu, toggle recording
        statusItem.menu = nil
        
        if recordingManager.isRecording {
            stopRecording()
        } else {
            startRecording()
        }
        
        // Re-enable menu after a brief delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.setupMenuBar()
        }
    }
    
    func startRecording() {
        // Update icon
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "mic.circle.fill", accessibilityDescription: "Recording...")
            button.contentTintColor = .red
        }
        
        // Capture screenshot first (for context)
        ScreenshotService.shared.captureScreen { [weak self] screenshot in
            self?.recordingManager.currentScreenshot = screenshot
        }
        
        // Start recording
        recordingManager.startRecording()
    }
    
    func stopRecording() {
        // Update icon
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "mic.fill", accessibilityDescription: "JARVIS Whispr")
            button.contentTintColor = nil
        }
        
        // Stop and process
        recordingManager.stopRecording { [weak self] audioURL in
            guard let audioURL = audioURL else { return }
            self?.processRecording(audioURL: audioURL)
        }
    }
    
    func processRecording(audioURL: URL) {
        // Show processing indicator
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "ellipsis.circle", accessibilityDescription: "Processing...")
        }
        
        // Transcribe
        TranscriptionService.shared.transcribe(audioURL: audioURL) { [weak self] transcription in
            guard let transcription = transcription else {
                self?.showNotification(title: "Error", body: "Transcription failed")
                self?.resetIcon()
                return
            }
            
            // Send to webhook
            WebhookService.shared.send(
                transcription: transcription,
                screenshot: self?.recordingManager.currentScreenshot
            ) { response in
                self?.handleWebhookResponse(response)
                self?.resetIcon()
            }
        }
    }
    
    func handleWebhookResponse(_ response: WebhookResponse?) {
        guard let response = response else {
            showNotification(title: "Sent to JARVIS", body: "Processing your request...")
            return
        }
        
        switch response.action {
        case "clipboard":
            if let text = response.text {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(text, forType: .string)
                showNotification(title: "Copied to Clipboard", body: String(text.prefix(50)) + "...")
            }
        case "telegram":
            showNotification(title: "Sent to Telegram", body: response.message ?? "Message sent")
        default:
            showNotification(title: "Sent to JARVIS", body: "Processing...")
        }
    }
    
    func resetIcon() {
        DispatchQueue.main.async {
            if let button = self.statusItem.button {
                button.image = NSImage(systemSymbolName: "mic.fill", accessibilityDescription: "JARVIS Whispr")
                button.contentTintColor = nil
            }
        }
    }
    
    func showNotification(title: String, body: String) {
        let notification = NSUserNotification()
        notification.title = title
        notification.informativeText = body
        NSUserNotificationCenter.default.deliver(notification)
    }
    
    @objc func openSettings() {
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    @objc func quit() {
        NSApplication.shared.terminate(nil)
    }
}
