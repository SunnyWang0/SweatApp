//
//  Persistence.swift
//  Sweat
//
//  Created by Sunny Wang on 1/18/25.
//

import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    @MainActor
    static let preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        
        // Create sample wines
        let supplementNames = ["C4", "Bang", "BuggedUp"]
        let supplementTypes = ["Preworkout", "Energy Drink", "Preworkout"]
        
        for i in 0..<supplementNames.count {
            let supplement = Supplement(context: viewContext)
            supplement.id = UUID()
            supplement.name = supplementNames[i]
            supplement.type = supplementTypes[i]
            
            // Create a scan for each wine
            let scan = Scan(context: viewContext)
            scan.id = UUID()
            scan.date = Date().addingTimeInterval(Double(-i * 86400))
            scan.supplement = supplement
            
            // Add some ratings
            if i < 2 {
                let rating = Rating(context: viewContext)
                rating.id = UUID()
                rating.date = Date()
                rating.score = Double(4 + i)
                rating.supplement = supplement
            }
        }
        
        do {
            try viewContext.save()
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "Sweat")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.

                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}
