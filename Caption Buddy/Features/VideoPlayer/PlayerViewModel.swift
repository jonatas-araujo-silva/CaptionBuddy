import Foundation
import AVKit
import Combine

// Manages the state and logic for the video player.

@MainActor
class PlayerViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var player: AVPlayer?
    @Published var currentCaptionIndex: Int? = nil
    @Published var animationName: String? = nil
    
    // MARK: - Properties
    let recording: VideoRecording
    @Published var captions: [TimedCaption] = []
    
    private var timeObserverToken: Any?
    
    // MARK: - Initialization & Deinitialization
    init(recording: VideoRecording) {
        self.recording = recording
    }
    
    deinit {
        print("PlayerViewModel deinitialized.")
    }
    
    /// Asynchronously prepares the AVPlayer, loads caption data, and starts playback.
    /// This should be called from a .task modifier in the PlayerView.
    func setupPlayer() async {
        guard let url = recording.videoURL else {
            print("❌ Error: Video URL is nil.")
            return
        }
        
        self.captions = recording.captions
        
        // Create the player and add the time observer.
        let player = AVPlayer(url: url)
        self.player = player
        addPeriodicTimeObserver(player: player)
        player.play()
    }
    
    /// Pauses the video playback.
    func pause() {
        player?.pause()
    }
    
    /// Called when view disappears to ensure all observers are removed immediately
    func cleanup() {
        removePeriodicTimeObserver()
    }
    
    // MARK: - Time Synchronization
    private func addPeriodicTimeObserver(player: AVPlayer) {
        let timeInterval = CMTime(seconds: 0.1, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        
        // Wrap the closure's body in a Task to runs it on the Main Actor
        timeObserverToken = player.addPeriodicTimeObserver(forInterval: timeInterval, queue: .main) { [weak self] time in
            Task { @MainActor in
                guard let self = self else { return }
                
                let currentTime = time.seconds
                
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
    }
    
    private func removePeriodicTimeObserver() {
        if let token = timeObserverToken {
            player?.removeTimeObserver(token)
            timeObserverToken = nil
            print("Time observer removed.")
        }
    }
}
