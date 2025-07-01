import Foundation

/*
 Codable struct that represents a single segment of a transcription.
 * Holds the spoken word and its start and end time within the video.
 */

struct TimedCaption: Codable, Identifiable {
    var id = UUID()
    let text: String
    let startTime: TimeInterval
    let duration: TimeInterval
    
    private enum CodingKeys: String, CodingKey {
        case text, startTime, duration
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        text = try container.decode(String.self, forKey: .text)
        startTime = try container.decode(TimeInterval.self, forKey: .startTime)
        duration = try container.decode(TimeInterval.self, forKey: .duration)
        id = UUID()
    }
    
    init(id: UUID = UUID(), text: String, startTime: TimeInterval, duration: TimeInterval) {
        self.id = id
        self.text = text
        self.startTime = startTime
        self.duration = duration
    }
}
