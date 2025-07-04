import Foundation

//Represent a single message in the live chat.

struct ChatMessage: Identifiable {
    let id = UUID()
    let isFromLocalUser: Bool
    let text: String
}
