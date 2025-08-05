import Foundation
import Speech
import AVFoundation

// Responsible for generating a timed transcript from a video file's audio track.
 
class CaptionService {
    
    // shared instance for convenience in the main app
    static let shared = CaptionService()
    
    init() {}
    
    enum TranscriptionError: Error {
        case authorizationDenied(String)
        case recognizerNotAvailable(String)
        case transcriptionFailed(String)
    }
    
    /// Transcribes the audio from a video file and provides timed data for each word.
    /// - Parameter url: The URL of the video file to be transcribed.
    /// - Returns: A `Result` containing either an array of TimedCaption objects or an error.
    func transcribeVideo(url: URL) async -> Result<[TimedCaption], Error> {
        
        let authStatus = await requestAuthorization()
        
        guard authStatus == .authorized else {
            let message = "Speech recognition authorization denied."
            print("Error: \(message)")
            return .failure(TranscriptionError.authorizationDenied(message))
        }
        
        guard let recognizer = SFSpeechRecognizer(locale: Locale.current), recognizer.isAvailable else {
            let message = "Speech recognizer is not available for the current locale."
            print("Error: \(message)")
            return .failure(TranscriptionError.recognizerNotAvailable(message))
        }
        
        let request = SFSpeechURLRecognitionRequest(url: url)
        request.shouldReportPartialResults = false
        request.addsPunctuation = true
        
        print("-> Starting timed transcription for video at: \(url.lastPathComponent)")
        
        do {
            let result = try await performRecognition(with: request, on: recognizer)
            
            var timedCaptions: [TimedCaption] = []
            for segment in result.bestTranscription.segments {
                let caption = TimedCaption(
                    text: segment.substring,
                    startTime: segment.timestamp,
                    duration: segment.duration
                )
                timedCaptions.append(caption)
            }
            
            print("✅ Timed transcription successful: \(timedCaptions.count) words found.")
            return .success(timedCaptions)
        } catch {
            print("❌ Error during transcription: \(error.localizedDescription)")
            return .failure(error)
        }
    }
    
    // wrap the completion handler API for authorization
    private func requestAuthorization() async -> SFSpeechRecognizerAuthorizationStatus {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }
    }
    
    // Private helper to wrap the recognition task
    private func performRecognition(with request: SFSpeechURLRecognitionRequest, on recognizer: SFSpeechRecognizer) async throws -> SFSpeechRecognitionResult {
        try await withCheckedThrowingContinuation { continuation in
            recognizer.recognitionTask(with: request) { result, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let result = result, result.isFinal else {
                    // shouldn't be hit with shouldReportPartialResults = false
                    let tempError = NSError(domain: "CaptionService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Recognition did not produce a final result."])
                    continuation.resume(throwing: tempError)
                    return
                }
                
                continuation.resume(returning: result)
            }
        }
    }
}
