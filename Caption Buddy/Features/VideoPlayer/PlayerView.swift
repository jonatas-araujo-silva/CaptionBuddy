import SwiftUI
import AVKit

// Responsible for displays video player, captions and Lottie animations.

struct PlayerView: View {
    
    @StateObject var viewModel: PlayerViewModel
    
    var body: some View {
        ZStack {
            // Layer 1: Video Player
            if let player = viewModel.player {
                VideoPlayer(player: player)
                    .ignoresSafeArea()
            } else {
                ProgressView()
            }
            
            // Layer 2: All UI Overlays
            PlayerOverlaysView(viewModel: viewModel)
        }
        .navigationTitle(viewModel.recording.createdAt?.formatted(date: .abbreviated, time: .shortened) ?? "Video")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color.black)
        .onDisappear {
            viewModel.pause()
            viewModel.cleanup()
        }
        .task {
            await viewModel.setupPlayer()
        }
    }
}

// View that contains all UI elements layered on top of the main video player, such as captions and animations.
struct PlayerOverlaysView: View {
    @ObservedObject var viewModel: PlayerViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Holds the caption and animation panel
            VStack(spacing: 0) {
                CurrentCaptionView(
                    captions: viewModel.captions,
                    currentIndex: viewModel.currentCaptionIndex
                )
                AnimationDisplayView(animationName: viewModel.animationName)
            }
            .padding(.bottom)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .padding(.horizontal)
            .padding(.bottom)
        }
    }
}

// Reusable component whose only job is display the currently spoken word with a smooth animation.
struct CurrentCaptionView: View {
    let captions: [TimedCaption]
    let currentIndex: Int?
    
    var body: some View {
        ZStack {
            if let index = currentIndex, captions.indices.contains(index) {
                Text(captions[index].text)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.white.opacity(0.5))
                    .clipShape(Capsule())
                    .transition(.opacity.combined(with: .scale))
            }
        }
        .frame(height: 60)
        .animation(.easeInOut, value: currentIndex)
    }
}


// Helper view to manage the animation's presentation
struct AnimationDisplayView: View {
    let animationName: String?

    var body: some View {
        ZStack {
            if let name = animationName {
                LottieView(name: name, loopMode: .playOnce)
                    .transition(.scale.animation(.spring()))
            } else {
                Color.clear
            }
        }
        .frame(height: 120)
        .padding(.bottom, 8)
    }
}

// MARK: - Preview
#Preview {
    let moc = PersistenceController.preview.container.viewContext
    let previewRecording = VideoRecording(context: moc)
    previewRecording.createdAt = Date()
    previewRecording.videoURL = URL(string: "example.com")
    
    return NavigationView {
        PlayerView(viewModel: PlayerViewModel(recording: previewRecording))
    }
}
