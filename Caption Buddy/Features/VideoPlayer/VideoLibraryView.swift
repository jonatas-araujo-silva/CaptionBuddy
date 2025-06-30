import SwiftUI

/* Displays a list of all video recordings that have been saved
 * to Core Data. It uses the VideoLibraryViewModel to fetch the data.
 */

struct VideoLibraryView: View {
    
    @StateObject private var viewModel = VideoLibraryViewModel()
    
    var body: some View {
        NavigationView {
            if viewModel.recordings.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "film.stack")
                        .font(.system(size: 80))
                        .foregroundColor(.gray)
                    Text("No Recordings Yet")
                        .font(.title)
                        .fontWeight(.bold)
                    Text("Go to the Record tab to create your first video.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .navigationTitle("Library")
            } else {
                List {
                    ForEach(viewModel.recordings) { recording in
                        NavigationLink(destination: PlayerView(viewModel: PlayerViewModel(recording: recording))) {
                            VideoRow(recording: recording)
                        }
                    }
                }
                .listStyle(InsetGroupedListStyle())
                .navigationTitle("Library")
            }
        }
        .onAppear {
            viewModel.fetchRecordings()
        }
    }
}

// Defines the layout for a single row in the library list.
struct VideoRow: View {
    let recording: VideoRecording
    
    // Generate the preview text
    private var transcriptPreview: String {
        // Use .captions extension, map each word, and join them with spaces.
        let fullTranscript = recording.captions.map { $0.text }.joined(separator: " ")
        return fullTranscript.isEmpty ? "No transcript available." : fullTranscript
    }
    
    var body: some View {
        HStack {
            Image(systemName: "video.badge.waveform")
                .font(.largeTitle)
                .foregroundColor(.red)
                .frame(width: 60)

            VStack(alignment: .leading, spacing: 4) {
                Text(recording.createdAt ?? Date(), style: .date)
                    .fontWeight(.semibold)
                
                Text(transcriptPreview)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 8)
    }
}


// MARK: - Preview
#Preview {
    VideoLibraryView()
}
