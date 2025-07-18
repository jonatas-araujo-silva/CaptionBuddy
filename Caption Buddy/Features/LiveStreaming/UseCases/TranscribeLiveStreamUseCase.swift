import Foundation
import Combine
import Speech

/* Handles the specific business logic for real-time transcription
 * Takes raw audio data from the StreamingService and provides a live transcript.
 */

@MainActor
class TranscribeLiveStreamUseCase: ObservableObject {
    
    // MARK: - Published Properties
    @Published var liveCaptionText: String = ""
    @Published var animationName: String? = nil
    
    // MARK: - Private Properties
    private let streamingService: StreamingService
    private var cancellables = Set<AnyCancellable>()
    
    // Properties for Apple's Speech framework
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()

    init(streamingService: StreamingService) {
        self.streamingService = streamingService
        
        // Subscribe to raw audio publisher from StreamingService.
        streamingService.rawAudioPublisher
            .sink { [weak self] audioData in
                self?.appendAudioData(audioData)
            }
            .store(in: &cancellables)
    }
    
    /// Starts the transcription process.
    func start() {
        guard speechRecognizer?.isAvailable == true else {
            print("❌ Speech recognizer is not available.")
            return
        }
        
        // Request authorization to use speech recognition.
        SFSpeechRecognizer.requestAuthorization { authStatus in
            Task { @MainActor in
                if authStatus == .authorized {
                    self.startRecognition()
                } else {
                    print("❌ Speech recognition authorization denied.")
                }
            }
        }
    }
    
    /// Stops the transcription process.
    func stop() {
        recognitionTask?.cancel()
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        recognitionTask = nil
        
        liveCaptionText = ""
        animationName = nil
    }
    
    // MARK: - Private Methods
    
    private func startRecognition() {
        // Create a new recognition request.
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else { return }
        
        recognitionRequest.shouldReportPartialResults = true
        
        // Start the recognition task.
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self, let result = result else {
                self?.stop()
                return
            }
            
            // Update the UI with the latest transcript.
            let transcript = result.bestTranscription.formattedString
            self.handleNewTranscript(transcript)
        }
    }
    
    private func appendAudioData(_ data: Data) {
        // I'll need to convert the raw Data into a PCM buffer that SFSpeechRecognizer can use when I'll put this app into production.
        // recognitionRequest?.append(pcmBuffer)
    }
    
    private func handleNewTranscript(_ transcript: String) {
        self.liveCaptionText = transcript
        
        // Find the last word to check for an animation.
        if let lastWord = transcript.split(separator: " ").last {
            self.animationName = AnimationService.shared.animationName(for: String(lastWord))
        }
    }
}
