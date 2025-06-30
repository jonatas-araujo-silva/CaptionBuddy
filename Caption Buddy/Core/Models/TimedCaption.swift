import Foundation

/* A Codable struct that represents a single segment of a transcription.
 * Holds the spoken word and its start and end time within the video,
 */

struct TimedCaption: Codable, Identifiable {
    var id = UUID()
    
    let text: String
    
    let startTime: TimeInterval
    
    let duration: TimeInterval
}
