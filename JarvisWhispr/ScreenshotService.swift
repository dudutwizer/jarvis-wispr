import Foundation
import AppKit

class ScreenshotService {
    static let shared = ScreenshotService()
    
    func captureScreen(completion: @escaping (Data?) -> Void) {
        let displayID = CGMainDisplayID()
        
        guard let screenshot = CGDisplayCreateImage(displayID) else {
            print("Failed to capture screen")
            completion(nil)
            return
        }
        
        let bitmapRep = NSBitmapImageRep(cgImage: screenshot)
        
        // Compress to JPEG at 50% quality for reasonable size
        guard let jpegData = bitmapRep.representation(using: .jpeg, properties: [.compressionFactor: 0.5]) else {
            print("Failed to convert screenshot to JPEG")
            completion(nil)
            return
        }
        
        // Resize if too large (max 1MB)
        if jpegData.count > 1_000_000 {
            if let lowerQuality = bitmapRep.representation(using: .jpeg, properties: [.compressionFactor: 0.3]) {
                print("Screenshot captured: \(lowerQuality.count) bytes")
                completion(lowerQuality)
                return
            }
        }
        
        print("Screenshot captured: \(jpegData.count) bytes")
        completion(jpegData)
    }
}
