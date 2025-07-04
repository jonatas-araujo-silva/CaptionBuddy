import SwiftUI
import UIKit

/*
Main UI for the live streaming feature. It allows users to either
 * start a broadcast or join an existing one as a viewer.
 */
struct StreamView: View {
    
    @StateObject private var viewModel = StreamViewModel()
    
    var body: some View {
        NavigationView {
            VStack {
                if viewModel.isInChannel {
                    // Shown when the user is in a live channel
                    LiveVideoView(viewModel: viewModel)
                } else {
                    // Shown before joining a channel
                    PreJoinView(viewModel: viewModel)
                }
            }
            .navigationTitle("Live Stream")
            .navigationBarHidden(viewModel.isInChannel)         }
    }
}

// Helper view for the screen shown before joining a stream
struct PreJoinView: View {
    @ObservedObject var viewModel: StreamViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Ready to Go Live?")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            TextField("Enter Channel Name", text: $viewModel.channelName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            Button("Go Live as Broadcaster") {
                viewModel.startBroadcast()
            }
            .padding()
            .background(Color.red)
            .foregroundColor(.white)
            .cornerRadius(10)
            
            Button("Join as Audience") {
                viewModel.joinAsAudience()
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .padding()
    }
}

/* Main screen for when a user is in a live session
 * Displays video feeds and chat interface
 */
struct LiveVideoView: View {
    
    @ObservedObject var viewModel: StreamViewModel
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Video grid
                if viewModel.remoteUserViews.isEmpty {
                    Spacer()
                    Text("Waiting for others to join...")
                        .foregroundColor(.white)
                    Spacer()
                } else {
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())]) {
                            ForEach(Array(viewModel.remoteUserViews.keys), id: \.self) { uid in
                                if let userView = viewModel.remoteUserViews[uid] {
                                    AgoraVideoView(uiView: userView)
                                        .frame(height: 200)
                                        .cornerRadius(10)
                                }
                            }
                        }
                        .padding()
                    }
                }
                
                // -- Chat Messages Display --
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(viewModel.messages) { message in
                                ChatRow(message: message)
                            }
                        }
                        .padding()
                    }
                    .onChange(of: viewModel.messages.count) { _, _ in
                        // Auto-scroll to newest message
                        if let lastMessage = viewModel.messages.last {
                            withAnimation {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                }
                .frame(maxHeight: 200)
                .background(Color.black.opacity(0.3))
                
                // -- Chat Input Field --
                HStack {
                    TextField("Enter message...", text: $viewModel.currentMessageText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Button("Send") {
                        viewModel.sendMessage()
                    }
                    .buttonStyle(BorderlessButtonStyle())
                    .padding(.horizontal)
                }
                .padding()
            }
            
            // -- UI Overlay for Controls --
            VStack {
                HStack {
                    Spacer()
                    Button("Leave") {
                        viewModel.leaveChannel()
                    }
                    .padding(8)
                    .background(Color.red.opacity(0.8))
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .padding()
                Spacer()
            }
        }
    }
}

// --- Dedicated view for a single chat message row ---
struct ChatRow: View {
    let message: ChatMessage
    
    var body: some View {
        HStack {
            if message.isFromLocalUser { Spacer() }
            
            Text(message.text)
                .padding(10)
                .background(message.isFromLocalUser ? Color.blue : Color.gray.opacity(0.6))
                .foregroundColor(.white)
                .cornerRadius(12)
            
            if !message.isFromLocalUser { Spacer() }
        }
    }
}


// -- Generic UIViewRepresentable to wrap the UIViews from Agora --
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
