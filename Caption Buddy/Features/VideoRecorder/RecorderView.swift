import SwiftUI
import AVFoundation

struct RecorderView: View {
    @StateObject private var viewModel = RecorderViewModel()

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if let previewLayer = viewModel.previewLayer, viewModel.isSessionReady {
                VideoPreviewView(layer: previewLayer)
                    .ignoresSafeArea()
            }

            // -- UI Overlay -
            VStack {
                
                Spacer()
                
                // -- RECORD BUTTON --
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

struct VideoPreviewView: UIViewRepresentable {
    let layer: AVCaptureVideoPreviewLayer

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        layer.frame = view.bounds
        view.layer.addSublayer(layer)
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        layer.frame = uiView.bounds
    }
}

// MARK: - Preview
#Preview {
    RecorderView()
}
