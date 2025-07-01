import Foundation

/* Provides a mapping between spoken words and the names of
 * their corresponding Lottie animation files. Acts like a simple dictionary
 * to look up which animation, if any, should be played for a given word.
 */

class AnimationService {
    
    static let shared = AnimationService()
    
    // The key is the word (lowercase), and value is animation (without json extension).
    private let animationMap: [String: String] = [
        "hello": "hello",
        "world": "world_sign",
        "goodbye": "goodbye_sign",
        "thanks": "thanks_sign"
    ]
    
    private init() {}
    
    /// Checks if animation exists for a given word.
    /// - Parameter word: The word to look up.
    /// - Returns: The name of the animation file if a match is found, otherwise nil.
    func animationName(for word: String) -> String? {
        // Convert the word to lowercase to make the lookup case-insensitive.
        let lowercasedWord = word.lowercased()
        return animationMap[lowercasedWord]
    }
}
