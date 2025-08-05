import Foundation
import Combine
import AVFoundation

@MainActor
class RecorderViewModel: ObservableObject {
    
    private let recordingService: RecordingServiceProtocol
    
    @Published var previewLayer: AVCaptureVideoPreviewLayer?
    @Published var isSessionReady = false
    @Published var isRecording = false
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        #if targetEnvironment(simulator)
        self.recordingService = SimulatorRecordingService()
        #else
        self.recordingService = AVFoundationRecordingService()
        #endif
        
        recordingService.previewLayerPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] layer in
                self?.previewLayer = layer
            }
            .store(in: &cancellables)
            
        recordingService.isConfiguredPublisher
            .receive(on: DispatchQueue.main)
            .assign(to: \.isSessionReady, on: self)
            .store(in: &cancellables)
            
        recordingService.isRecordingPublisher
            .receive(on: DispatchQueue.main)
            .assign(to: \.isRecording, on: self)
            .store(in: &cancellables)
    }
    
    func toggleRecording() async {
        if isRecording {
            await recordingService.stopRecording()
        } else {
            await recordingService.startRecording()
        }
    }
}
