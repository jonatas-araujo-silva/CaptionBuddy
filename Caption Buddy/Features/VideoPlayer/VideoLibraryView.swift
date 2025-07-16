import SwiftUI
import AVFoundation

// Displays a list of all video recordings saved in Core Data

struct VideoLibraryView: View {
    
    @StateObject private var viewModel = VideoLibraryViewModel()
    
    var body: some View {
        NavigationView {
            VStack {
                if viewModel.recordings.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "film.stack")
                            .font(.system(size: 80))
                            .foregroundColor(.gray)
                        Text("No Recordings Yet")
                            .font(.title)
                            .fontWeight(.bold)
                        Text("Tap 'Generate Demos' to load sample videos.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                } else {
                    // Saved video recordings
                    List {
                        ForEach(viewModel.recordings) { recording in
                            NavigationLink(destination: PlayerView(viewModel: PlayerViewModel(recording: recording))) {
                                VideoRow(recording: recording)
                            }
                        }
                        .onDelete { indexSet in
                            Task {
                                await viewModel.delete(at: indexSet)
                            }
                        }
                    }
                    .listStyle(InsetGroupedListStyle())
                }
            }
            .navigationTitle("Library")
            .toolbar {
                #if DEBUG
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Generate Demos") {
                        Task {
                            await DemoDataGenerator.createPortfolioEntries()
                            viewModel.fetchRecordings()
                        }
                    }
                }
                #endif
            }
        }
        .onAppear {
            viewModel.fetchRecordings()
        }
    }
}

//Helper view for a single row in library list, now using a thumbnail
struct VideoRow: View {
    let recording: VideoRecording
    
    private var transcriptPreview: String {
        let fullTranscript = recording.captions.map { $0.text }.joined(separator: " ")
        return fullTranscript.isEmpty ? "No transcript available." : fullTranscript
    }
    
    var body: some View {
        HStack(spacing: 16) {
            VideoThumbnailView(videoURL: recording.videoURL)
                .frame(width: 80, height: 60)
                .background(Color.secondary.opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 4) {
                Text(recording.createdAt ?? Date(), style: .date)
                    .fontWeight(.semibold)
                    .font(.headline)
                
                Text(transcriptPreview)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 8)
    }
}

//Dedicated view that async generate/displays a thumbnail
struct VideoThumbnailView: View {
    let videoURL: URL?
    
    @State private var thumbnailImage: UIImage? = nil
    
    var body: some View {
        ZStack {
            if let image = thumbnailImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                ProgressView()
            }
        }
        .onAppear(perform: generateThumbnail)
    }
    
    private func generateThumbnail() {
        guard let url = videoURL else { return }
        
        DispatchQueue.global(qos: .userInitiated).async {
            let asset = AVAsset(url: url)
            let imageGenerator = AVAssetImageGenerator(asset: asset)
            imageGenerator.appliesPreferredTrackTransform = true
            
            // Generate an image at the 1 second mark of the video
            let time = CMTime(seconds: 1, preferredTimescale: 600)
            
            do {
                let cgImage = try imageGenerator.copyCGImage(at: time, actualTime: nil)
                let uiImage = UIImage(cgImage: cgImage)
                
                DispatchQueue.main.async {
                    self.thumbnailImage = uiImage
                }
            } catch {
                print("❌ Error generating thumbnail: \(error.localizedDescription)")
            }
        }
    }
}


#Preview {
    VideoLibraryView()
}
