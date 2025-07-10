import Foundation

/*Used to poulating the app with mock data for portfolio demos,
 * specifically when running on the simulator.
 */
struct DemoDataGenerator {
    
    static func createPortfolioEntries() {
        print("SIMULATOR: Generating portfolio demo entries...")
        
        if let videoURL = Bundle.main.url(forResource: "DemoLibraryVideo", withExtension: "mp4"),
           let captionsURL = Bundle.main.url(forResource: "DemoLibraryCaption", withExtension: "json") {
            
            saveDemoData(videoURL: videoURL, captionsURL: captionsURL)
        } else {
            print("❌ SIMULATOR ERROR: Could not find DemoLibraryVideo assets.")
        }
        
        if let videoURL1 = Bundle.main.url(forResource: "FirstVideo_Portfolio", withExtension: "mp4"),
           let captionsURL1 = Bundle.main.url(forResource: "Caption_FirstVideo_Portfolio", withExtension: "json") {
            
            saveDemoData(videoURL: videoURL1, captionsURL: captionsURL1)
        }
        
        if let videoURL2 = Bundle.main.url(forResource: "SecondVideo_Portfolio", withExtension: "mp4"),
           let captionsURL2 = Bundle.main.url(forResource: "Caption_SecondVideo_Portfolio", withExtension: "json") {
            
            saveDemoData(videoURL: videoURL2, captionsURL: captionsURL2)
        }
    }
    
    private static func saveDemoData(videoURL: URL, captionsURL: URL) {
        do {
            let captionsData = try Data(contentsOf: captionsURL)
            let decoder = JSONDecoder()
            let timedCaptions = try decoder.decode([TimedCaption].self, from: captionsData)
            
            DataManager.shared.saveVideo(url: videoURL, timedCaptions: timedCaptions)
        } catch {
            print("❌ SIMULATOR ERROR: Failed to decode or save sample data for \(videoURL.lastPathComponent): \(error)")
        }
    }
}
