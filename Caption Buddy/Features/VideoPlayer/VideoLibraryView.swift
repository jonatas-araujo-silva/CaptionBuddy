import SwiftUI
import CoreData
import AVFoundation

// Displays a list of all video recordings saved in Core Data
struct VideoLibraryView: View {
    
    // Get the managed object context from the environment
    @Environment(\.managedObjectContext) private var viewContext

    // Automatically fetch and update `recordings` array whenever data in CoreData changes
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \VideoRecording.createdAt, ascending: false)],
        animation: .default)
    
    private var recordings: FetchedResults<VideoRecording>
    
    var body: some View {
        NavigationView {
            // Chooses which view to display based on the recordings state
            Group {
                if recordings.isEmpty {
                    EmptyLibraryView()
                } else {
                    RecordingsListView(recordings: recordings, onDelete: deleteItems)
                }
            }
            .navigationTitle("Library")
            .toolbar {
                #if DEBUG
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Generate Demos") {
                        Task {
                            await DemoDataGenerator.createPortfolioEntries()
                        }
                    }
                }
                #endif
            }
        }
    }
    
    // Works directly with the view context
    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            offsets.map { recordings[$0] }.forEach(viewContext.delete)

            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                print("❌ Error saving context after deletion: \(nsError), \(nsError.userInfo)")
            }
        }
    }
}

// View for empty state
private struct EmptyLibraryView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "film.stack")
                .font(.system(size: 80))
                .foregroundColor(.gray)
            Text("No Recordings Yet")
                .font(.title)
                .fontWeight(.bold)
                .accessibilityIdentifier("emptyLibraryMessage")
            Text("Tap 'Generate Demos' to load sample videos.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }
}

// View for the list of recordings
private struct RecordingsListView: View {
    let recordings: FetchedResults<VideoRecording>
    let onDelete: (IndexSet) -> Void
    
    var body: some View {
        List {
            ForEach(recordings) { recording in
                NavigationLink(destination: PlayerView(viewModel: PlayerViewModel(recording: recording))) {
                    VideoRow(recording: recording)
                }
            }
            .onDelete(perform: onDelete)
        }
        .listStyle(InsetGroupedListStyle())
    }
}


//View for a single row in the library list
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

// View that asynchronously generates and displays a thumbnail for a given video URL.
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
        
        Task(priority: .userInitiated) {
            let asset = AVURLAsset(url: url)
            let imageGenerator = AVAssetImageGenerator(asset: asset)
            imageGenerator.appliesPreferredTrackTransform = true
            
            let time = CMTime(seconds: 1, preferredTimescale: 600)
            
            do {
                let cgImage = try await imageGenerator.image(at: time).image
                let uiImage = UIImage(cgImage: cgImage)
                
                await MainActor.run {
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
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
