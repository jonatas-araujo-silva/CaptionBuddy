import Foundation
import Combine
import Speech

// Depends on a protocol for dependency injection and publishes errors for the UI.

@MainActor
class TranscribeLiveStreamUseCase: ObservableObject {
    
    // MARK: - Published Properties
    @Published var liveCaptionText: String = ""
    @Published var animationName: String? = nil
    
    // Publish errors to UI
    @Published var transcriptionError: String? = nil
    
    // MARK: - Private Properties
    private let streamingService: StreamingServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    // Uses the device current locale
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale.current)
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?

    // This service is being injected
    init(streamingService: StreamingServiceProtocol) {
        self.streamingService = streamingService
        
        // Subscribe to the raw audio publisher from the service protocol.
        streamingService.rawAudioPublisher
            .sink { [weak self] audioData in
                self?.appendAudioData(audioData)
            }
            .store(in: &cancellables)
    }
    
    /// Starts the transcription process.
    func start() {
        guard speechRecognizer?.isAvailable == true else {
            self.transcriptionError = "Speech recognizer is not available for the current language."
            return
        }
        
        SFSpeechRecognizer.requestAuthorization { authStatus in
            Task { @MainActor in
                if authStatus == .authorized {
                    self.startRecognition()
                } else {
                    self.transcriptionError = "Please grant permission to use speech recognition."
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
        transcriptionError = nil
    }
    
    // MARK: - Private Methods
    
    private func startRecognition() {
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else { return }
        
        recognitionRequest.shouldReportPartialResults = true
        
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }
            
            if let result = result {
                let transcript = result.bestTranscription.formattedString
                self.handleNewTranscript(transcript)
            }
            
            if error != nil {
                self.stop()
            }
        }
    }
    
    private func appendAudioData(_ data: Data) {
        // Architecture is ready for logic to be plugged in.
    }
    
    private func handleNewTranscript(_ transcript: String) {
        self.liveCaptionText = transcript
        
        if let lastWord = transcript.split(separator: " ").last {
            self.animationName = AnimationService.shared.animationName(for: String(lastWord))
        }
    }
}
