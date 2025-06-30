import Foundation
import Combine

/* Responsible for fetching and holding the list of
 saved video recordings to be displayed in the VideoLibraryView.
 */
class VideoLibraryViewModel: ObservableObject {
    
    // Holds the array of video recordings
    @Published var recordings: [VideoRecording] = []
    
    // MARK: - Public Methods
    /// This function use the "DataManager" to fetch recordings from Core Data
    /// This method is called when the view appears
    func fetchRecordings() {
        self.recordings = DataManager.shared.fetchVideoRecordings()
        print("-> Fetched \(recordings.count) video recordings.")
    }
    
    //I'll add other methods here later.
    
}
