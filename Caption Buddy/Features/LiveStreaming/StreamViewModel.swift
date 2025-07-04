import Foundation
import Combine
import SwiftUI

/*
 Manages the state and user interactions for the live streaming view.
 * It coordinates between the UI and the underlying StreamingService.
 */
class StreamViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var channelName: String = "caption-buddy-live"
    @Published var isInChannel: Bool = false
    @Published var remoteUserViews: [UInt: UIView] = [:]
    
    @Published var messages: [ChatMessage] = []
    @Published var currentMessageText: String = ""
    
    // MARK: - Private Properties
    private let streamingService = StreamingService()
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init() {
        // Subscribe to remote user views
        streamingService.$remoteUserViews
            .receive(on: DispatchQueue.main)
            .assign(to: \.remoteUserViews, on: self)
            .store(in: &cancellables)
            
        // Subscribe to incoming chat messages
        // When the service publishes a new message, it'll be add to array
        streamingService.chatMessagePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message in
                self?.messages.append(message)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    
    func setupLocalVideo(on view: UIView) {
        streamingService.setupLocalVideo(on: view)
    }
    
    func startBroadcast() {
        streamingService.joinChannel(channelName: channelName, isBroadcaster: true)
        isInChannel = true
    }
    
    func joinAsAudience() {
        streamingService.joinChannel(channelName: channelName, isBroadcaster: false)
        isInChannel = true
    }
    
    func leaveChannel() {
        streamingService.leaveChannel()
        isInChannel = false
        messages.removeAll()
    }
    
    func sendMessage() {
        let messageToSend = currentMessageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !messageToSend.isEmpty else { return }
        
        streamingService.sendMessage(messageToSend)
        currentMessageText = ""
    }
}
