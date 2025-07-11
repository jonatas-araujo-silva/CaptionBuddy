import SwiftUI
import AVKit

/* Responsible for displaying the video player, and features:
 * captions and Lottie animations.
 */
struct PlayerView: View {
    
    @StateObject var viewModel: PlayerViewModel
    
    var body: some View {
        ZStack(alignment: .bottom) {
            //  Video Player 
            if let player = viewModel.player {
                VideoPlayer(player: player)
                    .onAppear { player.play() }
                    .onDisappear { player.pause() }
                    .ignoresSafeArea()
            } else {
                VStack {
                    Image(systemName: "video.slash.fill")
                        .font(.largeTitle)
                    Text("Error: Could not load video.")
                        .padding(.top)
                }
            }
            
            // --- UI Overlay ---
            VStack(spacing: 0) {
                ZStack {
                    if let index = viewModel.currentCaptionIndex {
                        if viewModel.captions.indices.contains(index) {
                            Text(viewModel.captions[index].text)
                                .font(.title).bold()
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.black.opacity(0.6))
                                .clipShape(Capsule())
                                .transition(.opacity.combined(with: .scale))
                        }
                    }
                }
                .frame(height: 60)
                .animation(.easeInOut, value: viewModel.currentCaptionIndex)
                
                AnimationDisplayView(animationName: viewModel.animationName)
            }
            .padding(.bottom)
        }
        .navigationTitle(viewModel.recording.createdAt?.formatted(date: .abbreviated, time: .shortened) ?? "Video")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color.black)
        .onDisappear {
            viewModel.cleanup()
        }
    }
}

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

