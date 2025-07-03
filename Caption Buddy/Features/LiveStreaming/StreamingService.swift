import Foundation
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
    
    // MARK: - Published Properties
    
    // Hold the UIView for a remote user's video stream.
    // Key = user's ID(UInt)
    @Published var remoteUserViews: [UInt: UIView] = [:]
    
    // MARK: - Private Properties
    
    // Core object of the Agora SDK
    private var agoraEngine: AgoraRtcEngineKit?
    
    // App ID Agora Console
    private let appId: String = "a691bece736d4fa1bc23caedb7ae49e7"
    
    // MARK: - Initialization
    
    override init() {
        super.init()
        initializeAgoraEngine()
    }
    
    // MARK: - Public Methods
    
    /// Sets the local user's video feed to be showed
    /// - Parameter view: UIView where the local camera feed should rendered
    func setupLocalVideo(on view: UIView) {
        let videoCanvas = AgoraRtcVideoCanvas()
        videoCanvas.uid = 0 // 0 = local user
        videoCanvas.view = view
        videoCanvas.renderMode = .hidden
        agoraEngine?.setupLocalVideo(videoCanvas)
    }
    
    /// Joins a specified channel to start or view a stream.
    /// - Parameters:
    ///   - channelName: The unique name for the streaming channel.
    ///   - isBroadcaster: A boolean indicating if the user is the one streaming or just a viewer.
    func joinChannel(channelName: String, isBroadcaster: Bool) {
        guard let engine = agoraEngine else {
            print("❌ Agora Engine not initialized.")
            return
        }
        
        // Set the user's role before joining.
        let role: AgoraClientRole = isBroadcaster ? .broadcaster : .audience
        engine.setClientRole(role)
        
        // Enable the video module.
        engine.enableVideo()
        
        // Join the channel. A token is not needed for testing mode
        engine.joinChannel(byToken: nil, channelId: channelName, info: nil, uid: 0) { (channel, uid, elapsed) in
            print("✅ Successfully joined channel: \(channel) with uid: \(uid)")
        }
    }
    
    /// Leaves the current channel.
    func leaveChannel() {
        agoraEngine?.leaveChannel(nil)
        print("Left channel.")
    }
    
    // MARK: - Private Methods
    
    private func initializeAgoraEngine() {
        // Create an AgoraRtcEngineKit instance with App ID and a delegate
        agoraEngine = AgoraRtcEngineKit.sharedEngine(withAppId: appId, delegate: self)
    }
}

// MARK: - AgoraRtcEngineDelegate
// Handles all the important events from the Agora engine
extension StreamingService: AgoraRtcEngineDelegate {
    
    /// Called when a remote user joins the channel
    func rtcEngine(_ engine: AgoraRtcEngineKit, didJoinedOfUid uid: UInt, elapsed: Int) {
        print("Remote user joined with uid: \(uid)")
        
        // Create a view for the remote user and add it to our dictionary
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
    
    /// Called when a remote user leaves the channel
    func rtcEngine(_ engine: AgoraRtcEngineKit, didOfflineOfUid uid: UInt, reason: AgoraUserOfflineReason) {
        print("Remote user left with uid: \(uid)")
        
        // Remove the user's view from dictionary
        DispatchQueue.main.async {
            self.remoteUserViews.removeValue(forKey: uid)
        }
    }
}
