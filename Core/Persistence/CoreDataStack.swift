import CoreData
import Combine
import CloudKit

final class CoreDataStack {
    static let shared = CoreDataStack()
    
    // MARK: - Core Data Container
    
    lazy var persistentContainer: NSPersistentCloudKitContainer = {
        let container = NSPersistentCloudKitContainer(name: "AncestryClone")
        
        // Set up container's description for CloudKit sync
        guard let description = container.persistentStoreDescriptions.first else {
            fatalError("Failed to retrieve persistent store description")
        }
        
        // Enable CloudKit sync
        description.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(containerIdentifier: "iCloud.com.example.AncestryClone")
        
        // Enable history tracking and remote notifications
        description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate.
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 */
                fatalError("Unresolved Core Data error \(error), \(error.userInfo)")
            }
        })
        
        // Enable automatic merging of changes from the parent
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        container.viewContext.undoManager = nil
        
        return container
    }()
    
    // MARK: - Core Data Context
    
    var viewContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    // Background context for async operations
    func newBackgroundContext() -> NSManagedObjectContext {
        let context = persistentContainer.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        context.undoManager = nil
        return context
    }
    
    // MARK: - Save Context
    
    func saveContext() {
        let context = viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
    
    // Save background context
    func saveBackgroundContext(_ context: NSManagedObjectContext, completion: ((Error?) -> Void)? = nil) {
        if context.hasChanges {
            do {
                try context.save()
                completion?(nil)
            } catch {
                completion?(error)
                print("Error saving background context: \(error)")
            }
        } else {
            completion?(nil)
        }
    }
    
    // MARK: - Fetch Methods
    
    func fetch<T: NSManagedObject>(_ type: T.Type, predicate: NSPredicate? = nil, sortDescriptors: [NSSortDescriptor]? = nil, limit: Int? = nil) -> [T] {
        let request = NSFetchRequest<T>(entityName: String(describing: type))
        request.predicate = predicate
        request.sortDescriptors = sortDescriptors
        
        if let limit = limit {
            request.fetchLimit = limit
        }
        
        do {
            return try viewContext.fetch(request)
        } catch {
            print("Error fetching \(type): \(error)")
            return []
        }
    }
    
    // MARK: - Delete Method
    
    func delete(_ object: NSManagedObject) {
        viewContext.delete(object)
        saveContext()
    }
    
    // MARK: - CloudKit Utilities
    
    func initCloudKitSchema(completion: @escaping (Error?) -> Void) {
        persistentContainer.initializeCloudKitSchema(options: []) { (result) in
            switch result {
            case .success:
                completion(nil)
            case .failure(let error):
                completion(error)
            }
        }
    }
}

