import SwiftUI

struct Message: Identifiable {
    let id = UUID()
    let text: String
    let isUser: Bool
    let timestamp: Date
}

struct ChatWindow: View {
    @State private var messages: [Message] = []
    @State private var inputText: String = ""
    @State private var isLoading: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Messages
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        ForEach(messages) { message in
                            MessageBubble(message: message)
                                .id(message.id)
                        }
                        
                        if isLoading {
                            HStack {
                                ProgressView()
                                    .scaleEffect(0.7)
                                Text("Thinking...")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                            }
                            .padding(.leading, 12)
                        }
                    }
                    .padding()
                }
                .onChange(of: messages.count) { _ in
                    if let lastMessage = messages.last {
                        withAnimation {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }
            
            Divider()
            
            // Input
            HStack(spacing: 8) {
                TextField("Message Jarvis...", text: $inputText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onSubmit {
                        sendMessage()
                    }
                
                Button(action: sendMessage) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                        .foregroundColor(inputText.isEmpty ? .gray : .accentColor)
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(inputText.isEmpty || isLoading)
            }
            .padding()
        }
        .frame(minWidth: 400, minHeight: 500)
    }
    
    func sendMessage() {
        guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let userMessage = Message(text: inputText, isUser: true, timestamp: Date())
        messages.append(userMessage)
        
        let messageToSend = inputText
        inputText = ""
        isLoading = true
        
        Task {
            do {
                let response = try await ClawdbotAPI.shared.sendMessage(messageToSend)
                
                await MainActor.run {
                    let botMessage = Message(text: response, isUser: false, timestamp: Date())
                    messages.append(botMessage)
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    let errorMessage = Message(
                        text: "Error: \(error.localizedDescription)",
                        isUser: false,
                        timestamp: Date()
                    )
                    messages.append(errorMessage)
                    isLoading = false
                }
            }
        }
    }
}

struct MessageBubble: View {
    let message: Message
    @State private var isHovering = false
    
    private var renderedText: Text {
        // Safely render markdown or fallback to plain text
        if !message.text.isEmpty {
            do {
                // Try full markdown parsing
                let attributedText = try AttributedString(markdown: message.text, options: .init(interpretedSyntax: .full))
                return Text(attributedText)
            } catch {
                // Fallback to plain text if markdown parsing fails
                print("Markdown parsing failed for text: \(message.text.prefix(100))")
                print("Error: \(error)")
                return Text(message.text)
            }
        } else {
            return Text(message.text)
        }
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            if message.isUser { Spacer() }
            
            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 4) {
                HStack(alignment: .top, spacing: 8) {
                    // Message content with Markdown support
                    renderedText
                        .textSelection(.enabled)
                        .padding(10)
                        .background(message.isUser ? Color.accentColor : Color(nsColor: .controlBackgroundColor))
                        .foregroundColor(message.isUser ? .white : .primary)
                        .cornerRadius(12)
                    
                    // Copy button (always visible for bot messages, on hover for user)
                    if !message.isUser || isHovering {
                        Button(action: {
                            copyToClipboard(message.text)
                        }) {
                            Image(systemName: "doc.on.doc")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .help("Copy message")
                        .padding(.top, 10)
                    }
                }
                
                Text(timeString(from: message.timestamp))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            if !message.isUser { Spacer() }
        }
        .onHover { hovering in
            isHovering = hovering
        }
    }
    
    func copyToClipboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }
    
    func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

#Preview {
    ChatWindow()
}
