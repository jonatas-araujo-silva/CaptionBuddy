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
                    // -- Live View --
                    LiveVideoView(viewModel: viewModel)
                } else {
                    // -- Pre-Join View --
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
            .navigationTitle("Live Stream")
        }
    }
}

/* Displays the local and remote video feeds once connected to a channel.
 */
struct LiveVideoView: View {
    
    @ObservedObject var viewModel: StreamViewModel
    
    var body: some View {
        VStack {
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
            
            Spacer()
            
            // Display the local user's video feed
            AgoraVideoView(setup: viewModel.setupLocalVideo)
                .frame(width: 150, height: 200)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.gray, lineWidth: 2)
                )
                .padding()
            
            Button("Leave Channel") {
                viewModel.leaveChannel()
            }
            .padding()
            .background(Color.gray)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
    }
}

// Wraps the UIViews provided by the Agora SDK,
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

// MARK: - Preview
#Preview {
    StreamView()
}
