import Foundation
import AVFoundation
import Combine

@MainActor
class RecorderViewModel: ObservableObject {
    
    private let recordingService = RecordingService()
    
    @Published var previewLayer: AVCaptureVideoPreviewLayer?
    @Published var isSessionReady = false
    @Published var isRecording = false
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Subscribe to the previewLayerPublisher from the service.
        recordingService.previewLayerPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] layer in
                self?.previewLayer = layer
            }
            .store(in: &cancellables)
            
        // Subscribe to the isConfigured property from the service.
        recordingService.$isConfigured
            .receive(on: DispatchQueue.main)
            .assign(to: \.isSessionReady, on: self)
            .store(in: &cancellables)
            
        // Subscribe to the isRecording property from the service.
        recordingService.$isRecording
            .receive(on: DispatchQueue.main)
            .assign(to: \.isRecording, on: self)
            .store(in: &cancellables)
    }
    
    func toggleRecording() async {
        if isRecording {
            await recordingService.stopRecording()
        } else {
            recordingService.startRecording()
        }
    }
}
