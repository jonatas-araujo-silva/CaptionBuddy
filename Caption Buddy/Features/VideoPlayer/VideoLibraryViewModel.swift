import Foundation
import Combine

/* Responsible for fetching, holding, and deleting the list of
 * saved video recordings to be displayed in the VideoLibraryView.
 */

@MainActor
class VideoLibraryViewModel: ObservableObject {
    
    // Holds the array of video recordings
    @Published var recordings: [VideoRecording] = []
    
    // MARK: - Public Methods
    
    /// Fetches the video recordings from Core Data using DataManager
    /// This method should be called when the view appears
    func fetchRecordings() {
        self.recordings = DataManager.shared.fetchVideoRecordings()
        print("-> Fetched \(recordings.count) video recordings.")
    }
    
    /// Deletes recordings at the specified index set from both the local array and Core Data.
    /// - Parameter offsets: An `IndexSet` containing the indices of the recordings to delete.
    func delete(at offsets: IndexSet) async {
        // Creates a copy of the recordings to be deleted
        let recordingsToDelete = offsets.map { self.recordings[$0] }
        
        // Remove from the local array first
        self.recordings.remove(atOffsets: offsets)
        
        // Loop through the copied array and delete each from Core Data
        for recording in recordingsToDelete {
            await DataManager.shared.delete(recording: recording)
        }
    }
}
