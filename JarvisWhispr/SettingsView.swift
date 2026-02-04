import SwiftUI

struct SettingsView: View {
    @AppStorage("openai_api_key") private var openAIKey = ""
    @AppStorage("webhook_url") private var webhookURL = "https://clawdbot-railway-template-production-1dde.up.railway.app/hooks/ios"
    @AppStorage("auto_paste") private var autoPaste = false
    
    var body: some View {
        Form {
            Section("API Keys") {
                SecureField("OpenAI API Key", text: $openAIKey)
                    .textFieldStyle(.roundedBorder)
                Text("Used for Whisper transcription")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Section("Webhook") {
                TextField("Webhook URL", text: $webhookURL)
                    .textFieldStyle(.roundedBorder)
                Text("JARVIS endpoint for processing requests")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Button("Reset to Default") {
                    webhookURL = "https://clawdbot-railway-template-production-1dde.up.railway.app/hooks/ios"
                }
                .buttonStyle(.link)
            }
            
            Section("Behavior") {
                Toggle("Auto-paste clipboard responses", isOn: $autoPaste)
                Text("When enabled, clipboard responses will be automatically pasted")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Section("Info") {
                LabeledContent("Recordings") {
                    Button("Open Folder") {
                        let path = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
                            .appendingPathComponent("JarvisWhispr/recordings")
                        NSWorkspace.shared.open(path)
                    }
                }
                
                LabeledContent("Version") {
                    Text("1.0.0")
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 450, height: 400)
        .padding()
    }
}

#Preview {
    SettingsView()
}
