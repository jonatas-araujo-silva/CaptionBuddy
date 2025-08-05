import Foundation
import AVFoundation
import Combine

/* Defines standards for any service that provides video recording
 * functionality. Allows use of dependency injection to provide different
 * implementations for the real app and for testing/simulators.
 */

protocol RecordingServiceProtocol {
    // Publishers for the UI to observe the service's state.
    var isRecordingPublisher: AnyPublisher<Bool, Never> { get }
    var isConfiguredPublisher: AnyPublisher<Bool, Never> { get }
    var previewLayerPublisher: PassthroughSubject<AVCaptureVideoPreviewLayer, Never> { get
    }
    
    // Asynchronous methods to control the recording.
    func startRecording() async
    func stopRecording() async
}
