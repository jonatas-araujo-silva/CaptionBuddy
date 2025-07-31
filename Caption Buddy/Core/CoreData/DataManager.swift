import Foundation
import CoreData

// Responsible for all interactions with CoreData
 
class DataManager {
    
    // Uses the production Core Data container from PersistenceController
    static let shared = DataManager(container: PersistenceController.shared.container)
    
    // Reference to the Core Data persistence container
    let container: NSPersistentContainer
    
    // main view context for performing database operations.
    private var viewContext: NSManagedObjectContext {
        return container.viewContext
    }
    
    // This initializer is used to create separate instances of DataManager for testing,
    // injecting a mock container that uses an in-memory database.
    init(container: NSPersistentContainer) {
        self.container = container
    }
    
    /// Saves a new video recording and its timed captions to the database.
    func saveVideo(url: URL, timedCaptions: [TimedCaption]) async {
        // performBackgroundTask is used to make this be used in a safe background thread
        await container.performBackgroundTask { context in
            let newVideo = VideoRecording(context: context)
            
            newVideo.id = UUID()
            newVideo.videoURL = url
            newVideo.createdAt = Date()
            
            let encoder = JSONEncoder()
            do {
                newVideo.timedCaptionsData = try encoder.encode(timedCaptions)
            } catch {
                print("❌ Error encoding timed captions: \(error)")
            }
            
            do {
                try context.save()
                print("✅ Successfully saved video record.")
            } catch {
                print("❌ Error saving video record: \(error)")
            }
        }
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
    func delete(recording: VideoRecording) async {
        let objectID = recording.objectID
        await container.performBackgroundTask { context in
            if let objectToDelete = context.object(with: objectID) as? VideoRecording {
                context.delete(objectToDelete)
                do {
                    try context.save()
                    print("✅ Successfully deleted video record.")
                } catch {
                    print("❌ Error deleting video record: \(error)")
                }
            }
        }
    }
}
