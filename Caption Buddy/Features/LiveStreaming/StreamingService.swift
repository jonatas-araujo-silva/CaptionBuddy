import Foundation
import AgoraRtcKit
import Combine

#if targetEnvironment(simulator)
import SwiftUI
import AVKit
#endif

class StreamingService: NSObject, ObservableObject {
    
    @Published var remoteUserViews: [UInt: UIView] = [:]
    var chatMessagePublisher = PassthroughSubject<ChatMessage, Never>()
    
    private var agoraEngine: AgoraRtcEngineKit?
    private let appId: String = "a691bece736d4fa1bc23caedb7ae49e7"
    private var dataStreamId: Int = 0
    
    #if targetEnvironment(simulator)
    private var simulatorVideoPlayers: [AVPlayer] = []
    #endif

    override init() {
        super.init()
        #if !targetEnvironment(simulator)
        // Only initialize the real engine on a physical device
        initializeAgoraEngine()
        #endif
    }
    
    deinit {
        #if !targetEnvironment(simulator)
        agoraEngine?.leaveChannel(nil)
        AgoraRtcEngineKit.destroy()
        print("StreamingService deinitialized and Agora engine destroyed.")
        #endif
    }
    
    // MARK: - Public Methods
    
    /// Sets up the local user's video feed to be displayed.
    func setupLocalVideo(on view: UIView) {
        #if !targetEnvironment(simulator)
        let videoCanvas = AgoraRtcVideoCanvas()
        videoCanvas.uid = 0 // 0 = local user
        videoCanvas.view = view
        videoCanvas.renderMode = .hidden
        agoraEngine?.setupLocalVideo(videoCanvas)
        agoraEngine?.startPreview()
        #endif
    }
    
    /// Joins a specified channel to start or view a stream.
    func joinChannel(channelName: String, isBroadcaster: Bool) {
        #if targetEnvironment(simulator)
        print("SIMULATOR: Pretending to join channel '\(channelName)'.")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            print("SIMULATOR: A remote user has joined.")
            if let fakeView = self.createFakeRemoteVideoView() {
                self.remoteUserViews[123] = fakeView
            }
            let welcomeMessage = ChatMessage(isFromLocalUser: false, text: "Welcome!")
            self.chatMessagePublisher.send(welcomeMessage)
        }
        #else
        // -- REAL DEVICE --
        guard let engine = agoraEngine else {
            print("❌ Agora Engine not initialized.")
            return
        }
        let role: AgoraClientRole = isBroadcaster ? .broadcaster : .audience
        engine.setClientRole(role)
        engine.enableVideo()
        let config = AgoraDataStreamConfig()
        config.syncWithAudio = false
        config.ordered = true
        engine.createDataStream(&dataStreamId, config: config)
        engine.joinChannel(byToken: nil, channelId: channelName, info: nil, uid: 0) { (channel, uid, elapsed) in
            print("✅ Successfully joined channel: \(channel) with uid: \(uid)")
        }
        #endif
    }
    
    /// Leaves the current channel.
    func leaveChannel() {
        #if targetEnvironment(simulator)
        print("SIMULATOR: Pretending to leave channel.")
        simulatorVideoPlayers.removeAll()
        remoteUserViews.removeAll()
        #else
        // -- REAL DEVICE LOGIC --
        agoraEngine?.leaveChannel(nil)
        remoteUserViews.removeAll()
        print("Left channel.")
        #endif
    }
    
    /// Sends a chat message.
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
    
    // MARK: - Private Methods
    
    #if !targetEnvironment(simulator)
    private func initializeAgoraEngine() {
        agoraEngine = AgoraRtcEngineKit.sharedEngine(withAppId: appId, delegate: self)
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

// MARK: - AgoraRtcEngineDelegate
#if !targetEnvironment(simulator)
// This extension is only compiled for real devices.
extension StreamingService: AgoraRtcEngineDelegate {
    
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
