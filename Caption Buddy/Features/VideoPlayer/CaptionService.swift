import Foundation
import Speech
import AVFoundation

/* Responsible for taking a video file URL and generating
 * a detailed, timed transcript from its audio track.
 */
class CaptionService {
    
    static let shared = CaptionService()
    private init() {}
    
    enum TranscriptionError: Error {
        case authorizationDenied(String)
        case recognizerNotAvailable(String)
        case transcriptionFailed(String)
    }
    
    /// - Parameters:
    func transcribeVideo(url: URL, completion: @escaping (Result<[TimedCaption], Error>) -> Void) {
        
        SFSpeechRecognizer.requestAuthorization { authStatus in
            guard authStatus == .authorized else {
                let message = "Speech recognition authorization denied."
                print("Error: \(message)")
                DispatchQueue.main.async {
                    completion(.failure(TranscriptionError.authorizationDenied(message)))
                }
                return
            }
            
            guard let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US")), recognizer.isAvailable else {
                let message = "Speech recognizer is not available for the current locale."
                print("Error: \(message)")
                DispatchQueue.main.async {
                    completion(.failure(TranscriptionError.recognizerNotAvailable(message)))
                }
                return
            }
            
            let request = SFSpeechURLRecognitionRequest(url: url)
            request.shouldReportPartialResults = false
            request.addsPunctuation = true
            
            print("-> Starting timed transcription for video at: \(url.lastPathComponent)")
            
            recognizer.recognitionTask(with: request) { (result, error) in
                if let error = error {
                    print("Error during transcription: \(error.localizedDescription)")
                    DispatchQueue.main.async {
                        completion(.failure(error))
                    }
                    return
                }
                
                guard let result = result, result.isFinal else { return }

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
                DispatchQueue.main.async {
                    completion(.success(timedCaptions))
                }
            }
        }
    }
}
