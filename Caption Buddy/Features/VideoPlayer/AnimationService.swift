import Foundation

/*Provides a mapping between spoken words and the names of
 * their corresponding Lottie animation files. acts as a simple dictionary
 * to look up which animation, if any, should be played for a given word.
 */
class AnimationService {
    
    static let shared = AnimationService()
    
    private let animationMap: [String: String] = [
        
        "okay": "okay",
        "plan": "plan",
        "focus": "focus",
        "automation": "automation",
        "key": "key",
        "deadline": "deadline",
        "success": "success"
    ]
    
    private init() {}
    
    /// Checks if an animation exists for a given word.
    /// - Parameter word: The word to look up.
    /// - Returns: The name of the animation file if a match is found, otherwise nil.
    func animationName(for word: String) -> String? {
        let cleanedWord = word.trimmingCharacters(in: .punctuationCharacters)
        
        let lowercasedWord = cleanedWord.lowercased()
        
        return animationMap[lowercasedWord]
    }
}
