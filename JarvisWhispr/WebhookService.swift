import Foundation

struct WebhookResponse: Codable {
    let action: String  // "clipboard" or "telegram"
    let text: String?   // For clipboard action
    let message: String? // For telegram action
}

struct WebhookPayload: Codable {
    let transcription: String
    let screenshot: String?  // Base64 encoded
    let timestamp: String
    let mode: String
}

class WebhookService {
    static let shared = WebhookService()
    
    private let defaultWebhookURL = "https://clawdbot-railway-template-production-1dde.up.railway.app/hooks/whispr"
    
    var webhookURL: String {
        UserDefaults.standard.string(forKey: "webhook_url") ?? defaultWebhookURL
    }
    
    func send(transcription: String, screenshot: Data?, completion: @escaping (WebhookResponse?) -> Void) {
        guard let url = URL(string: webhookURL) else {
            print("Invalid webhook URL")
            completion(nil)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 60  // Allow time for JARVIS to process
        
        let screenshotBase64 = screenshot?.base64EncodedString()
        
        let payload = WebhookPayload(
            transcription: transcription,
            screenshot: screenshotBase64,
            timestamp: ISO8601DateFormatter().string(from: Date()),
            mode: "auto"
        )
        
        do {
            request.httpBody = try JSONEncoder().encode(payload)
        } catch {
            print("Failed to encode payload: \(error)")
            completion(nil)
            return
        }
        
        print("Sending to webhook: \(transcription.prefix(50))...")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Webhook error: \(error)")
                // Still show success - request was sent, JARVIS will respond via Telegram
                DispatchQueue.main.async { 
                    completion(WebhookResponse(action: "telegram", text: nil, message: "Sent to JARVIS"))
                }
                return
            }
            
            // For async webhooks, any 2xx response means success
            if let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) {
                print("Webhook accepted (status \(httpResponse.statusCode))")
                DispatchQueue.main.async {
                    completion(WebhookResponse(action: "telegram", text: nil, message: "Processing..."))
                }
                return
            }
            
            // Try to parse response (for future sync support)
            if let data = data {
                do {
                    let response = try JSONDecoder().decode(WebhookResponse.self, from: data)
                    print("Webhook response: action=\(response.action)")
                    DispatchQueue.main.async { completion(response) }
                    return
                } catch {
                    if let text = String(data: data, encoding: .utf8) {
                        print("Webhook response (text): \(text.prefix(100))")
                    }
                }
            }
            
            DispatchQueue.main.async { completion(nil) }
        }.resume()
    }
}
