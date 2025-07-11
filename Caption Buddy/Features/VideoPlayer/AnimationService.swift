import Foundation

/* Provides a mapping between spoken words and the names of
 * their corresponding Lottie animation files. acts like a dictionary
 * to look which animation, if any, should be played for a word.
 */
class AnimationService {
    
    static let shared = AnimationService()
    
    private let animationMap: [String: String] = [
        //first String = Word said, second String = JSON Animation File.
        "hi": "hi",
        "ok": "ok",
        "focus": "focus",
        "health": "health",
        "work": "work",
        "improve": "growth_chart",
        "productivity": "growth_chart",
        "plan": "idea",
        "automation": "work",
        "key": "find",
        "deadline": "success",
        "success": "success"
    ]
    
    private init() {}
    
    /// Check if an animation exists for a word
    /// - Parameter word: The word to look.
    /// - Returns: The name of the animation file if a match is found.
    func animationName(for word: String) -> String? {
        //Remove punctuation characters
        let cleanedWord = word.trimmingCharacters(in: .punctuationCharacters)
            
        //Convert the cleaned word to lowercase
        let lowercasedWord = cleanedWord.lowercased()
            
        //Look up the clean, lowercase word in our dictionary.
        let animationName = animationMap[lowercasedWord]
        
        if animationName == nil {  }
            
        return animationName
    }
}
