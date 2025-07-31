import XCTest
import CoreData
@testable import Caption_Buddy

/* Dedicated to verifying the functionality of the DataManager,
 * ensuring that all Core Data operations (saving, fetching, deleting)
 * work as expected, including edge cases.
 */
final class DataManagerTests: XCTestCase {

    var dataManager: DataManager!
    var mockContainer: NSPersistentContainer!

    // This method is called before each test in the class runs.
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        // Explicitly use the bundle for the test class itself to find the model.
        let testBundle = Bundle(for: type(of: self))
        guard let modelURL = testBundle.url(forResource: "CaptionBuddy", withExtension: "momd"),
              let managedObjectModel = NSManagedObjectModel(contentsOf: modelURL) else {
            fatalError("Failed to load Core Data model from test bundle. Make sure the .xcdatamodeld file has Target Membership for CaptionBuddyTests.")
        }
        
        // Create an in-memory Core Data stack for testing.
        mockContainer = NSPersistentContainer(name: "CaptionBuddy", managedObjectModel: managedObjectModel)
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        mockContainer.persistentStoreDescriptions = [description]
        
        mockContainer.loadPersistentStores { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
        
        // Inject the mock container into a new DataManager instance.
        dataManager = DataManager(container: mockContainer)
    }

    // This method is called after each test runs to ensure a clean state.
    override func tearDownWithError() throws {
        dataManager = nil
        mockContainer = nil
        try super.tearDownWithError()
    }

    // MARK: - Test Functions

    func testSaveVideo_ShouldCreateOneVideoRecording() async {
        // GIVEN: A clean state and some sample data.
        let sampleURL = URL(fileURLWithPath: "/test.mov")
        let sampleCaptions = [TimedCaption(text: "hello", startTime: 0, duration: 1)]
        
        // WHEN: We call the async saveVideo function.
        await dataManager.saveVideo(url: sampleURL, timedCaptions: sampleCaptions)
        
        // THEN: We expect exactly one item to be in the database with the correct data.
        let recordings = dataManager.fetchVideoRecordings()
        XCTAssertEqual(recordings.count, 1, "There should be exactly one recording after saving.")
        
        let savedRecording = recordings.first!
        XCTAssertEqual(savedRecording.videoURL, sampleURL, "The saved URL should match the sample URL.")
        XCTAssertEqual(savedRecording.captions.count, 1, "The saved captions should match the sample captions.")
    }
    
    func testFetchVideoRecordings_WhenDatabaseIsEmpty_ShouldReturnEmptyArray() {
        // GIVEN: An empty database (provided by setUpWithError).
        
        // WHEN: We fetch recordings.
        let recordings = dataManager.fetchVideoRecordings()
        
        // THEN: The result should be an empty array.
        XCTAssertTrue(recordings.isEmpty, "Fetching from an empty database should return an empty array.")
    }
    
    func testDeleteVideo_ShouldRemoveRecordingFromDatabase() async {
        // GIVEN: A recording that has been saved to the database.
        let sampleURL = URL(fileURLWithPath: "/test.mov")
        await dataManager.saveVideo(url: sampleURL, timedCaptions: [])
        
        // Verify it was saved correctly.
        var recordings = dataManager.fetchVideoRecordings()
        XCTAssertEqual(recordings.count, 1, "Precondition failed: Recording was not saved.")
        
        // WHEN: We call the delete function.
        let recordingToDelete = recordings.first!
        await dataManager.delete(recording: recordingToDelete)
        
        // THEN: The database should be empty again.
        recordings = dataManager.fetchVideoRecordings()
        XCTAssertTrue(recordings.isEmpty, "The recordings array should be empty after deletion.")
    }
    
    // MARK: - Edge Case Tests
    
    func testSaveVideo_WithEmptyCaptions_ShouldSucceed() async {
        // GIVEN: A video with an empty captions array.
        let sampleURL = URL(fileURLWithPath: "/no_captions.mov")
        let emptyCaptions: [TimedCaption] = []
        
        // WHEN: We save the video.
        await dataManager.saveVideo(url: sampleURL, timedCaptions: emptyCaptions)
        
        // THEN: The video should still be saved correctly.
        let recordings = dataManager.fetchVideoRecordings()
        XCTAssertEqual(recordings.count, 1, "Saving with empty captions should still create a record.")
        XCTAssertTrue(recordings.first!.captions.isEmpty, "The saved captions array should be empty.")
    }
    
    func testFetchVideoRecordings_ShouldReturnInDescendingOrderOfCreation() async {
        // GIVEN: Three videos saved at different times.
        let url1 = URL(fileURLWithPath: "/first.mov")
        let url2 = URL(fileURLWithPath: "/second.mov")
        let url3 = URL(fileURLWithPath: "/third.mov")
        
        await dataManager.saveVideo(url: url1, timedCaptions: [])
        try? await Task.sleep(nanoseconds: 1000) 
        await dataManager.saveVideo(url: url2, timedCaptions: [])
        try? await Task.sleep(nanoseconds: 1000)
        await dataManager.saveVideo(url: url3, timedCaptions: [])
        
        // WHEN: We fetch all recordings.
        let recordings = dataManager.fetchVideoRecordings()
        
        // THEN: The third video (the newest) should be the first item in the array.
        XCTAssertEqual(recordings.count, 3, "There should be three recordings.")
        XCTAssertEqual(recordings.first?.videoURL, url3, "The fetched recordings should be sorted by newest first.")
        XCTAssertEqual(recordings.last?.videoURL, url1, "The oldest recording should be last.")
    }
}
