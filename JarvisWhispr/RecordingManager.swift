import Foundation
import AVFoundation

class RecordingManager: NSObject, ObservableObject {
    static let shared = RecordingManager()
    
    @Published var isRecording = false
    var currentScreenshot: Data?
    
    private var audioRecorder: AVAudioRecorder?
    private var currentRecordingURL: URL?
    
    private let recordingsDirectory: URL = {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let recordings = appSupport.appendingPathComponent("JarvisWhispr/recordings", isDirectory: true)
        try? FileManager.default.createDirectory(at: recordings, withIntermediateDirectories: true)
        return recordings
    }()
    
    func startRecording() {
        let fileName = "recording_\(ISO8601DateFormatter().string(from: Date())).m4a"
            .replacingOccurrences(of: ":", with: "-")
        let fileURL = recordingsDirectory.appendingPathComponent(fileName)
        currentRecordingURL = fileURL
        
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: fileURL, settings: settings)
            audioRecorder?.prepareToRecord()
            audioRecorder?.record()
            
            DispatchQueue.main.async {
                self.isRecording = true
            }
            print("Recording started: \(fileURL.path)")
        } catch {
            print("Recording failed to start: \(error)")
        }
    }
    
    func stopRecording(completion: @escaping (URL?) -> Void) {
        audioRecorder?.stop()
        
        DispatchQueue.main.async {
            self.isRecording = false
        }
        
        if let url = currentRecordingURL {
            print("Recording saved: \(url.path)")
            completion(url)
        } else {
            completion(nil)
        }
        
        audioRecorder = nil
    }
}
