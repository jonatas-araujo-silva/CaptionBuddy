import Foundation
import AVKit
import Combine

/* this manages the state and logic for the video player
 * It holds the AVPlayer instance and prepares it with the video URL
 * from the selected VideoRecording.
 */

class PlayerViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var player: AVPlayer?
    
    // Holds the index of the currently spoken word.
    @Published var currentCaptionIndex: Int? = nil
    
    // MARK: - Properties
    let recording: VideoRecording
    let captions: [TimedCaption]
    
    // Related to lifecycle of the time observer
    private var timeObserverToken: Any?
    
    // MARK: - Initialization & Deinitialization
    init(recording: VideoRecording) {
        self.recording = recording
        
        self.captions = recording.captions
        
        guard let url = recording.videoURL else {
            print("❌ Error: Video URL is nil.")
            return
        }
        
        self.player = AVPlayer(url: url)
        addPeriodicTimeObserver()
    }
    
    deinit {
        removePeriodicTimeObserver()
        print("PlayerViewModel deinitialized and time observer removed.")
    }
    
    // MARK: - Time Synchronization
    private func addPeriodicTimeObserver() {
        // Define the time interval for updates (e.g: every 100 milliseconds).
        let timeInterval = CMTime(seconds: 0.1, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        
        // Add an observer and returns a token that's used to remove the observer later
        timeObserverToken = player?.addPeriodicTimeObserver(forInterval: timeInterval, queue: .main) { [weak self] time in
            guard let self = self else { return }
            
            let currentTime = time.seconds
            
            // Find the index of the caption that corresponds to the current player time.
            if let newIndex = self.captions.firstIndex(where: { caption in
                let startTime = caption.startTime
                let endTime = startTime + caption.duration
                return currentTime >= startTime && currentTime < endTime
            }) {
                // If it's found a new index, gonna update the published property
                if self.currentCaptionIndex != newIndex {
                    self.currentCaptionIndex = newIndex
                }
            } else {
                self.currentCaptionIndex = nil
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
