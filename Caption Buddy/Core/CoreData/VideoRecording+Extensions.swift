import Foundation

/*
 * Adds properties and methods to the auto-generated
 * VideoRecording Core Data class.
 */
extension VideoRecording {
    
    /// A computed property that decodes the `timedCaptionsData` (which is stored as raw Data)
    /// into a usable array of `TimedCaption` structs.
    var captions: [TimedCaption] {
        guard let data = timedCaptionsData else {
            return []
        }
        
        do {
            let decoder = JSONDecoder()
            return try decoder.decode([TimedCaption].self, from: data)
        } catch {
            print("❌ Error decoding timed captions data: \(error)")
            return []
        }
    }
}
