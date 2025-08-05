import Foundation

/* Simple utility for populating the app with sample data for portfolio demos,
 * specifically when running on the simulator.
 */
struct DemoDataGenerator {
    
    private struct DemoAsset {
        let videoName: String
        let captionName: String
    }
    
    private static let demoAssets: [DemoAsset] = [
        DemoAsset(videoName: "FirstVideo_Portfolio", captionName: "Caption_FirstVideo_Portfolio"),
        DemoAsset(videoName: "SecondVideo_Portfolio", captionName: "Caption_SecondVideo_Portfolio"),
        DemoAsset(videoName: "DemoLibraryVideo", captionName: "DemoLibraryCaption")
    ]
    
    static func createPortfolioEntries() async {
        print("SIMULATOR: Generating portfolio demo entries...")
        
        for asset in demoAssets {
            if let videoURL = Bundle.main.url(forResource: asset.videoName, withExtension: "mp4"),
               let captionsURL = Bundle.main.url(forResource: asset.captionName, withExtension: "json") {
                
                await saveDemoData(videoURL: videoURL, captionsURL: captionsURL)
            } else {
                print("❌ SIMULATOR ERROR: Could not find assets for \(asset.videoName).")
            }
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
