import SwiftUI
import UIKit

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

//Main screen for when a user is in live session
struct LiveVideoView: View {
    
    @ObservedObject var viewModel: StreamViewModel
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.black.ignoresSafeArea()
            
            // - Video Grid Area -
            if viewModel.remoteUserViews.isEmpty {
                VStack {
                    Spacer()
                    ProgressView()
                    Text("Waiting for others to join...")
                        .foregroundColor(.secondary)
                        .padding(.top)
                    Spacer()
                }
            } else {
                ScrollView {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 4) {
                        ForEach(Array(viewModel.remoteUserViews.keys), id: \.self) { uid in
                            if let userView = viewModel.remoteUserViews[uid] {
                                AgoraVideoView(uiView: userView)
                                    .aspectRatio(3/4, contentMode: .fill)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                    }
                }
            }
            
            // - Chat and Controls UI -
            VStack {
                Spacer()
                ChatView(viewModel: viewModel)
            }
            .ignoresSafeArea(.container, edges: .bottom)
            
            // - Leave Button -
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

// Dedicated view for chat interface
struct ChatView: View {
    @ObservedObject var viewModel: StreamViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(viewModel.messages) { message in
                            ChatRow(message: message)
                        }
                    }
                    .padding()
                }
                .onChange(of: viewModel.messages.count) {
                    if let lastMessageID = viewModel.messages.last?.id {
                        withAnimation { proxy.scrollTo(lastMessageID, anchor: .bottom) }
                    }
                }
            }
            
            // Chat Input Field
            HStack(spacing: 12) {
                TextField("Send a message...", text: $viewModel.currentMessageText)
                    .padding(10)
                    .padding(.leading, 8)
                    .background(Color.black.opacity(0.25))
                    .clipShape(Capsule())
                
                Button {
                    viewModel.sendMessage()
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title)
                }
                .disabled(viewModel.currentMessageText.isEmpty)
            }
            .padding([.horizontal, .top])
            .padding(.bottom)
        }
        .frame(maxHeight: 300)
        .background(.ultraThinMaterial)
    }
}


// - Helper Views -

struct ChatRow: View {
    let message: ChatMessage
    
    var body: some View {
        HStack {
            if message.isFromLocalUser { Spacer(minLength: 50) }
            
            Text(message.text)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(message.isFromLocalUser ? .blue : .secondary.opacity(0.4))
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            
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
