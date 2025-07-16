import Foundation
import CoreData

//Responsible for all interactions with Core Data

class DataManager {
    
    // Shared singleton instance
    static let shared = DataManager(container: PersistenceController.shared.container)
    
    // Reference to Core Data persistence container
    private let container: NSPersistentContainer
    
    // Main view context for performing database operations
    private var viewContext: NSManagedObjectContext {
        return container.viewContext
    }
    
    init(container: NSPersistentContainer) {
        self.container = container
    }
    
    /// Saves a new video recording and its timed captions to database.
    func saveVideo(url: URL, timedCaptions: [TimedCaption]) async {
        let newVideo = VideoRecording(context: viewContext)
        
        newVideo.id = UUID()
        newVideo.videoURL = url
        newVideo.createdAt = Date()
        
        let encoder = JSONEncoder()
        do {
            newVideo.timedCaptionsData = try encoder.encode(timedCaptions)
        } catch {
            print("❌ Error encoding timed captions: \(error)")
            newVideo.timedCaptionsData = nil
        }
        
        await saveContext()
        print("✅ Successfully saved video record with timed captions to Core Data.")
    }
    
    /// Fetches all saved video recordings from Core Data.
    func fetchVideoRecordings() -> [VideoRecording] {
        let request: NSFetchRequest<VideoRecording> = VideoRecording.fetchRequest()
        
        let sortDescriptor = NSSortDescriptor(keyPath: \VideoRecording.createdAt, ascending: false)
        request.sortDescriptors = [sortDescriptor]
        
        do {
            return try viewContext.fetch(request)
        } catch {
            print("❌ Error fetching video recordings: \(error)")
            return []
        }
    }
    
    /// Deletes a given VideoRecording object from the Core Data store.
    /// - Parameter recording: The `VideoRecording` managed object to delete.
    func delete(recording: VideoRecording) async {
        viewContext.delete(recording)
        await saveContext()
        print("✅ Successfully deleted video record from Core Data.")
    }
    
    /// A private helper function to save the current state of the view context.
    private func saveContext() async {
        guard viewContext.hasChanges else { return }
        
        do {
            try await viewContext.perform {
                try self.viewContext.save()
            }
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
    }
}
