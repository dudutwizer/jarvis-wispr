import Foundation

class TranscriptionService {
    static let shared = TranscriptionService()
    
    private let whisperEndpoint = "https://api.openai.com/v1/audio/transcriptions"
    
    func transcribe(audioURL: URL, completion: @escaping (String?) -> Void) {
        guard let apiKey = UserDefaults.standard.string(forKey: "openai_api_key"), !apiKey.isEmpty else {
            print("OpenAI API key not set")
            completion(nil)
            return
        }
        
        var request = URLRequest(url: URL(string: whisperEndpoint)!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // Add model field
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"model\"\r\n\r\n".data(using: .utf8)!)
        body.append("whisper-1\r\n".data(using: .utf8)!)
        
        // Add audio file
        if let audioData = try? Data(contentsOf: audioURL) {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"file\"; filename=\"audio.m4a\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: audio/m4a\r\n\r\n".data(using: .utf8)!)
            body.append(audioData)
            body.append("\r\n".data(using: .utf8)!)
        }
        
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Transcription error: \(error)")
                DispatchQueue.main.async { completion(nil) }
                return
            }
            
            guard let data = data else {
                DispatchQueue.main.async { completion(nil) }
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let text = json["text"] as? String {
                    print("Transcription: \(text)")
                    DispatchQueue.main.async { completion(text) }
                } else {
                    print("Unexpected response: \(String(data: data, encoding: .utf8) ?? "")")
                    DispatchQueue.main.async { completion(nil) }
                }
            } catch {
                print("JSON parsing error: \(error)")
                DispatchQueue.main.async { completion(nil) }
            }
        }.resume()
    }
}
