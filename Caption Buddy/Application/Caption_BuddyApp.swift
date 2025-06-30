
import SwiftUI

@main
struct Caption_BuddyApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            APITestView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
