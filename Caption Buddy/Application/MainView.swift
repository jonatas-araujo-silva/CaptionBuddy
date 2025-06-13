import SwiftUI
import AVFoundation
import Speech
import Lottie

struct MainView: View {
    var body: some View {
        TabView {
            RecorderView()
                .tabItem {
                    Image(systemName: "video.fill")
                    Text("Record")
                }

            VideoLibraryView()
                .tabItem {
                    Image(systemName: "photo.on.rectangle.angled")
                    Text("Library")
                }
            
            // MARK: - API Testing Tab
            APITestView()
                .tabItem {
                    Image(systemName: "ladybug.fill")
                    Text("API Tests")
                }
        }
        .accentColor(.red)
    }
}

// MARK: - API ViewModelTest
class APITestViewModel: ObservableObject {
    
    @Published var cameraPermissionGranted = false
    @Published var micPermissionGranted = false
    @Published var speechRecognitionStatus = "Not Started"
    @Published var transcriptionResult = ""
    @Published var coreDataStatus = "Ready"

    // Permissions:
    func checkAllPermissions() {
        checkCameraPermission()
        checkMicPermission()
    }

    func checkCameraPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            self.cameraPermissionGranted = true
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    self.cameraPermissionGranted = granted
                }
            }
        default:
            self.cameraPermissionGranted = false
        }
    }

    func checkMicPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized:
            self.micPermissionGranted = true
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .audio) { granted in
                DispatchQueue.main.async {
                    self.micPermissionGranted = granted
                }
            }
        default:
            self.micPermissionGranted = false
        }
    }
    
    //SFSpeechRecognizer:
    func runSpeechToTextTest() {
        self.speechRecognitionStatus = "Requesting Auth..."
        self.transcriptionResult = ""

        SFSpeechRecognizer.requestAuthorization { authStatus in
            DispatchQueue.main.async {
                guard authStatus == .authorized, let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US")) else {
                    self.speechRecognitionStatus = "Auth Denied"
                    return
                }
                
                guard let sampleAudioURL = Bundle.main.url(forResource: "test_audio", withExtension: "m4a") else {
                    self.speechRecognitionStatus = "Error: Test audio file not found."
                    self.transcriptionResult = "Please add a file named 'test_audio.m4a' to your project."
                    return
                }

                let request = SFSpeechURLRecognitionRequest(url: sampleAudioURL)
                self.speechRecognitionStatus = "Processing..."

                recognizer.recognitionTask(with: request) { (result, error) in
                    DispatchQueue.main.async {
                        if let error = error {
                            self.speechRecognitionStatus = "Recognition Error"
                            self.transcriptionResult = error.localizedDescription
                            return
                        }
                        
                        guard let result = result else {
                            self.speechRecognitionStatus = "No result"
                            return
                        }

                        self.transcriptionResult = result.bestTranscription.formattedString
                        if result.isFinal {
                            self.speechRecognitionStatus = "Success"
                        }
                    }
                }
            }
        }
    }
    
    //CORE DATA:
    func testCoreDataSave() {
        // Here we would get the managedObjectContext and save a dummy object
        // Placeholder for the actual implementation in Persistence.swift
        self.coreDataStatus = "Saved dummy video entry."
        print("-> Core Data: Pretended to save a test object.")
    }
    
    func testCoreDataLoad() {
        self.coreDataStatus = "Loaded dummy video entry."
        print("-> Core Data: Pretended to load test objects.")
    }
}


// MARK: - API ViewTest
struct APITestView: View {
    // instance of our ViewModel
    // @StateObject ensures it lives for the duration of the view.
    @StateObject private var viewModel = APITestViewModel()

    var body: some View {
        NavigationView {
            Form {
                // Section for Permissions API (AVFoundation)
                Section(header: Text("1. Permissions (AVFoundation)")) {
                    StatusRow(title: "Camera Access", isGranted: viewModel.cameraPermissionGranted)
                    StatusRow(title: "Microphone Access", isGranted: viewModel.micPermissionGranted)
                }
                
                // Section for Speech-to-Text API (Speech)
                Section(header: Text("2. Speech-to-Text (Speech Framework)")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Status: \(viewModel.speechRecognitionStatus)")
                            .font(.caption)
                        if !viewModel.transcriptionResult.isEmpty {
                            Text("Result: \"\(viewModel.transcriptionResult)\"")
                                .font(.body)
                                .foregroundColor(.primary)
                        }
                    }
                    Button("Run Speech Recognition Test") {
                        viewModel.runSpeechToTextTest()
                    }
                }
                
                // Section for CoreData
                Section(header: Text("3. Data Storage (CoreData)")) {
                    Text("Status: \(viewModel.coreDataStatus)")
                    HStack {
                        Button("Save Test Data") { viewModel.testCoreDataSave() }
                        Spacer()
                        Button("Load Test Data") { viewModel.testCoreDataLoad() }
                    }
                }
                
                // Section for Animation (Lottie)
                Section(header: Text("4. Animation (Lottie)")) {
                    // LottieView is a custom wrapper I'll create.
                    // It needs a .lottie file in project.
                    // placeholder.
                    VStack(alignment: .center) {
                         Text("Lottie Animation Preview")
                             .font(.headline)
                         // Add a LottieView here
                         // Example: LottieView(name: "hello_sign")
                         // For now: a placeholder image.
                         Image(systemName: "hand.wave.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.purple)
                            .frame(height: 150)
                    }
                }
            }
            .onAppear(perform: viewModel.checkAllPermissions)
            .navigationTitle("API Testing")
        }
    }
}

// MARK: - Helper Subview
struct StatusRow: View {
    let title: String
    let isGranted: Bool

    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Image(systemName: isGranted ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(isGranted ? .green : .red)
            Text(isGranted ? "Granted" : "Denied")
                .font(.subheadline)
                .foregroundColor(isGranted ? .green : .red)
        }
    }
}

// MARK: - Placeholder Views
// Temporary views that allow the TabView to compile.
// I'll replace them with the real feature views later.

struct RecorderViewTest: View {
    var body: some View {
        NavigationView {
            Text("Recorder View Placeholder")
                .navigationTitle("Recorder")
        }
    }
}

struct VideoLibraryView: View {
    var body: some View {
        NavigationView {
            Text("Video Library Placeholder")
                .navigationTitle("Library")
        }
    }
}


// MARK: - Preview
#Preview {
    MainView()
}
