import Foundation
import AVFoundation
import Combine

class RecorderViewModel: ObservableObject {
    
    private let recordingService = RecordingService()
    
    @Published var previewLayer: AVCaptureVideoPreviewLayer?
    @Published var isSessionReady = false
    @Published var isRecording = false
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init() {
        // Subscribe to previewLayerPublisher
        recordingService.previewLayerPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] layer in
                self?.previewLayer = layer
            }
            .store(in: &cancellables)
            
        // Subscribe to isConfigured property
        recordingService.$isConfigured
            .receive(on: DispatchQueue.main)
            .assign(to: \.isSessionReady, on: self)
            .store(in: &cancellables)
            
        // Subscribe to isRecording property
        recordingService.$isRecording
            .receive(on: DispatchQueue.main)
            .assign(to: \.isRecording, on: self)
            .store(in: &cancellables)
    }
    
    func toggleRecording() {
        if isRecording {
            recordingService.stopRecording()
        } else {
            recordingService.startRecording()
        }
    }
}
