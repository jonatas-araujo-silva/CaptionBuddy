import SwiftUI
import UIKit
import AVKit

// Allows users to start a broadcast or join an existing one
struct StreamView: View {
    
    @StateObject private var viewModel = StreamViewModel()
    
    var body: some View {
        ZStack {
            if viewModel.isInChannel {
                // Main view for when a user is in live session
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
            Image(systemName: "dot.radiowaves.left.and.right").font(.system(size: 60)).foregroundColor(.red)
            Text("Live Stream").font(.largeTitle).fontWeight(.bold)
            Text("Start a broadcast or join an existing channel as a viewer.").font(.subheadline).foregroundColor(.secondary).multilineTextAlignment(.center).padding(.horizontal)
            VStack {
                TextField("Enter Channel Name", text: $viewModel.channelName)
                    .textFieldStyle(.roundedBorder).padding(.horizontal)
            }.padding(.top)
            Spacer()
            VStack(spacing: 12) {
                Button { viewModel.startBroadcast() } label: {
                    Label("Go Live as Broadcaster", systemImage: "video.fill").fontWeight(.semibold).frame(maxWidth: .infinity)
                }.buttonStyle(.borderedProminent).tint(.red).controlSize(.large)
                Button { viewModel.joinAsAudience() } label: {
                    Label("Join as Audience", systemImage: "person.2.fill").fontWeight(.semibold).frame(maxWidth: .infinity)
                }.buttonStyle(.bordered).controlSize(.large)
            }.padding()
        }
    }
}

// Main screen for when a user is in live session
struct LiveVideoView: View {
    
    @ObservedObject var viewModel: StreamViewModel
    
    var body: some View {
        // Separates the video area from the control panel
        VStack(spacing: 0) {
            // -- Video Player Area --
            ZStack(alignment: .top) {
                // Main Video Player
                if let player = viewModel.player {
                    VideoPlayer(player: player)
                } else {
                    Color.black
                    Text("Loading Stream...").foregroundColor(.white)
                }
                
                // Overlays for the video area (PiP, controls)
                HStack {
                    // Participant Count
                    HStack(spacing: 4) {
                        Image(systemName: "person.2.fill")
                        Text("\(viewModel.participantCount)")
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.white)
                    .padding(8)
                    .background(Color.black.opacity(0.5))
                    .clipShape(Capsule())
                    
                    Spacer()
                    
                    // Leave Button
                    Button { viewModel.leaveChannel() } label: {
                        Image(systemName: "xmark").foregroundColor(.white).padding(8)
                            .background(Color.red.opacity(0.8)).clipShape(Circle())
                    }
                }
                .padding()
            }
            .ignoresSafeArea(.container, edges: .top)

            // -- Captions and Chat Panel --
            CaptionsAndChatView(viewModel: viewModel)
        }
        .background(Color.black.ignoresSafeArea())
    }
}

// -- A dedicated view for the local user's video in the simulator --
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
        .frame(width: 100, height: 150)
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

// -- A dedicated view for the captions and chat UI --
struct CaptionsAndChatView: View {
    @ObservedObject var viewModel: StreamViewModel

    var body: some View {
        VStack(spacing: 0) {
            // -- Current Spoken Word --
            ZStack {
                if let index = viewModel.currentCaptionIndex, viewModel.captions.indices.contains(index) {
                    Text(viewModel.captions[index].text)
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
            .animation(.easeInOut, value: viewModel.currentCaptionIndex)
            
            // -- Animation and Chat Area --
            ZStack(alignment: .bottom) {
                // Chat Messages
                ChatView(viewModel: viewModel)
                
                // Lottie Animation
                if let animationName = viewModel.animationName {
                    LottieView(name: animationName, loopMode: .playOnce)
                        .frame(height: 80)
                        .transition(.scale.animation(.easeInOut(duration: 0.2)))
                        .padding(.bottom, 60)
                }
            }
        }
        .padding(.top)
        .background(.ultraThinMaterial)
    }
}

struct ChatView: View {
    @ObservedObject var viewModel: StreamViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            Divider()
            
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
            .frame(maxHeight: 120)
            
            HStack(spacing: 12) {
                TextField("Send a message...", text: $viewModel.currentMessageText)
                    .padding(10).padding(.leading, 8).background(Color.black.opacity(0.1)).clipShape(Capsule())
                Button { viewModel.sendMessage() } label: { Image(systemName: "arrow.up.circle.fill").font(.title) }
                .disabled(viewModel.currentMessageText.isEmpty)
            }
            .padding()
        }
    }
}

struct ChatRow: View {
    let message: ChatMessage
    var body: some View {
        HStack {
            if message.isFromLocalUser { Spacer(minLength: 50) }
            Text(message.text)
                .font(.footnote)
                .padding(.horizontal, 10).padding(.vertical, 6)
                .background(message.isFromLocalUser ? Color.blue : Color(uiColor: .systemGray4))
                .foregroundColor(message.isFromLocalUser ? .white : .primary)
                .clipShape(RoundedRectangle(cornerRadius: 14))
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
