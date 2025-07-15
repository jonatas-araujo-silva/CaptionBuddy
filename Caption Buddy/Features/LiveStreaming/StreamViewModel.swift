import Foundation
import Combine
import SwiftUI
import AVKit

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
    
    @Published var player: AVQueuePlayer?
    
    @Published var captions: [TimedCaption] = []
    @Published var currentCaptionIndex: Int? = nil
    @Published var animationName: String? = nil
    
    @Published var participantCount: Int = 0
    
    // MARK: - Private Properties
    private let streamingService = StreamingService()
    private var cancellables = Set<AnyCancellable>()
    private var timeObserverToken: Any?
    private var firstPlayerItem: AVPlayerItem?
    private var firstVideoCaptions: [TimedCaption] = []
    private var secondVideoCaptions: [TimedCaption] = []
    
    init() {
        streamingService.$remoteUserViews
            .receive(on: DispatchQueue.main)
            .sink { [weak self] remoteViews in
                self?.remoteUserViews = remoteViews
                self?.participantCount = remoteViews.count + 1
            }
            .store(in: &cancellables)
            
        streamingService.chatMessagePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message in
                self?.messages.append(message)
            }
            .store(in: &cancellables)
    }
    
    deinit {
        removePeriodicTimeObserver()
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Public Methods
    
    func startBroadcast() {
        setupConversationPlayer()
        streamingService.joinChannel(channelName: channelName, isBroadcaster: true)
        isInChannel = true
    }
    
    func joinAsAudience() {
        setupConversationPlayer()
        streamingService.joinChannel(channelName: channelName, isBroadcaster: false)
        isInChannel = true
    }
    
    func leaveChannel() {
        streamingService.leaveChannel()
        isInChannel = false
        messages.removeAll()
        removePeriodicTimeObserver()
        player?.removeAllItems()
        player = nil
        captions.removeAll()
        participantCount = 0 // Reset participant count
        NotificationCenter.default.removeObserver(self)
    }
    
    func sendMessage() {
        let messageToSend = currentMessageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !messageToSend.isEmpty else { return }
        streamingService.sendMessage(messageToSend)
        currentMessageText = ""
    }
    
    // MARK: - Private Caption & Timing Logic
    
    private func setupConversationPlayer() {
        guard let videoURL1 = Bundle.main.url(forResource: "FirstVideo_Portfolio", withExtension: "mp4"),
              let captionsURL1 = Bundle.main.url(forResource: "Caption_FirstVideo_Portfolio", withExtension: "json"),
              let videoURL2 = Bundle.main.url(forResource: "SecondVideo_Portfolio", withExtension: "mp4"),
              let captionsURL2 = Bundle.main.url(forResource: "Caption_SecondVideo_Portfolio", withExtension: "json") else {
            print("❌ SIMULATOR ERROR: Could not find all portfolio assets.")
            return
        }
        
        do {
            let data1 = try Data(contentsOf: captionsURL1)
            self.firstVideoCaptions = try JSONDecoder().decode([TimedCaption].self, from: data1)
            
            let data2 = try Data(contentsOf: captionsURL2)
            self.secondVideoCaptions = try JSONDecoder().decode([TimedCaption].self, from: data2)
        } catch {
            print("❌ SIMULATOR ERROR: Failed to decode captions: \(error)")
            return
        }
        
        self.firstPlayerItem = AVPlayerItem(url: videoURL1)
        let secondPlayerItem = AVPlayerItem(url: videoURL2)
        self.player = AVQueuePlayer(items: [firstPlayerItem!, secondPlayerItem])
        
        self.captions = firstVideoCaptions
        addPeriodicTimeObserver()
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(firstVideoDidFinish),
                                               name: .AVPlayerItemDidPlayToEndTime,
                                               object: firstPlayerItem)
        
        self.player?.play()
    }
    
    @objc private func firstVideoDidFinish() {
        print("First video finished. Switching to second video captions.")
        self.captions = secondVideoCaptions
        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: firstPlayerItem)
    }
    
    private func addPeriodicTimeObserver() {
        let timeInterval = CMTime(seconds: 0.1, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserverToken = player?.addPeriodicTimeObserver(forInterval: timeInterval, queue: .main) { [weak self] time in
            guard let self = self, let currentItem = self.player?.currentItem else { return }
            
            let currentTime = currentItem.currentTime().seconds
            
            if let newIndex = self.captions.firstIndex(where: { caption in
                let startTime = caption.startTime
                let endTime = startTime + caption.duration
                return currentTime >= startTime && currentTime < endTime
            }) {
                if self.currentCaptionIndex != newIndex {
                    self.currentCaptionIndex = newIndex
                    let currentWord = self.captions[newIndex].text
                    self.animationName = AnimationService.shared.animationName(for: currentWord)
                }
            } else {
                self.currentCaptionIndex = nil
                self.animationName = nil
            }
        }
    }
    
    private func removePeriodicTimeObserver() {
        if let token = timeObserverToken {
            player?.removeTimeObserver(token)
            timeObserverToken = nil
        }
    }
}
