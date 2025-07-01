import SwiftUI
import AVFoundation

struct RecorderView: View {
    @StateObject private var viewModel = RecorderViewModel()

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            #if targetEnvironment(simulator)
            // -- SIMULATOR UI --
            // Shown only when running on the Simulator
            VStack {
                ErrorView(systemImageName: "display", errorMessage: "Simulator Mode")
                Text("Tap the button below to generate a sample recording.")
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            #else
            // -- REAL DEVICE UI --
            // Shown only when running on a physical device
            if viewModel.isSessionReady {
                if let previewLayer = viewModel.previewLayer {
                    VideoPreviewView(layer: previewLayer)
                        .ignoresSafeArea()
                } else {
                    ErrorView(systemImageName: "video.slash.fill", errorMessage: "Could not create camera preview.")
                }
            } else {
                ErrorView(systemImageName: "exclamationmark.triangle.fill", errorMessage: "Camera Not Available\n\nPlease run on a physical device.")
            }
            #endif

            // -- UI Overlay (for Simulator and Device) --
            VStack {
                Spacer()
                Button(action: {
                    viewModel.toggleRecording()
                }) {
                    ZStack {
                        Circle()
                            .strokeBorder(Color.white, lineWidth: 3)
                            .frame(width: 75, height: 75)
                        
                        RoundedRectangle(cornerRadius: viewModel.isRecording ? 8 : 32.5)
                            .fill(Color.red)
                            .frame(width: viewModel.isRecording ? 45 : 65, height: viewModel.isRecording ? 45 : 65)
                    }
                }
                .buttonStyle(PlainButtonStyle())
                .animation(.spring(), value: viewModel.isRecording)
                .padding(.bottom, 30)
            }
        }
    }
}

//A helper view for the real device's camera layer
struct VideoPreviewView: UIViewRepresentable {
    let layer: AVCaptureVideoPreviewLayer

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        
        layer.frame = view.bounds
        layer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(layer)
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        layer.frame = uiView.bounds
    }
}

//A reusable view for displaying error messages / simulator status
struct ErrorView: View {
    let systemImageName: String
    let errorMessage: String
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: systemImageName)
                .font(.system(size: 60))
                .foregroundColor(.white.opacity(0.7))
            
            Text(errorMessage)
                .font(.headline)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding()
        }
    }
}


#Preview {
    RecorderView()
}
