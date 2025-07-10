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
    
    // MARK: - Private Properties
    private let streamingService = StreamingService()
    private var cancellables = Set<AnyCancellable>()
    private var timeObserverToken: Any?
    
    // Properties to manage the video sequence
    private var firstVideoCaptions: [TimedCaption] = []
    private var secondVideoCaptions: [TimedCaption] = []
    private var firstPlayerItem: AVPlayerItem?
    
    init() {
        streamingService.$remoteUserViews
            .receive(on: DispatchQueue.main)
            .assign(to: \.remoteUserViews, on: self)
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
        //load all assets
        guard let videoURL1 = Bundle.main.url(forResource: "FirstVideo_Portfolio", withExtension: "mp4"),
              let captionsURL1 = Bundle.main.url(forResource: "Caption_FirstVideo_Portfolio", withExtension: "json"),
              let videoURL2 = Bundle.main.url(forResource: "SecondVideo_Portfolio", withExtension: "mp4"),
              let captionsURL2 = Bundle.main.url(forResource: "Caption_SecondVideo_Portfolio", withExtension: "json") else {
            print("❌ SIMULATOR ERROR: Could not find all portfolio assets.")
            return
        }
        
        //decode caption files
        do {
            let data1 = try Data(contentsOf: captionsURL1)
            self.firstVideoCaptions = try JSONDecoder().decode([TimedCaption].self, from: data1)
            
            let data2 = try Data(contentsOf: captionsURL2)
            self.secondVideoCaptions = try JSONDecoder().decode([TimedCaption].self, from: data2)
        } catch {
            print("❌ SIMULATOR ERROR: Failed to decode captions: \(error)")
            return
        }
        
        // create player items and the queue
        self.firstPlayerItem = AVPlayerItem(url: videoURL1)
        let secondPlayerItem = AVPlayerItem(url: videoURL2)
        self.player = AVQueuePlayer(items: [firstPlayerItem!, secondPlayerItem])
        
        // set initial state
        self.captions = firstVideoCaptions
        addPeriodicTimeObserver()
        
        // observe when the first video finishes playing
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(firstVideoDidFinish),
                                               name: .AVPlayerItemDidPlayToEndTime,
                                               object: firstPlayerItem)
        
        self.player?.play()
    }
    
    // Called when the first video ends.
    @objc private func firstVideoDidFinish() {
        print("First video finished. Switching to second video captions.")
        //switch the active captions to the second video's data.
        self.captions = secondVideoCaptions
        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: firstPlayerItem)
    }
    
    private func addPeriodicTimeObserver() {
        let timeInterval = CMTime(seconds: 0.1, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserverToken = player?.addPeriodicTimeObserver(forInterval: timeInterval, queue: .main) { [weak self] time in
            guard let self = self, let currentItem = self.player?.currentItem else { return }
            
            // get the time relative to the currently playing item
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
