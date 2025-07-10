import Foundation
import Combine
import AgoraRtcKit
#if targetEnvironment(simulator)
import SwiftUI
import AVKit
#endif

/*
 Encapsulates the logic for interacting with the Agora RTC SDK.
 * Responsibilities include:
 * -- Initializing the Agora Real-Time Communication (RTC) engine.
 * -- Joining and leaving streaming channels.
 * -- Managing local and remote video streams.
 * -- Handling delegate callbacks from Agora engine.
 */

class StreamingService: NSObject, ObservableObject {
    
    @Published var remoteUserViews: [UInt: UIView] = [:]
    var chatMessagePublisher = PassthroughSubject<ChatMessage, Never>()
    
    private var agoraEngine: AgoraRtcEngineKit?
    private let appId: String = "a691bece736d4fa1bc23caedb7ae49e7"
    private var dataStreamId: Int = 0
    private var simulatorVideoPlayers: [AVPlayer] = []

    override init() {
        super.init()
        #if !targetEnvironment(simulator)
        initializeAgoraEngine()
        #endif
    }
    
    deinit {
        agoraEngine?.leaveChannel(nil)
        AgoraRtcEngineKit.destroy()
    }
    
    #if targetEnvironment(simulator)
    private func createFakeVideoView(for videoName: String) -> UIView? {
        guard let url = Bundle.main.url(forResource: videoName, withExtension: "mp4") else {
            print("❌ SIMULATOR ERROR: Could not find \(videoName).mp4")
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

    func setupLocalVideo(on view: UIView) {
        #if !targetEnvironment(simulator)
        let videoCanvas = AgoraRtcVideoCanvas()
        videoCanvas.uid = 0
        videoCanvas.view = view
        videoCanvas.renderMode = .hidden
        agoraEngine?.setupLocalVideo(videoCanvas)
        #endif
    }
    
    func joinChannel(channelName: String, isBroadcaster: Bool) {
        #if targetEnvironment(simulator)
        print("SIMULATOR: Pretending to join channel '\(channelName)'.")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            if let remoteView = self.createFakeVideoView(for: "FirstVideo_Portfolio") {
                self.remoteUserViews[123] = remoteView
            }
            let welcomeMessage = ChatMessage(isFromLocalUser: false, text: "Welcome!")
            self.chatMessagePublisher.send(welcomeMessage)
        }
        #else
        guard let engine = agoraEngine else { return }
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

    func leaveChannel() {
        #if targetEnvironment(simulator)
        print("SIMULATOR: Pretending to leave channel.")
        simulatorVideoPlayers.removeAll()
        remoteUserViews.removeAll()
        #else
        agoraEngine?.leaveChannel(nil)
        remoteUserViews.removeAll()
        print("Left channel.")
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
    }
    #endif
}

#if !targetEnvironment(simulator)
extension StreamingService: AgoraRtcEngineDelegate {
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, didJoinedOfUid uid: UInt, elapsed: Int) {
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
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, didOfflineOfUid uid: UInt, reason: AgoraUserOfflineReason) {
        DispatchQueue.main.async {
            self.remoteUserViews.removeValue(forKey: uid)
        }
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, receiveStreamMessageFromUid uid: UInt, streamId: Int, data: Data) {
        guard let messageText = String(data: data, encoding: .utf8) else { return }
        let message = ChatMessage(isFromLocalUser: false, text: messageText)
        chatMessagePublisher.send(message)
    }
}
#endif
