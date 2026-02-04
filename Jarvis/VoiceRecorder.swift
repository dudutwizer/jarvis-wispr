import AVFoundation
import AppKit
import SwiftUI

class VoiceRecorder: NSObject, AVAudioRecorderDelegate {
    private var audioRecorder: AVAudioRecorder?
    private var recordingCompletion: ((String?) -> Void)?
    private var recordingStartTime: Date?
    private var statusWindow: NSWindow?
    private var globalMonitor: Any?
    private var localMonitor: Any?
    
    func startRecording(completion: @escaping (String?) -> Void) {
        print("🎙️ VoiceRecorder: startRecording() called")
        self.recordingCompletion = completion
        
        // Check microphone permission first
        let status = AVCaptureDevice.authorizationStatus(for: .audio)
        
        switch status {
        case .notDetermined:
            print("⚠️ Microphone permission not determined, requesting...")
            AVCaptureDevice.requestAccess(for: .audio) { [weak self] granted in
                if granted {
                    print("✅ Microphone permission granted")
                    DispatchQueue.main.async {
                        self?.startRecording(completion: completion)
                    }
                } else {
                    print("❌ Microphone permission denied")
                    DispatchQueue.main.async {
                        self?.showPermissionAlert()
                        completion(nil)
                    }
                }
            }
            return
            
        case .denied, .restricted:
            print("❌ Microphone permission denied/restricted")
            showPermissionAlert()
            completion(nil)
            return
            
        case .authorized:
            print("✅ Microphone permission authorized")
            
        @unknown default:
            print("⚠️ Unknown microphone permission status")
            completion(nil)
            return
        }
        
        // Create recording file
        let tempDir = NSTemporaryDirectory()
        let fileName = "jarvis_recording_\(Int(Date().timeIntervalSince1970)).m4a"
        let filePath = (tempDir as NSString).appendingPathComponent(fileName)
        let fileURL = URL(fileURLWithPath: filePath)
        
        // Recording settings for macOS
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: fileURL, settings: settings)
            audioRecorder?.delegate = self
            
            // Start recording
            let success = audioRecorder?.record() ?? false
            if !success {
                throw NSError(domain: "VoiceRecorder", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to start recording"])
            }
            
            recordingStartTime = Date()
            
            // Show recording indicator
            showRecordingIndicator()
            
            // Setup BOTH global and local monitors for Option key
            setupStopMonitors()
            
        } catch {
            print("Recording failed: \(error)")
            DispatchQueue.main.async {
                completion(nil)
            }
        }
    }
    
    func stopRecording() {
        print("🛑 Stopping recording...")
        
        // Store URL before stopping (it might become nil after stop)
        let recordedURL = audioRecorder?.url
        
        // Stop recording
        audioRecorder?.stop()
        
        // Hide indicator
        hideRecordingIndicator()
        
        // Remove monitors safely
        if let monitor = globalMonitor {
            NSEvent.removeMonitor(monitor)
            globalMonitor = nil
        }
        if let monitor = localMonitor {
            NSEvent.removeMonitor(monitor)
            localMonitor = nil
        }
        
        // Call completion with saved URL
        if let url = recordedURL {
            print("✅ Recording saved to: \(url.path)")
            let completion = recordingCompletion
            recordingCompletion = nil
            completion?(url.path)
        } else {
            print("⚠️ No recording URL")
            let completion = recordingCompletion
            recordingCompletion = nil
            completion?(nil)
        }
        
        // Clean up
        audioRecorder = nil
        recordingStartTime = nil
    }
    
    private func setupStopMonitors() {
        let handler: (NSEvent) -> Void = { [weak self] event in
            guard let self = self else { return }
            
            // Check if Option key is NOT pressed anymore
            if !event.modifierFlags.contains(.option) && self.audioRecorder?.isRecording == true {
                // Make sure we've been recording for at least 1 second (avoid double-tap stopping it)
                if let startTime = self.recordingStartTime, Date().timeIntervalSince(startTime) > 1.0 {
                    print("Option released, stopping recording")
                    DispatchQueue.main.async {
                        self.stopRecording()
                    }
                }
            }
        }
        
        // Global monitor (when app doesn't have focus)
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged, handler: handler)
        
        // Local monitor (when app has focus)
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) { event in
            handler(event)
            return event
        }
    }
    
    private func showRecordingIndicator() {
        let view = RecordingIndicatorView()
        let hostingView = NSHostingView(rootView: view)
        
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 220, height: 120),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        window.backgroundColor = .clear
        window.isOpaque = false
        window.level = .statusBar
        window.contentView = hostingView
        window.center()
        window.makeKeyAndOrderFront(nil)
        
        statusWindow = window
    }
    
    private func hideRecordingIndicator() {
        DispatchQueue.main.async { [weak self] in
            self?.statusWindow?.close()
            self?.statusWindow = nil
        }
    }
    
    private func showPermissionAlert() {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "Microphone Access Required"
            alert.informativeText = "Jarvis needs microphone access to record voice input. Please grant permission in System Settings > Privacy & Security > Microphone."
            alert.alertStyle = .warning
            alert.addButton(withTitle: "Open Settings")
            alert.addButton(withTitle: "Cancel")
            
            let response = alert.runModal()
            if response == .alertFirstButtonReturn {
                // Open System Settings to microphone privacy
                if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone") {
                    NSWorkspace.shared.open(url)
                }
            }
        }
    }
    
    // AVAudioRecorderDelegate
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        print("Recording finished, success: \(flag)")
    }
    
    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        if let error = error {
            print("Recording error: \(error)")
        }
    }
}

struct RecordingIndicatorView: View {
    @State private var scale: CGFloat = 1.0
    @State private var elapsed: Int = 0
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "waveform.circle.fill")
                .font(.system(size: 40))
                .foregroundColor(.red)
                .scaleEffect(scale)
                .onAppear {
                    withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                        scale = 1.2
                    }
                }
            
            Text("🎙️ Recording... \(elapsed)s")
                .font(.headline)
                .onReceive(timer) { _ in
                    elapsed += 1
                }
            
            Text("Release ⌥ Option to finish")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(nsColor: .windowBackgroundColor))
                .shadow(color: .black.opacity(0.3), radius: 20)
        )
    }
}
