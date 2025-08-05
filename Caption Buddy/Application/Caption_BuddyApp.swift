import SwiftUI

@main
struct Caption_BuddyApp: App {
    let persistenceController = PersistenceController.shared
    
    // controls the launch screen's visibility:
    @State private var isShowingLaunchScreen = true

    var body: some Scene {
        WindowGroup {
            ZStack {
                if isShowingLaunchScreen {
                    LaunchScreenView()
                        .transition(.opacity)
                } else {
                    MainView()
                        .environment(\.managedObjectContext, persistenceController.container.viewContext)
                }
            }
            .onAppear {
                Task {
                    // Wait for: 1.5 seconds
                    try? await Task.sleep(nanoseconds: 1_500_000_000)
                    
                    //trigger the transition to main view with an animation
                    withAnimation {
                        isShowingLaunchScreen = false
                    }
                }
            }
        }
    }
}
