//
//  Caption_BuddyApp.swift
//  Caption Buddy
//
//  Created by Jonatas Araujo on 12/06/25.
//

import SwiftUI

@main
struct Caption_BuddyApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            MainView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
