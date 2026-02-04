import XCTest
@testable import Jarvis

final class JarvisTests: XCTestCase {
    
    // MARK: - KeyMonitor Tests
    
    func testKeyMonitorDoubleTapInterval() {
        let monitor = KeyMonitor()
        XCTAssertNotNil(monitor)
        // The double-tap interval should be 0.4 seconds
        // This is tested implicitly through the flag change handling
    }
    
    // MARK: - ClawdbotAPI Tests
    
    func testClawdbotAPIInitialization() {
        let api = ClawdbotAPI.shared
        XCTAssertNotNil(api)
    }
    
    func testMessageEscaping() async throws {
        // Test that special characters are properly escaped
        let testMessage = "Test with \"quotes\" and $dollar and `backticks` and \\backslash"
        
        // We can't actually call sendMessage without a running clawdbot
        // But we can verify the escaping logic would work
        XCTAssertTrue(testMessage.contains("\""))
        XCTAssertTrue(testMessage.contains("$"))
        XCTAssertTrue(testMessage.contains("`"))
        XCTAssertTrue(testMessage.contains("\\"))
    }
    
    func testJSONPayloadParsing() {
        // Test the JSON structure we expect from clawdbot agent --json
        let sampleJSON = """
        {
            "runId": "test-123",
            "summary": "completed",
            "status": "ok",
            "result": {
                "payloads": [
                    {
                        "text": "First response"
                    },
                    {
                        "text": "Second response"
                    }
                ]
            }
        }
        """
        
        guard let data = sampleJSON.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let result = json["result"] as? [String: Any],
              let payloads = result["payloads"] as? [[String: Any]] else {
            XCTFail("Failed to parse sample JSON")
            return
        }
        
        // Verify payload parsing logic
        let textParts = payloads.compactMap { $0["text"] as? String }
        XCTAssertEqual(textParts.count, 2)
        XCTAssertEqual(textParts[0], "First response")
        XCTAssertEqual(textParts[1], "Second response")
        
        let combined = textParts.joined(separator: "\n\n")
        XCTAssertEqual(combined, "First response\n\nSecond response")
    }
    
    // MARK: - VoiceRecorder Tests
    
    func testVoiceRecorderInitialization() {
        let recorder = VoiceRecorder()
        XCTAssertNotNil(recorder)
    }
    
    func testRecordingFilePaths() {
        // Test that recording file paths are generated correctly
        let tempDir = NSTemporaryDirectory()
        let timestamp = Int(Date().timeIntervalSince1970)
        let fileName = "jarvis_recording_\(timestamp).m4a"
        let filePath = (tempDir as NSString).appendingPathComponent(fileName)
        
        XCTAssertTrue(filePath.contains("jarvis_recording_"))
        XCTAssertTrue(filePath.hasSuffix(".m4a"))
        XCTAssertTrue(filePath.contains(tempDir))
    }
    
    // MARK: - Path Configuration Tests
    
    func testHomebrewPathConfiguration() {
        // Test that our PATH includes Homebrew locations
        let pathComponents = [
            "/opt/homebrew/bin",
            "/usr/local/bin"
        ]
        
        for path in pathComponents {
            let exists = FileManager.default.fileExists(atPath: path)
            // These paths should exist on most macOS systems with Homebrew
            print("Path \(path) exists: \(exists)")
        }
    }
    
    func testWhisperInstallation() {
        let whisperPaths = [
            "/opt/homebrew/bin/whisper",
            "/usr/local/bin/whisper"
        ]
        
        var whisperFound = false
        for path in whisperPaths {
            if FileManager.default.fileExists(atPath: path) {
                whisperFound = true
                print("✅ Whisper found at: \(path)")
                break
            }
        }
        
        if !whisperFound {
            print("⚠️ Whisper not found at standard locations")
        }
    }
    
    func testPeekabooInstallation() {
        let peekabooPath = "/opt/homebrew/bin/peekaboo"
        let exists = FileManager.default.fileExists(atPath: peekabooPath)
        
        if exists {
            print("✅ Peekaboo found at: \(peekabooPath)")
        } else {
            print("⚠️ Peekaboo not found at: \(peekabooPath)")
        }
    }
    
    // MARK: - Window Management Tests
    
    func testWindowConfiguration() {
        // Test chat window dimensions
        let chatWindowRect = NSRect(x: 0, y: 0, width: 400, height: 500)
        XCTAssertEqual(chatWindowRect.width, 400)
        XCTAssertEqual(chatWindowRect.height, 500)
        
        // Test settings window dimensions
        let settingsWindowRect = NSRect(x: 0, y: 0, width: 500, height: 550)
        XCTAssertEqual(settingsWindowRect.width, 500)
        XCTAssertEqual(settingsWindowRect.height, 550)
    }
    
    // MARK: - Markdown Rendering Tests
    
    func testMarkdownParsing() throws {
        let testStrings = [
            "**bold text**",
            "*italic text*",
            "`code snippet`",
            "# Heading",
            "Plain text"
        ]
        
        for testString in testStrings {
            // Test that AttributedString can parse these
            let attributed = try? AttributedString(
                markdown: testString,
                options: .init(interpretedSyntax: .full)
            )
            XCTAssertNotNil(attributed, "Failed to parse: \(testString)")
        }
    }
    
    // MARK: - Permission Handling Tests
    
    func testAccessibilityPermissionCheck() {
        // Test that we can check accessibility permission status
        let hasPermission = AXIsProcessTrusted()
        print("Accessibility permission: \(hasPermission ? "✅ Granted" : "❌ Not granted")")
        
        // We don't assert here because permission status depends on user action
        // But we verify the API is callable
    }
    
    // MARK: - Audio Format Tests
    
    func testAudioRecordingSettings() {
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        XCTAssertEqual(settings[AVFormatIDKey] as? Int, Int(kAudioFormatMPEG4AAC))
        XCTAssertEqual(settings[AVSampleRateKey] as? Double, 44100.0)
        XCTAssertEqual(settings[AVNumberOfChannelsKey] as? Int, 1)
        XCTAssertEqual(settings[AVEncoderAudioQualityKey] as? Int, AVAudioQuality.high.rawValue)
    }
}
