import SwiftUI
import AVKit

/* this is responsible for displaying the video player and, eventually,
 * the synchronized captions and Lottie animations.
 */

struct PlayerView: View {
    
    @StateObject var viewModel: PlayerViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            if let player = viewModel.player {
                VideoPlayer(player: player)
                    .onAppear { player.play() }
                    .onDisappear { player.pause() }
            } else {
                Text("Error: Could not load video.")
            }
            
            // -- Synchronized Captions --
            VStack {
                ScrollViewReader { scrollViewProxy in
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 4) {
                            ForEach(Array(viewModel.captions.enumerated()), id: \.element.id) { (index, caption) in
                                Text(caption.text)
                                    .font(.title2)
                                    .fontWeight(.medium)
                                    .foregroundColor(index == viewModel.currentCaptionIndex ? .red : .primary)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(
                                        index == viewModel.currentCaptionIndex ? Color.red.opacity(0.2) : Color.clear
                                    )
                                    .cornerRadius(6)
                                    .id(index)
                            }
                        }
                        .padding()
                    }
                    .onChange(of: viewModel.currentCaptionIndex) { newIndex, _ in
                        if let index = newIndex {
                            withAnimation {
                                scrollViewProxy.scrollTo(index, anchor: .center)
                            }
                        }
                    }
                }
            }
            .frame(height: 100)
            .background(Color(.systemGroupedBackground))
            .shadow(radius: 5)
        }
        .navigationTitle(viewModel.recording.createdAt?.formatted(date: .abbreviated, time: .shortened) ?? "Video")
        .navigationBarTitleDisplayMode(.inline)
    }
}
