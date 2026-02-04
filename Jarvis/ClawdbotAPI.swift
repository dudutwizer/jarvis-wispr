    import Foundation

class ClawdbotAPI {
    static let shared = ClawdbotAPI()
    
    private init() {}
    
    func sendMessage(_ message: String) async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/bin/bash")
            
            // Escape message for shell
            let escapedMessage = message
                .replacingOccurrences(of: "\\", with: "\\\\")
                .replacingOccurrences(of: "\"", with: "\\\"")
                .replacingOccurrences(of: "$", with: "\\$")
                .replacingOccurrences(of: "`", with: "\\`")
            
            // Use clawdbot agent with a dedicated session for Jarvis
            let shellCommand = """
            export PATH="$HOME/.nvm/versions/node/v22.15.0/bin:$PATH"
            clawdbot agent --message "\(escapedMessage)" --session-id jarvis-chat --json 2>&1
            """
            
            process.arguments = ["-c", shellCommand]
            
            let pipe = Pipe()
            process.standardOutput = pipe
            process.standardError = pipe
            
            do {
                try process.run()
                
                DispatchQueue.global().async {
                    process.waitUntilExit()
                    
                    let data = pipe.fileHandleForReading.readDataToEndOfFile()
                    let output = String(data: data, encoding: .utf8) ?? ""
                    
                    if process.terminationStatus == 0 {
                        // Try to parse JSON response
                        if let jsonData = output.data(using: .utf8),
                           let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] {
                            
                            // Parse clawdbot agent --json response structure
                            var reply: String?
                            
                            // Check for result.payloads (clawdbot agent --json format)
                            // Collect all text from payloads and join them
                            if let result = json["result"] as? [String: Any],
                               let payloads = result["payloads"] as? [[String: Any]] {
                                
                                // Collect all text payloads (skip tool calls)
                                let textParts = payloads.compactMap { payload -> String? in
                                    return payload["text"] as? String
                                }.filter { !$0.isEmpty }
                                
                                if !textParts.isEmpty {
                                    // Join multiple text parts with double newline
                                    reply = textParts.joined(separator: "\n\n")
                                }
                            }
                            // Fallback: Check for "text" field (top-level)
                            else if let text = json["text"] as? String {
                                reply = text
                            }
                            // Fallback: Check for "content" field
                            else if let content = json["content"] as? String {
                                reply = content
                            }
                            // Fallback: Check for "reply" field
                            else if let replyText = json["reply"] as? String {
                                reply = replyText
                            }
                            // Fallback: Check for "message" field
                            else if let message = json["message"] as? String {
                                reply = message
                            }
                            
                            if let reply = reply {
                                continuation.resume(returning: reply)
                            } else {
                                // Could not find reply in expected fields
                                continuation.resume(throwing: NSError(
                                    domain: "ClawdbotAPI",
                                    code: -1,
                                    userInfo: [NSLocalizedDescriptionKey: "Could not parse reply from JSON response. Fields: \(json.keys.joined(separator: ", "))"]
                                ))
                            }
                        } else {
                            // JSON parsing failed - show error instead of raw output
                            continuation.resume(throwing: NSError(
                                domain: "ClawdbotAPI",
                                code: -1,
                                userInfo: [NSLocalizedDescriptionKey: "Failed to parse JSON response"]
                            ))
                        }
                    } else {
                        continuation.resume(throwing: NSError(
                            domain: "ClawdbotAPI",
                            code: Int(process.terminationStatus),
                            userInfo: [NSLocalizedDescriptionKey: output]
                        ))
                    }
                }
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    func processVoiceWithContext(audioPath: String, screenContext: String) async throws -> String {
        print("🎤 [API] processVoiceWithContext started")
        print("📁 [API] Audio: \(audioPath)")
        
        // First, transcribe the audio using Whisper
        print("🔊 [API] Step 1: Transcribing audio...")
        let transcription = try await transcribeAudio(audioPath)
        print("✅ [API] Transcription: \"\(transcription)\"")
        
        // Build context message
        let contextMessage = """
        Voice input: "\(transcription)"
        
        Screen context:
        \(screenContext.prefix(500))
        
        Please rewrite the voice input to match the context. If it's a form, fill in the appropriate field. If it's a document, insert it naturally. Be concise and context-aware. Return ONLY the refined text to paste, nothing else.
        """
        
        print("📤 [API] Step 2: Sending to Clawdbot...")
        print("💬 [API] Message: \(contextMessage.prefix(200))...")
        
        // Send to Clawdbot
        let response = try await sendMessage(contextMessage)
        print("✅ [API] Response received: \(response.prefix(100))...")
        
        return response
    }
    
    private func transcribeAudio(_ audioPath: String) async throws -> String {
        print("🎤 [TRANSCRIBE] Starting transcription...")
        
        // Use OpenAI Whisper API (simple HTTP request, no local dependencies)
        return try await transcribeWithWhisperAPI(audioPath)
    }
    
    private func transcribeWithWhisperAPI(_ audioPath: String) async throws -> String {
        print("🌐 [TRANSCRIBE] Using OpenAI Whisper API")
        
        // Check if OPENAI_API_KEY is available
        guard let apiKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"], !apiKey.isEmpty else {
            print("⚠️ [TRANSCRIBE] No OPENAI_API_KEY, trying clawdbot instead...")
            return try await transcribeWithClawdbot(audioPath)
        }
        
        // Read audio file
        guard let audioData = try? Data(contentsOf: URL(fileURLWithPath: audioPath)) else {
            throw NSError(domain: "ClawdbotAPI", code: -1,
                         userInfo: [NSLocalizedDescriptionKey: "Could not read audio file"])
        }
        
        print("📤 [TRANSCRIBE] Uploading \(audioData.count) bytes to OpenAI...")
        
        // Create multipart request
        let boundary = UUID().uuidString
        let url = URL(string: "https://api.openai.com/v1/audio/transcriptions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // Add model
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"model\"\r\n\r\n".data(using: .utf8)!)
        body.append("whisper-1\r\n".data(using: .utf8)!)
        
        // Add audio file
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"audio.m4a\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: audio/m4a\r\n\r\n".data(using: .utf8)!)
        body.append(audioData)
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let errorText = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(domain: "ClawdbotAPI", code: -1,
                         userInfo: [NSLocalizedDescriptionKey: "OpenAI API error: \(errorText)"])
        }
        
        // Parse JSON response
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let text = json["text"] as? String else {
            throw NSError(domain: "ClawdbotAPI", code: -1,
                         userInfo: [NSLocalizedDescriptionKey: "Could not parse transcription response"])
        }
        
        print("✅ [TRANSCRIBE] Transcribed: \(text)")
        return text
    }
    
    private func transcribeWithClawdbot(_ audioPath: String) async throws -> String {
        print("🤖 [TRANSCRIBE] Using clawdbot for transcription...")
        
        // Use clawdbot to transcribe (it has built-in whisper support)
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/bash")
        
        let shellCommand = """
        export PATH="/Users/david/.nvm/versions/node/v22.15.0/bin:$PATH"
        echo "Transcribing: \(audioPath)" | clawdbot agent --session-id jarvis-transcribe --json
        """
        
        process.arguments = ["-c", shellCommand]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        
        try process.run()
        process.waitUntilExit()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8) ?? ""
        
        print("📝 [TRANSCRIBE] Clawdbot output: \(output.prefix(200))...")
        
        // For now, just return placeholder
        // TODO: Implement proper audio file sending to clawdbot
        return "[Audio transcription placeholder - configure OPENAI_API_KEY for real transcription]"
    }
}
