import Foundation

/* Provides a mapping between spoken words and the names of
 * their corresponding Lottie animation files. Acts like a simple dictionary
 * to look up which animation, if any, should be played for a given word
 */

class AnimationService {
    
    static let shared = AnimationService()
    
    private let animationMap: [String: String] = [
        "hi": "hi",
        "focus": "focus",
        "health": "health",
        "work": "work",
        "improve": "growth_chart",
        "productivity": "growth_chart",
        "find": "find",
        "love": "love",
        "success": "success",
        "you've": "you've"
    ]
    
    private init() {}
    
    /// Checks if an animation exists for a given word.
    /// - Parameter word: The word to look up.
    /// - Returns: The name of the animation file if a match is found, otherwise nil.
    func animationName(for word: String) -> String? {
        
        // remove common punctuation characters.
        let cleanedWord = word.trimmingCharacters(in: .punctuationCharacters)
        
        // convert the cleaned word to lowercase.
        let lowercasedWord = cleanedWord.lowercased()
        
        // look up the clean, lowercase word in our dictionary.
        return animationMap[lowercasedWord]
    }
}
