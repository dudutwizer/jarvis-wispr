import Foundation
import AppKit
import ScreenCaptureKit

class ScreenshotService {
    static let shared = ScreenshotService()
    
    func captureScreen(completion: @escaping (Data?) -> Void) {
        // Use CGWindowListCreateImage for simplicity and speed
        // ScreenCaptureKit requires more setup but is better for permissions
        
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
            // Re-compress at lower quality
            if let lowerQuality = bitmapRep.representation(using: .jpeg, properties: [.compressionFactor: 0.3]) {
                print("Screenshot captured: \(lowerQuality.count) bytes")
                completion(lowerQuality)
                return
            }
        }
        
        print("Screenshot captured: \(jpegData.count) bytes")
        completion(jpegData)
    }
    
    // Alternative using ScreenCaptureKit (macOS 12.3+)
    @available(macOS 12.3, *)
    func captureWithScreenCaptureKit(completion: @escaping (Data?) -> Void) {
        Task {
            do {
                let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
                
                guard let display = content.displays.first else {
                    print("No display found")
                    completion(nil)
                    return
                }
                
                let filter = SCContentFilter(display: display, excludingWindows: [])
                let config = SCStreamConfiguration()
                config.width = display.width / 2  // Half resolution for speed
                config.height = display.height / 2
                config.pixelFormat = kCVPixelFormatType_32BGRA
                
                let image = try await SCScreenshotManager.captureImage(
                    contentFilter: filter,
                    configuration: config
                )
                
                let bitmapRep = NSBitmapImageRep(cgImage: image)
                let jpegData = bitmapRep.representation(using: .jpeg, properties: [.compressionFactor: 0.5])
                
                DispatchQueue.main.async {
                    completion(jpegData)
                }
            } catch {
                print("ScreenCaptureKit error: \(error)")
                DispatchQueue.main.async {
                    completion(nil)
                }
            }
        }
    }
}
