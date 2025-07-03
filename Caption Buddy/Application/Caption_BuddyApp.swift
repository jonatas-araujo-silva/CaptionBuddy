
import SwiftUI

@main
struct Caption_BuddyApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            StreamView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
