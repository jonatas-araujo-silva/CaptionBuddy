import XCTest
import Combine
import AVFoundation
@testable import Caption_Buddy

/* Mock version of RecordingService, created for testing.
 * Conforms to the RecordingServiceProtocol, so ViewModel can use it.
 */

class MockRecordingService: RecordingServiceProtocol {
    
    // Control values from test to simulate different states
    @Published var isRecording: Bool = false
    @Published var isConfigured: Bool = true
    
    // Expose publishers required by protocol
    var isRecordingPublisher: Published<Bool>.Publisher { $isRecording }
    var isConfiguredPublisher: Published<Bool>.Publisher { $isConfigured }
    var previewLayerPublisher = PassthroughSubject<AVCaptureVideoPreviewLayer, Never>()
    
    // Flags that can check if ViewModel called the correct methods
    var startRecordingCalled = false
    var stopRecordingCalled = false
    
    func startRecording() {
        startRecordingCalled = true
        isRecording = true
    }
    
    func stopRecording() async {
        stopRecordingCalled = true
        isRecording = false
    }
}



 //Test case that verifies business logic of the RecorderViewModel:
@MainActor
final class RecorderViewModelTests: XCTestCase {

    var viewModel: RecorderViewModel!
    var mockService: MockRecordingService!
    private var cancellables: Set<AnyCancellable>!

    override func setUpWithError() throws {
        try super.setUpWithError()
        // For each test, creates a new mock service and inject it into ViewModel
        mockService = MockRecordingService()
        viewModel = RecorderViewModel(recordingService: mockService)
        cancellables = []
    }

    override func tearDownWithError() throws {
        viewModel = nil
        mockService = nil
        cancellables = nil
        try super.tearDownWithError()
    }

    // MARK: - Test Functions

    func testToggleRecording_whenNotRecording_shouldStartRecording() async {
        // GIVEN: Service is not currently recording
        mockService.isRecording = false
        // Allow publisher to update ViewModel:
        await Task.yield()
        
        // WHEN: We call the toggleRecording function.
        await viewModel.toggleRecording()
        
        // THEN: ViewModel should have called the startRecording method on the service
        XCTAssertTrue(mockService.startRecordingCalled, "startRecording() should have been called.")
        XCTAssertFalse(mockService.stopRecordingCalled, "stopRecording() should not have been called.")
    }
    
    func testToggleRecording_whenRecording_shouldStopRecording() async {
        // GIVEN: The service is currently recording.
        mockService.isRecording = true
        // Allow publisher to update the ViewModel:
        await Task.yield()
        
        // WHEN: We call the toggleRecording function.
        await viewModel.toggleRecording()
        
        // THEN: ViewModel should have called the stopRecording method on the service.
        XCTAssertTrue(mockService.stopRecordingCalled, "stopRecording() should have been called.")
        XCTAssertFalse(mockService.startRecordingCalled, "startRecording() should not have been called.")
    }
    
    func testIsRecordingState_shouldSyncWithService() {
        // GIVEN: A clean ViewModel
        let expectation = XCTestExpectation(description: "isRecording should update to true")
        
        // Observe the ViewModel's isRecording property.
        viewModel.$isRecording
            .dropFirst() // Ignore initial mock value
            .sink { isRecording in
                // THEN: ViewModel's property should become true
                if isRecording {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // WHEN:Mock service's isRecording property changes to true
        mockService.isRecording = true
        
        // Wait for the expectation to be fullfilled.
        wait(for: [expectation], timeout: 1.0)
    }
}
