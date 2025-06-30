import Foundation
import CoreData

class DataManager {
    
    static let shared = DataManager()
    private let container: NSPersistentContainer
    private var viewContext: NSManagedObjectContext {
        return container.viewContext
    }
    
    private init() {
        container = PersistenceController.shared.container
    }
    
    /// - Parameters:
    func saveVideo(url: URL, timedCaptions: [TimedCaption]) {
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
        
        saveContext()
        print("✅ Successfully saved video record with timed captions to Core Data.")
    }
    
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
    
    private func saveContext() {
        guard viewContext.hasChanges else { return }
        
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
    }
}
