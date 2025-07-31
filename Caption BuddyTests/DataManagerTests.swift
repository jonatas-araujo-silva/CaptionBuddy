import XCTest
import CoreData
@testable import Caption_Buddy

// Dedicated to verifying the functionality of the DataManager

final class DataManagerTests: XCTestCase {

    var dataManager: DataManager!
    var mockContainer: NSPersistentContainer!

    // This method is called before each test in the class runs.
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        let managedObjectModel = NSManagedObjectModel()
        
        // Create the VideoRecording entity
        let videoEntity = NSEntityDescription()
        videoEntity.name = "VideoRecording"
        videoEntity.managedObjectClassName = "VideoRecording"
        
        // Create the attributes for the entity
        let idAttr = NSAttributeDescription()
        idAttr.name = "id"
        idAttr.attributeType = .UUIDAttributeType
        idAttr.isOptional = false
        
        let createdAtAttr = NSAttributeDescription()
        createdAtAttr.name = "createdAt"
        createdAtAttr.attributeType = .dateAttributeType
        createdAtAttr.isOptional = true
        
        let timedCaptionsAttr = NSAttributeDescription()
        timedCaptionsAttr.name = "timedCaptionsData"
        timedCaptionsAttr.attributeType = .binaryDataAttributeType
        timedCaptionsAttr.isOptional = true
        
        let videoURLAttr = NSAttributeDescription()
        videoURLAttr.name = "videoURL"
        videoURLAttr.attributeType = .URIAttributeType
        videoURLAttr.isOptional = true
        
        videoEntity.properties = [idAttr, createdAtAttr, timedCaptionsAttr, videoURLAttr]
        managedObjectModel.entities = [videoEntity]
        
        // Create an in-memory Core Data stack with our programmatic model.
        mockContainer = NSPersistentContainer(name: "CaptionBuddyMock", managedObjectModel: managedObjectModel)
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        mockContainer.persistentStoreDescriptions = [description]
        
        mockContainer.loadPersistentStores { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
        
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
}
