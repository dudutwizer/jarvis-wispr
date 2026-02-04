import SwiftUI

struct SettingsWindow: View {
    @State private var hasAccessibilityAccess: Bool = false
    @State private var lastKeyEvent: String = "No events yet"
    @State private var controlTapCount: Int = 0
    @State private var optionTapCount: Int = 0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Jarvis Settings")
                .font(.title)
                .bold()
            
            Divider()
            
            // Accessibility Status
            GroupBox(label: Label("Accessibility Access", systemImage: "hand.raised.fill")) {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Image(systemName: hasAccessibilityAccess ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(hasAccessibilityAccess ? .green : .red)
                        Text(hasAccessibilityAccess ? "Enabled" : "Disabled")
                            .font(.headline)
                    }
                    
                    if !hasAccessibilityAccess {
                        Text("Jarvis needs Accessibility permission to detect keyboard shortcuts.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Button("Open System Settings") {
                            openAccessibilitySettings()
                        }
                    }
                    
                    Button("Refresh Status") {
                        checkAccessibility()
                    }
                }
                .padding(10)
            }
            
            // Keyboard Shortcuts
            GroupBox(label: Label("Keyboard Shortcuts", systemImage: "keyboard")) {
                VStack(alignment: .leading, spacing: 15) {
                    // Chat shortcut
                    HStack {
                        Image(systemName: "message.fill")
                            .foregroundColor(.blue)
                        VStack(alignment: .leading) {
                            Text("Chat Window")
                                .font(.headline)
                            Text("Double-tap Control (⌃⌃)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Text("Taps: \(controlTapCount)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Divider()
                    
                    // Voice shortcut
                    HStack {
                        Image(systemName: "mic.fill")
                            .foregroundColor(.red)
                        VStack(alignment: .leading) {
                            Text("Voice Recording")
                                .font(.headline)
                            Text("Double-tap-and-hold Option (⌥⌥)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Text("Taps: \(optionTapCount)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(10)
            }
            
            // Debug Info
            GroupBox(label: Label("Debug", systemImage: "ant.fill")) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Last Event:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(lastKeyEvent)
                        .font(.system(.caption, design: .monospaced))
                        .padding(8)
                        .background(Color(nsColor: .textBackgroundColor))
                        .cornerRadius(6)
                }
                .padding(10)
            }
            
            Spacer()
        }
        .padding()
        .frame(width: 500, height: 550)
        .onAppear {
            checkAccessibility()
            startMonitoring()
        }
    }
    
    func checkAccessibility() {
        hasAccessibilityAccess = AXIsProcessTrusted()
    }
    
    func openAccessibilitySettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(url)
    }
    
    func startMonitoring() {
        // Monitor for key events
        NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) { event in
            let flags = event.modifierFlags
            let now = Date()
            let formatter = DateFormatter()
            formatter.timeStyle = .medium
            
            var pressed: [String] = []
            if flags.contains(.control) { 
                pressed.append("⌃")
                controlTapCount += 1
            }
            if flags.contains(.option) { 
                pressed.append("⌥")
                optionTapCount += 1
            }
            if flags.contains(.shift) { pressed.append("⇧") }
            if flags.contains(.command) { pressed.append("⌘") }
            
            if !pressed.isEmpty {
                lastKeyEvent = "\(formatter.string(from: now)) - Keys: \(pressed.joined(separator: " "))"
            }
            
            return event
        }
    }
}

#Preview {
    SettingsWindow()
}
