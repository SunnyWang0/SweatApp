//
//  SweatApp.swift
//  Sweat
//
//  Created by Sunny Wang on 1/18/25.
//

import SwiftUI

@main
struct SweatApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
