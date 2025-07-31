import Foundation
import Combine
import AVFoundation

/* Depends on the RecordingServiceProtocol in order to made dependency injection of a mock service during unit tests.
 */

@MainActor
class RecorderViewModel: ObservableObject {
    
    private let recordingService: RecordingServiceProtocol
    
    @Published var previewLayer: AVCaptureVideoPreviewLayer?
    @Published var isSessionReady = false
    @Published var isRecording = false
    
    private var cancellables = Set<AnyCancellable>()
    
    // The default value `RecordingService()` ensures that the main app can still create the ViewModel
    init(recordingService: RecordingServiceProtocol = RecordingService()) {
        self.recordingService = recordingService
        
        // Subscribe to the publishers from the service protocol.
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
    
    /// Toggles the recording state by calling the appropriate method on the injected service.
    func toggleRecording() async {
        if isRecording {
            await recordingService.stopRecording()
        } else {
            recordingService.startRecording()
        }
    }
}
