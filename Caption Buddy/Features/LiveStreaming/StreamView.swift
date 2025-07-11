import SwiftUI
import UIKit
import AVKit

// Allow users to start a broadcast or join an existing one
struct StreamView: View {
    
    @StateObject private var viewModel = StreamViewModel()
    
    var body: some View {
        ZStack {
            if viewModel.isInChannel {
                // Main view for user in live session
                LiveVideoView(viewModel: viewModel)
                    .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
            } else {
                // View shown before joining a channel
                PreJoinView(viewModel: viewModel)
                    .transition(.asymmetric(insertion: .move(edge: .leading), removal: .move(edge: .trailing)))
            }
        }
        .animation(.default, value: viewModel.isInChannel)
    }
}

// Helper view for screen shown before joining a stream
struct PreJoinView: View {
    @ObservedObject var viewModel: StreamViewModel
    
    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            
            Image(systemName: "dot.radiowaves.left.and.right")
                .font(.system(size: 60))
                .foregroundColor(.red)
            
            Text("Live Stream")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Start a broadcast or join an existing channel as a viewer.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            VStack {
                TextField("Enter Channel Name", text: $viewModel.channelName)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)
            }
            .padding(.top)
            
            Spacer()
            
            VStack(spacing: 12) {
                Button {
                    viewModel.startBroadcast()
                } label: {
                    Label("Go Live as Broadcaster", systemImage: "video.fill")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .controlSize(.large)
                
                Button {
                    viewModel.joinAsAudience()
                } label: {
                    Label("Join as Audience", systemImage: "person.2.fill")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            }
            .padding()
        }
    }
}

// Main screen for when a user is in live session
struct LiveVideoView: View {
    
    @ObservedObject var viewModel: StreamViewModel
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Main Video Player
            if let player = viewModel.player {
                VideoPlayer(player: player)
                    .ignoresSafeArea()
            } else {
                Color.black.ignoresSafeArea()
                Text("Loading Stream...").foregroundColor(.white)
            }
            
            //  UI Overlay
            VStack {
                // Picture-in-Picture for local user
                HStack {
                    Spacer()
                    LocalUserVideoView()
                        .padding()
                }
                
                Spacer()
                
                // Holds all overlay contents
                VStack(spacing: 0) {
                    
                    //  Display the current caption
                    ZStack {
                        // Only shown the Text view if there's a current word
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


                    // - Chat and Animation  -
                    ZStack(alignment: .bottom) {
                        //Chat Messages
                        ScrollViewReader { proxy in
                            ScrollView {
                                VStack(alignment: .leading, spacing: 10) {
                                    ForEach(viewModel.messages) { message in
                                        ChatRow(message: message)
                                    }
                                }.padding()
                            }
                            .onChange(of: viewModel.messages.count) {
                                if let lastMessageID = viewModel.messages.last?.id {
                                    withAnimation { proxy.scrollTo(lastMessageID, anchor: .bottom) }
                                }
                            }
                        }
                        .frame(maxHeight: 100)

                        if let animationName = viewModel.animationName {
                            LottieView(name: animationName, loopMode: .playOnce)
                                .frame(height: 80)
                                .transition(.scale.animation(.spring()))
                                .padding(.bottom, 8)
                        }
                    }

                    // Chat Input
                    HStack(spacing: 12) {
                        TextField("Send a message...", text: $viewModel.currentMessageText)
                            .padding(10).padding(.leading, 8).background(Color.black.opacity(0.25)).clipShape(Capsule())
                        Button { viewModel.sendMessage() } label: { Image(systemName: "arrow.up.circle.fill").font(.title) }
                            .disabled(viewModel.currentMessageText.isEmpty)
                    }
                    .padding([.horizontal, .top])
                    .padding(.bottom)
                }
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .padding(.horizontal)
                .padding(.bottom)
            }
            // Leave Button
            Button {
                viewModel.leaveChannel()
            } label: {
                Image(systemName: "xmark")
                    .foregroundColor(.white)
                    .padding(8)
                    .background(Color.black.opacity(0.5))
                    .clipShape(Circle())
            }
            .padding()
        }
    }
}


// View for the local user's video in the simulator
struct LocalUserVideoView: View {
    @State private var player: AVPlayer?

    var body: some View {
        VStack {
            if let player = player {
                VideoPlayer(player: player)
                    .disabled(true)
            } else {
                Color.black.opacity(0.8)
            }
        }
        .frame(width: 120, height: 180)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white, lineWidth: 2))
        .onAppear {
            if let url = Bundle.main.url(forResource: "SecondVideo_Portfolio", withExtension: "mp4") {
                let player = AVPlayer(url: url)
                self.player = player
                player.isMuted = true
                player.play()
                
                NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: player.currentItem, queue: .main) { _ in
                    player.seek(to: .zero)
                    player.play()
                }
            }
        }
    }
}


//Helper Views
struct ChatRow: View {
    let message: ChatMessage
    var body: some View {
        HStack {
            if message.isFromLocalUser { Spacer(minLength: 50) }
            Text(message.text)
                .padding(.horizontal, 12).padding(.vertical, 8)
                .background(message.isFromLocalUser ? .blue : .secondary.opacity(0.4))
                .foregroundColor(.white).clipShape(RoundedRectangle(cornerRadius: 16))
            if !message.isFromLocalUser { Spacer(minLength: 50) }
        }
    }
}

struct AgoraVideoView: UIViewRepresentable {
    var uiView: UIView?
    var setup: ((UIView) -> Void)?

    func makeUIView(context: Context) -> UIView {
        return uiView ?? UIView()
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        setup?(uiView)
    }
}

#Preview {
    StreamView()
}
