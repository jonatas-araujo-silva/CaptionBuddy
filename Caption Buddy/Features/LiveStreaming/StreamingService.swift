import Foundation
import Combine
import AgoraRtcKit

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
    
    // Publisher for incoming chat messages
    var chatMessagePublisher = PassthroughSubject<ChatMessage, Never>()
    
    private var agoraEngine: AgoraRtcEngineKit?
    
    // App ID Agora Console
    private let appId: String = "a691bece736d4fa1bc23caedb7ae49e7"
    
    private var dataStreamId: Int = 0

    override init() {
        super.init()
        #if !targetEnvironment(simulator)
        initializeAgoraEngine()
        #endif
    }
    
    deinit {
        agoraEngine?.leaveChannel(nil)
        AgoraRtcEngineKit.destroy()
        print("StreamingService deinitialized and Agora engine destroyed.")
    }
    
    // MARK: - Public Methods
    
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
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            print("SIMULATOR: A remote user has joined.")
            let fakeUserID: UInt = 123
            self.remoteUserViews[fakeUserID] = self.createFakeUserView()
            
            //Simulate a welcome message
            let welcomeMessage = ChatMessage(isFromLocalUser: false, text: "Welcome to the stream!")
            self.chatMessagePublisher.send(welcomeMessage)
        }
        #else
        guard let engine = agoraEngine else { return }
        let role: AgoraClientRole = isBroadcaster ? .broadcaster : .audience
        engine.setClientRole(role)
        engine.enableVideo()
        
        // Create a data stream for chat messages
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
        remoteUserViews.removeAll()
        #else
        agoraEngine?.leaveChannel(nil)
        remoteUserViews.removeAll()
        print("Left channel.")
        #endif
    }
    
    func sendMessage(_ messageText: String) {
        #if targetEnvironment(simulator)
        // On simulator, publish the message locally
        let message = ChatMessage(isFromLocalUser: true, text: messageText)
        chatMessagePublisher.send(message)
        #else
        guard let data = messageText.data(using: .utf8) else { return }
        agoraEngine?.sendStreamMessage(dataStreamId, data: data)
        
        // Also publish the message locally so the sender sees it immediately
        let message = ChatMessage(isFromLocalUser: true, text: messageText)
        chatMessagePublisher.send(message)
        #endif
    }
    
    #if !targetEnvironment(simulator)
    private func initializeAgoraEngine() {
        agoraEngine = AgoraRtcEngineKit.sharedEngine(withAppId: appId, delegate: self)
    }
    #else
    private func createFakeUserView() -> UIView {
        let view = UIView()
        view.backgroundColor = .darkGray
        let label = UILabel()
        label.text = "Remote User"
        label.textColor = .white
        label.textAlignment = .center
        label.frame = view.bounds
        label.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(label)
        return view
    }
    #endif
}

#if !targetEnvironment(simulator)
extension StreamingService: AgoraRtcEngineDelegate {
    
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
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, didOfflineOfUid uid: UInt, reason: AgoraUserOfflineReason) {
        print("Remote user left with uid: \(uid)")
        DispatchQueue.main.async {
            self.remoteUserViews.removeValue(forKey: uid)
        }
    }
    
    // Delegate method to handle incoming chat messages 
    func rtcEngine(_ engine: AgoraRtcEngineKit, receiveStreamMessageFromUid uid: UInt, streamId: Int, data: Data) {
        guard let messageText = String(data: data, encoding: .utf8) else { return }
        let message = ChatMessage(isFromLocalUser: false, text: messageText)
        chatMessagePublisher.send(message)
    }
}
#endif
