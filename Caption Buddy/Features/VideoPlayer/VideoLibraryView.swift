import SwiftUI

/* Displays a list of all video recordings that have been saved
 * to Core Data. It uses the VideoLibraryViewModel to fetch the data.
 */

struct VideoLibraryView: View {
    
    @StateObject private var viewModel = VideoLibraryViewModel()
    
    var body: some View {
        NavigationView {
            VStack {
                if viewModel.recordings.isEmpty {
                    // Shown when the library is empty
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
                    // Saved video records
                    List {
                        ForEach(viewModel.recordings) { recording in
                            NavigationLink(destination: PlayerView(viewModel: PlayerViewModel(recording: recording))) {
                                VideoRow(recording: recording)
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
                        DemoDataGenerator.createPortfolioEntries()
                        viewModel.fetchRecordings() // Refresh the list
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

// A helper view for a single row in the library list.
struct VideoRow: View {
    let recording: VideoRecording
    
    private var transcriptPreview: String {
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

#Preview {
    VideoLibraryView()
}
