import Foundation
import Combine
import SwiftUI

/*
 Manages the state and user interactions for the live streaming view.
 * It coordinates between the UI and the underlying StreamingService.
 */
class StreamViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    // The name of the channel the user will join.
    @Published var channelName: String = "caption-buddy-live"
    
    // Indicates if the user is currently in a live channel.
    @Published var isInChannel: Bool = false
    
    // A dictionary of remote user views, passed up from the service.
    @Published var remoteUserViews: [UInt: UIView] = [:]
    
    // MARK: - Private Properties
    
    // An instance of our streaming service.
    private let streamingService = StreamingService()
    
    // A set to hold our Combine subscriptions.
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init() {
        // Subscribe to the remoteUserViews publisher from the service.
        // This ensures our UI updates whenever a remote user joins or leaves.
        streamingService.$remoteUserViews
            .receive(on: DispatchQueue.main)
            .assign(to: \.remoteUserViews, on: self)
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    
    /// Sets up the local user's video feed.
    func setupLocalVideo(on view: UIView) {
        streamingService.setupLocalVideo(on: view)
    }
    
    /// Joins the channel as a broadcaster.
    func startBroadcast() {
        // You would typically get the App ID from a secure source.
        // For now, ensure it's set in StreamingService.
        streamingService.joinChannel(channelName: channelName, isBroadcaster: true)
        isInChannel = true
    }
    
    /// Joins the channel as an audience member.
    func joinAsAudience() {
        streamingService.joinChannel(channelName: channelName, isBroadcaster: false)
        isInChannel = true
    }
    
    /// Leaves the current channel.
    func leaveChannel() {
        streamingService.leaveChannel()
        isInChannel = false
    }
}
