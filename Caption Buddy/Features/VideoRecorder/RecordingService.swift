import Foundation
import AVFoundation
import Combine

// Define the protocol to made this service testable.

protocol RecordingServiceProtocol {
    var isRecordingPublisher: Published<Bool>.Publisher { get }
    var isConfiguredPublisher: Published<Bool>.Publisher { get }
    var previewLayerPublisher: PassthroughSubject<AVCaptureVideoPreviewLayer, Never> { get }
    
    func startRecording()
    func stopRecording() async
}

class RecordingService: NSObject, ObservableObject, RecordingServiceProtocol {

    var isRecordingPublisher: Published<Bool>.Publisher { $isRecording }
    var isConfiguredPublisher: Published<Bool>.Publisher { $isConfigured }
    
    private let session = AVCaptureSession()
    
    var previewLayerPublisher = PassthroughSubject<AVCaptureVideoPreviewLayer, Never>()
    
    @MainActor @Published var isConfigured = false
    @MainActor @Published var isRecording = false

    private var videoDeviceInput: AVCaptureDeviceInput?
    private var audioDeviceInput: AVCaptureDeviceInput?
    private var videoOutput: AVCaptureVideoDataOutput?
    private var audioOutput: AVCaptureAudioDataOutput?
    private let sessionQueue = DispatchQueue(label: "session.queue")
    private let dataOutputQueue = DispatchQueue(label: "data.output.queue")
    private var assetWriter: AVAssetWriter?
    private var assetWriterVideoInput: AVAssetWriterInput?
    private var assetWriterAudioInput: AVAssetWriterInput?
    private var sessionAtSourceTime: CMTime?


    override init() {
        super.init()
        #if !targetEnvironment(simulator)
        sessionQueue.async {
            self.configureSession()
        }
        #endif
    }
    
    deinit {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            if self.session.isRunning {
                self.session.stopRunning()
            }
        }
    }

    #if !targetEnvironment(simulator)
    private func configureSession() {
        // Runs on the `sessionQueue`.
        session.beginConfiguration()
        session.sessionPreset = .high

        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let videoDeviceInput = try? AVCaptureDeviceInput(device: videoDevice),
              session.canAddInput(videoDeviceInput) else {
            print("Error: Could not create video device input.")
            session.commitConfiguration()
            return
        }
        session.addInput(videoDeviceInput)
        self.videoDeviceInput = videoDeviceInput

        guard let audioDevice = AVCaptureDevice.default(for: .audio),
              let audioDeviceInput = try? AVCaptureDeviceInput(device: audioDevice),
              session.canAddInput(audioDeviceInput) else {
            print("Error: Could not create audio device input.")
            session.commitConfiguration()
            return
        }
        session.addInput(audioDeviceInput)
        self.audioDeviceInput = audioDeviceInput
        
        let videoOutput = AVCaptureVideoDataOutput()
        if session.canAddOutput(videoOutput) {
            videoOutput.setSampleBufferDelegate(self, queue: dataOutputQueue)
            session.addOutput(videoOutput)
            self.videoOutput = videoOutput
        }
        
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
    #endif
    
    private func createNewFileURL() -> URL {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let fileName = "video-\(formatter.string(from: Date())).mov"
        return documentsDirectory.appendingPathComponent(fileName)
    }

    public func startRecording() {
        #if targetEnvironment(simulator)
        Task { @MainActor in self.isRecording = true }
        #else
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
        #endif
    }

    public func stopRecording() async {
        #if targetEnvironment(simulator)
        await MainActor.run { self.isRecording = false }
        print("SIMULATOR: Generating sample recording.")
        await generateSampleRecording()
        #else
        await MainActor.run { self.isRecording = false }
        
        guard let writer = self.assetWriter else { return }
        let videoURL = writer.outputURL
        
        await writer.finish()
        
        print("Finished writing video to: \(videoURL)")
        
        let result = await CaptionService.shared.transcribeVideo(url: videoURL)
        switch result {
        case .success(let timedCaptions):
            await DataManager.shared.saveVideo(url: videoURL, timedCaptions: timedCaptions)
        case .failure(let error):
            print("Transcription failed: \(error.localizedDescription)")
        }
        
        self.assetWriter = nil
        self.assetWriterVideoInput = nil
        self.assetWriterAudioInput = nil
        #endif
    }
    
    #if targetEnvironment(simulator)
    private func generateSampleRecording() async {
        guard let videoURL = Bundle.main.url(forResource: "sample_video", withExtension: "mp4"),
              let captionsURL = Bundle.main.url(forResource: "sample_captions", withExtension: "json") else {
            print("❌ SIMULATOR ERROR: Could not find sample_video.mp4 or sample_captions.json in the project Resources.")
            return
        }
        
        do {
            let captionsData = try Data(contentsOf: captionsURL)
            let decoder = JSONDecoder()
            let timedCaptions = try decoder.decode([TimedCaption].self, from: captionsData)
            await DataManager.shared.saveVideo(url: videoURL, timedCaptions: timedCaptions)
        } catch {
            print("❌ SIMULATOR ERROR: Failed to decode sample captions JSON: \(error)")
        }
    }
    #endif
}

#if !targetEnvironment(simulator)
extension RecordingService: AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate {
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
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
#endif
