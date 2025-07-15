import Foundation

/* Populating the app with sample data for portfolio demos,
 * specifically when running on the simulator.
 */

struct DemoDataGenerator {
    
    static func createPortfolioEntries() async {
        print("SIMULATOR: Generating portfolio demo entries...")
        
        // --- Create Entry for the First Video ---
        if let videoURL1 = Bundle.main.url(forResource: "FirstVideo_Portfolio", withExtension: "mp4"),
           let captionsURL1 = Bundle.main.url(forResource: "Caption_FirstVideo_Portfolio", withExtension: "json") {
            
            await saveDemoData(videoURL: videoURL1, captionsURL: captionsURL1)
        } else {
            print("❌ SIMULATOR ERROR: Could not find FirstVideo_Portfolio assets.")
        }
        
        // --- Create Entry for the Second Video ---
        if let videoURL2 = Bundle.main.url(forResource: "SecondVideo_Portfolio", withExtension: "mp4"),
           let captionsURL2 = Bundle.main.url(forResource: "Caption_SecondVideo_Portfolio", withExtension: "json") {
            
            await saveDemoData(videoURL: videoURL2, captionsURL: captionsURL2)
        } else {
            print("❌ SIMULATOR ERROR: Could not find SecondVideo_Portfolio assets.")
        }
        
        // --- Create Entry for the Third Video ---
        if let videoURL3 = Bundle.main.url(forResource: "DemoLibraryVideo", withExtension: "mp4"),
           let captionsURL3 = Bundle.main.url(forResource: "DemoLibraryCaption", withExtension: "json") {
            
            await saveDemoData(videoURL: videoURL3, captionsURL: captionsURL3)
        } else {
            print("❌ SIMULATOR ERROR: Could not find DemoLibraryVideo assets.")
        }
    }
    
    private static func saveDemoData(videoURL: URL, captionsURL: URL) async {
        do {
            let captionsData = try Data(contentsOf: captionsURL)
            let decoder = JSONDecoder()
            let timedCaptions = try decoder.decode([TimedCaption].self, from: captionsData)
            
            await DataManager.shared.saveVideo(url: videoURL, timedCaptions: timedCaptions)
        } catch {
            print("❌ SIMULATOR ERROR: Failed to decode or save sample data for \(videoURL.lastPathComponent): \(error)")
        }
    }
}
