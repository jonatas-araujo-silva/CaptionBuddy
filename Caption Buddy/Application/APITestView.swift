import SwiftUI
import AVFoundation
import Speech
import Lottie

// MARK: - Main Content View
struct ContentView: View {
    
    init() {
        // Sets the color for icon and text of unselected tabs
        // Ensures they are visible against dark backgrounds
        UITabBar.appearance().unselectedItemTintColor = UIColor.lightGray
    }

    var body: some View {
        TabView {
            // Video Recorder
            RecorderView()
                .tabItem {
                    Image(systemName: "video.fill")
                    Text("Record")
                }

            // Video Library
            VideoLibraryView()
                .tabItem {
                    Image(systemName: "photo.on.rectangle.angled")
                    Text("Library")
                }
            
            // Live Streaming
            StreamView()
                .tabItem {
                    Image(systemName: "antenna.radiowaves.left.and.right")
                    Text("Live")
                }
        }
        .accentColor(.red)
    }
}

// MARK: - Preview
#Preview {
    ContentView()
}
