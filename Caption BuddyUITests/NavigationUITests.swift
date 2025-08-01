import XCTest

/* Verifies the main navigation of the app, ensuring that
 * each tab can be tapped and that the correct view is presented.
 */

final class NavigationUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    // --- Test Functions ---

    func testTabBarExistsAndHasThreeButtons() {
        // GIVEN: The app has launched.
        
        // THEN: The main tab bar should exist and contain exactly three buttons.
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 5), "The main tab bar should exist.")
        XCTAssertEqual(tabBar.buttons.count, 3, "The tab bar should have exactly 3 buttons.")
    }
    
    func testNavigateToRecordTab_ShouldShowRecordButton() {
        // GIVEN: The app has launched.
        
        // WHEN: The user taps the "Record" tab.
        app.tabBars.buttons["Record"].tap()
        
        // THEN: The record button should be visible.
        let recordButton = app.buttons["recordButton"]
        XCTAssertTrue(recordButton.waitForExistence(timeout: 5), "The record button should be visible on the Record screen.")
    }
    
    func testNavigateToLibraryTab_ShouldShowLibraryTitle() {
        // GIVEN: The app has launched.
        
        // WHEN: The user taps on the "Library" tab.
        app.tabBars.buttons["Library"].tap()
        
        // THEN: The navigation title "Library" should be visible.
        let libraryTitle = app.navigationBars["Library"]
        XCTAssertTrue(libraryTitle.waitForExistence(timeout: 5), "The navigation bar title for the Library screen should be visible.")
    }
    
    func testNavigateToLiveTab_ShouldShowLiveTitle() {
        // GIVEN: The app has launched.
        
        // WHEN: The user taps on the "Live" tab.
        app.tabBars.buttons["Live"].tap()
        
        // THEN: The text "Ready to Go Live?" should be visible on the screen.
        let liveTitle = app.staticTexts["liveStreamTitle"]
        XCTAssertTrue(liveTitle.waitForExistence(timeout: 5), "The title on the Pre-Join Live screen should be visible.")
    }
}
