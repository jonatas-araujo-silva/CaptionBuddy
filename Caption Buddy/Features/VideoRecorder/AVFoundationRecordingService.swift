import Foundation
import AVFoundation
import Combine

/* Real implementation of the RecordingServiceProtocol that uses AVFoundation to capture and record video and audio from the device's hardware.
 */

class AVFoundationRecordingService: NSObject, ObservableObject, RecordingServiceProtocol {

    // MARK: - Protocol Conformance
    var isRecordingPublisher: AnyPublisher<Bool, Never> { $isRecording.eraseToAnyPublisher() }
    var isConfiguredPublisher: AnyPublisher<Bool, Never> { $isConfigured.eraseToAnyPublisher() }
    var previewLayerPublisher = PassthroughSubject<AVCaptureVideoPreviewLayer, Never>()
    
    // MARK: - Published Properties
    @MainActor @Published private var isConfigured = false
    @MainActor @Published private var isRecording = false

    // MARK: - Private Properties
    private let session = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "com.captionbuddy.session.queue")
    private let dataOutputQueue = DispatchQueue(label: "com.captionbuddy.data.output.queue")
    
    // Dependencies are injected
    private let dataManager: DataManager
    private let captionService: CaptionService
    
    private var videoDeviceInput: AVCaptureDeviceInput?
    private var audioDeviceInput: AVCaptureDeviceInput?
    private var videoOutput: AVCaptureVideoDataOutput?
    private var audioOutput: AVCaptureAudioDataOutput?
    private var assetWriter: AVAssetWriter?
    private var assetWriterVideoInput: AVAssetWriterInput?
    private var assetWriterAudioInput: AVAssetWriterInput?
    private var sessionAtSourceTime: CMTime?
    
    // Initializer accepts dependencies
    init(dataManager: DataManager = .shared, captionService: CaptionService = .shared) {
        self.dataManager = dataManager
        self.captionService = captionService
        super.init()
        
        sessionQueue.async {
            self.configureSession()
        }
    }
    
    deinit {
        sessionQueue.async {
            if self.session.isRunning {
                self.session.stopRunning()
            }
        }
    }

    private func configureSession() {
        session.beginConfiguration()
        session.sessionPreset = .high

        // Video Input Setup
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let videoDeviceInput = try? AVCaptureDeviceInput(device: videoDevice),
              session.canAddInput(videoDeviceInput) else {
            print("Error: Could not create video device input.")
            session.commitConfiguration()
            return
        }
        session.addInput(videoDeviceInput)
        self.videoDeviceInput = videoDeviceInput

        // Audio Input Setup
        guard let audioDevice = AVCaptureDevice.default(for: .audio),
              let audioDeviceInput = try? AVCaptureDeviceInput(device: audioDevice),
              session.canAddInput(audioDeviceInput) else {
            print("Error: Could not create audio device input.")
            session.commitConfiguration()
            return
        }
        session.addInput(audioDeviceInput)
        self.audioDeviceInput = audioDeviceInput
        
        // Video Output Setup
        let videoOutput = AVCaptureVideoDataOutput()
        if session.canAddOutput(videoOutput) {
            videoOutput.setSampleBufferDelegate(self, queue: dataOutputQueue)
            session.addOutput(videoOutput)
            self.videoOutput = videoOutput
        }
        
        // Audio Output Setup
        let audioOutput = AVCaptureAudioDataOutput()
        if session.canAddOutput(audioOutput) {
            audioOutput.setSampleBufferDelegate(self, queue: dataOutputQueue)
            session.addOutput(audioOutput)
            self.audioOutput = audioOutput
        }
        
        session.commitConfiguration()
        
        self.session.startRunning()
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: self.session)
        previewLayer.videoGravity = .resizeAspectFill
        
        Task { @MainActor in
            self.previewLayerPublisher.send(previewLayer)
            self.isConfigured = true
        }
    }

    func startRecording() async {
        dataOutputQueue.async {
            guard !self.isRecording else { return }
            let outputURL = self.createNewFileURL()
            do {
                self.assetWriter = try AVAssetWriter(outputURL: outputURL, fileType: .mov)
            } catch {
                print("Error: Could not create asset writer: \(error)")
                return
            }
            let videoSettings: [String: Any] = [ AVVideoCodecKey: AVVideoCodecType.h264, AVVideoWidthKey: 1920, AVVideoHeightKey: 1080 ]
            self.assetWriterVideoInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
            self.assetWriterVideoInput?.expectsMediaDataInRealTime = true
            if let videoInput = self.assetWriterVideoInput, self.assetWriter?.canAdd(videoInput) == true { self.assetWriter?.add(videoInput) }
            
            let audioSettings: [String: Any] = [ AVFormatIDKey: kAudioFormatMPEG4AAC, AVNumberOfChannelsKey: 1, AVSampleRateKey: 44100.0, AVEncoderBitRateKey: 64000 ]
            self.assetWriterAudioInput = AVAssetWriterInput(mediaType: .audio, outputSettings: audioSettings)
            self.assetWriterAudioInput?.expectsMediaDataInRealTime = true
            if let audioInput = self.assetWriterAudioInput, self.assetWriter?.canAdd(audioInput) == true { self.assetWriter?.add(audioInput) }
            
            self.sessionAtSourceTime = nil
            self.assetWriter?.startWriting()
            
            Task { @MainActor in
                self.isRecording = true
            }
        }
    }

    func stopRecording() async {
        await MainActor.run { self.isRecording = false }
        
        guard let writer = self.assetWriter else { return }
        let videoURL = writer.outputURL
        
        await writer.finishWriting()
        
        print("Finished writing video to: \(videoURL)")
        
        let result = await captionService.transcribeVideo(url: videoURL)
        switch result {
        case .success(let timedCaptions):
            await dataManager.saveVideo(url: videoURL, timedCaptions: timedCaptions)
        case .failure(let error):
            print("Transcription failed: \(error.localizedDescription)")
        }
        
        self.assetWriter = nil
        self.assetWriterVideoInput = nil
        self.assetWriterAudioInput = nil
    }
    
    private func createNewFileURL() -> URL {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let fileName = "video-\(formatter.string(from: Date())).mov"
        return documentsDirectory.appendingPathComponent(fileName)
    }
}

// Delegate extension for AVCaptureVideoDataOutputSampleBufferDelegate
extension AVFoundationRecordingService: AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate {
    @MainActor func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard isRecording, let writer = assetWriter, writer.status == .writing else { return }
        let presentationTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        if sessionAtSourceTime == nil {
            sessionAtSourceTime = presentationTime
            writer.startSession(atSourceTime: presentationTime)
        }
        if output is AVCaptureVideoDataOutput, let videoInput = assetWriterVideoInput, videoInput.isReadyForMoreMediaData {
            videoInput.append(sampleBuffer)
        }
        if output is AVCaptureAudioDataOutput, let audioInput = assetWriterAudioInput, audioInput.isReadyForMoreMediaData {
            audioInput.append(sampleBuffer)
        }
    }
}
