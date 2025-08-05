import Foundation
import AgoraRtcKit
import Combine

#if targetEnvironment(simulator)
import SwiftUI
import AVKit
#endif

// Define what any "Streaming Service" must be able to do.
protocol StreamingServiceProtocol {
    var rawAudioPublisher: PassthroughSubject<Data, Never> { get }
    
    func joinChannel(channelName: String, isBroadcaster: Bool)
    func leaveChannel()
    func sendMessage(_ messageText: String) // Add this line
}

class StreamingService: NSObject, ObservableObject, StreamingServiceProtocol {
    
    @Published var remoteUserViews: [UInt: UIView] = [:]
    var chatMessagePublisher = PassthroughSubject<ChatMessage, Never>()
    
    var rawAudioPublisher = PassthroughSubject<Data, Never>()
    
    private var agoraEngine: AgoraRtcEngineKit?
    private let appId: String = "YOUR_AGORA_APP_ID"
    private var dataStreamId: Int = 0
    
    #if targetEnvironment(simulator)
    private var simulatorVideoPlayers: [AVPlayer] = []
    #endif

    override init() {
        super.init()
        #if !targetEnvironment(simulator)
        initializeAgoraEngine()
        #endif
    }
    
    deinit {
        #if !targetEnvironment(simulator)
        agoraEngine?.leaveChannel(nil)
        AgoraRtcEngineKit.destroy()
        #endif
    }
    
    // MARK: - Public Methods
    
    func setupLocalVideo(on view: UIView) {
        #if !targetEnvironment(simulator)
        let videoCanvas = AgoraRtcVideoCanvas()
        videoCanvas.uid = 0
        videoCanvas.view = view
        videoCanvas.renderMode = .hidden
        agoraEngine?.setupLocalVideo(videoCanvas)
        agoraEngine?.startPreview()
        #endif
    }
    
    func joinChannel(channelName: String, isBroadcaster: Bool) {
        #if targetEnvironment(simulator)
        print("SIMULATOR: Pretending to join channel '\(channelName)'.")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            if let fakeView = self.createFakeRemoteVideoView() {
                self.remoteUserViews[123] = fakeView
            }
            let welcomeMessage = ChatMessage(isFromLocalUser: false, text: "Welcome!")
            self.chatMessagePublisher.send(welcomeMessage)
        }
        #else
        guard let engine = agoraEngine else { return }
        
        engine.setAudioFrameDelegate(self)
        
        let role: AgoraClientRole = isBroadcaster ? .broadcaster : .audience
        engine.setClientRole(role)
        engine.enableVideo()
        
        let config = AgoraDataStreamConfig()
        config.syncWithAudio = false
        config.ordered = true
        engine.createDataStream(&dataStreamId, config: config)
        
        engine.joinChannel(byToken: nil, channelId: channelName, info: nil, uid: 0)
        #endif
    }
    
    func leaveChannel() {
        #if targetEnvironment(simulator)
        print("SIMULATOR: Pretending to leave channel.")
        simulatorVideoPlayers.removeAll()
        remoteUserViews.removeAll()
        #else
        agoraEngine?.leaveChannel(nil)
        remoteUserViews.removeAll()
        #endif
    }
    
    func sendMessage(_ messageText: String) {
        #if targetEnvironment(simulator)
        let message = ChatMessage(isFromLocalUser: true, text: messageText)
        chatMessagePublisher.send(message)
        #else
        guard let data = messageText.data(using: .utf8) else { return }
        agoraEngine?.sendStreamMessage(dataStreamId, data: data)
        let message = ChatMessage(isFromLocalUser: true, text: messageText)
        chatMessagePublisher.send(message)
        #endif
    }
    
    #if !targetEnvironment(simulator)
    private func initializeAgoraEngine() {
        agoraEngine = AgoraRtcEngineKit.sharedEngine(withAppId: appId, delegate: self)
        agoraEngine?.setRecordingAudioFrameParametersWithSampleRate(16000, channel: 1, mode: .readWrite, samplesPerCall: 1600)
    }
    #else
    private func createFakeRemoteVideoView() -> UIView? {
        guard let url = Bundle.main.url(forResource: "SecondVideo_Portfolio", withExtension: "mp4") else {
            print("❌ SIMULATOR ERROR: Could not find SecondVideo_Portfolio.mp4")
            return nil
        }
        let player = AVPlayer(url: url)
        player.isMuted = true
        player.play()
        simulatorVideoPlayers.append(player)
        let playerLayer = AVPlayerLayer(player: player)
        let view = UIView()
        playerLayer.frame = view.bounds
        playerLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(playerLayer)
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: player.currentItem, queue: .main) { _ in
            player.seek(to: .zero)
            player.play()
        }
        return view
    }
    #endif
}

// MARK: - AgoraRtcEngineDelegate & AgoraAudioFrameDelegate
#if !targetEnvironment(simulator)
// This extension is only compiled for real devices.
extension StreamingService: AgoraRtcEngineDelegate, AgoraAudioFrameDelegate {
    
    func onRecordAudioFrame(_ frame: AgoraAudioFrame) -> Bool {
        if let data = frame.buffer {
            // Publish the raw audio data to any listeners
            rawAudioPublisher.send(data)
        }
        return true
    }
    
    /// Called when a remote user joins the channel.
    func rtcEngine(_ engine: AgoraRtcEngineKit, didJoinedOfUid uid: UInt, elapsed: Int) {
        print("Remote user joined with uid: \(uid)")
        
        let view = UIView()
        let videoCanvas = AgoraRtcVideoCanvas()
        videoCanvas.uid = uid
        videoCanvas.view = view
        videoCanvas.renderMode = .hidden
        engine.setupRemoteVideo(videoCanvas)
        
        DispatchQueue.main.async {
            self.remoteUserViews[uid] = view
        }
    }
    
    /// Called when a remote user leaves the channel.
    func rtcEngine(_ engine: AgoraRtcEngineKit, didOfflineOfUid uid: UInt, reason: AgoraUserOfflineReason) {
        print("Remote user left with uid: \(uid)")
        
        DispatchQueue.main.async {
            self.remoteUserViews.removeValue(forKey: uid)
        }
    }
    
    /// Called when a chat message is received from a remote user.
    func rtcEngine(_ engine: AgoraRtcEngineKit, receiveStreamMessageFromUid uid: UInt, streamId: Int, data: Data) {
        guard let messageText = String(data: data, encoding: .utf8) else { return }
        let message = ChatMessage(isFromLocalUser: false, text: messageText)
        chatMessagePublisher.send(message)
    }
}
#endif
