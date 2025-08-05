import Foundation
import AVFoundation
import Combine

/* Mock implementation of the RecordingServiceProtocol that is used when
 * running the app on the iOS Simulator. Simulates the recording process
 * and generates sample data.
 */

class SimulatorRecordingService: ObservableObject, RecordingServiceProtocol {
    
    // MARK: - Protocol Conformance
    var isRecordingPublisher: AnyPublisher<Bool, Never> { $isRecording.eraseToAnyPublisher() }
    var isConfiguredPublisher: AnyPublisher<Bool, Never> { $isConfigured.eraseToAnyPublisher() }
    var previewLayerPublisher = PassthroughSubject<AVCaptureVideoPreviewLayer, Never>()
    
    @Published private var isConfigured = true
    @Published private var isRecording = false
    
    private let dataManager: DataManager
    
    init(dataManager: DataManager = .shared) {
        self.dataManager = dataManager
    }
    
    func startRecording() async {
        // Pretend to be recording by updating the state
        isRecording = true
    }

    func stopRecording() async {
        isRecording = false
        print("SIMULATOR: Generating sample recording.")
        await generateSampleRecording()
    }
    
    private func generateSampleRecording() async {
        guard let videoURL = Bundle.main.url(forResource: "DemoLibraryVideo", withExtension: "mp4"),
              let captionsURL = Bundle.main.url(forResource: "DemoLibraryCaption", withExtension: "json") else {
            print("❌ SIMULATOR ERROR: Could not find demo assets.")
            return
        }
        
        do {
            let captionsData = try Data(contentsOf: captionsURL)
            let timedCaptions = try JSONDecoder().decode([TimedCaption].self, from: captionsData)
            await dataManager.saveVideo(url: videoURL, timedCaptions: timedCaptions)
        } catch {
            print("❌ SIMULATOR ERROR: Failed to process sample data: \(error)")
        }
    }
}
