import CoreData
import Combine
import CloudKit
import UIKit
import os.log

final class CoreDataStack {
    static let shared = CoreDataStack()
    
    // Logger for CoreData operations
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.example.AncestryClone", category: "CoreData")
    
    // For handling low memory situations
    private var lowMemoryObserver: NSObjectProtocol?
    
    // For iPad scene handling
    private var sceneActivationObservers: [NSObjectProtocol] = []
    
    init() {
        setupMemoryManagement()
        setupSceneHandling()
    }
    
    deinit {
        if let observer = lowMemoryObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        
        for observer in sceneActivationObservers {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
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
        // Enable automatic merging of changes from the parent
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        container.viewContext.undoManager = nil
        
        // Important for iPad with larger datasets - prevent blocking UI
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.shouldDeleteInaccessibleFaults = true
        
        // Configure query generations for table views
        do {
            try container.viewContext.setQueryGenerationFrom(.current)
        } catch {
            logger.error("Failed to pin viewContext to the current generation: \(error.localizedDescription)")
        }
        return container
    }()
    
    // MARK: - Core Data Context
    
    var viewContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    // MARK: - Context Management
    
    // Return a context specific to the current scene on iPad or the shared context on iPhone
    func contextForScene(_ scene: UIScene? = nil) -> NSManagedObjectContext {
        // For iPad with multiple windows, we might want separate contexts
        if UIDevice.current.userInterfaceIdiom == .pad, 
           let windowScene = scene as? UIWindowScene {
            // For now, we're still using the shared viewContext for consistency
            // In the future, we could create scene-specific contexts if needed
            return viewContext
        }
        
        // Default to the shared view context
        return viewContext
    }
    
    // Background context for async operations
    func newBackgroundContext() -> NSManagedObjectContext {
        let context = persistentContainer.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        context.undoManager = nil
        
        // Set the qos for background tasks
        context.performAndWait {
            context.transactionAuthor = "background"
            context.name = "backgroundContext-\(UUID().uuidString)"
        }
        
        return context
    }
    
    // Get a background context and perform work with it
    func performBackgroundTask(_ block: @escaping (NSManagedObjectContext) -> Void) {
        persistentContainer.performBackgroundTask { context in
            context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
            block(context)
        }
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
                logger.error("Error saving background context: \(error.localizedDescription)")
            }
        } else {
            completion?(nil)
        }
    }
    }
    
    // Save context with error handling
    func saveContext(_ context: NSManagedObjectContext, completion: ((Error?) -> Void)? = nil) {
        // Don't save if there are no changes
        guard context.hasChanges else {
            completion?(nil)
            return
        }
        
        // Check whether this is the main context or a background context
        if context === viewContext {
            // This is the main context, so perform the save directly
            do {
                try context.save()
                completion?(nil)
            } catch {
                logger.error("Error saving main context: \(error.localizedDescription)")
                completion?(error)
            }
        } else {
            // This is a background context, so perform the save in the background
            context.perform {
                do {
                    try context.save()
                    completion?(nil)
                } catch {
                    self.logger.error("Error saving background context: \(error.localizedDescription)")
                    completion?(error)
                }
            }
        }
    }
    
    func fetch<T: NSManagedObject>(_ type: T.Type, 
                                   predicate: NSPredicate? = nil, 
                                   sortDescriptors: [NSSortDescriptor]? = nil, 
                                   limit: Int? = nil,
                                   batchSize: Int? = nil) -> [T] {
        let request = NSFetchRequest<T>(entityName: String(describing: type))
        request.predicate = predicate
        request.sortDescriptors = sortDescriptors
        
        // Add batch size for better performance with large datasets on iPad
        if let batchSize = batchSize {
            request.fetchBatchSize = batchSize
        } else if UIDevice.current.userInterfaceIdiom == .pad {
            // Default batch size for iPad
            request.fetchBatchSize = 50
        }
        
        if let limit = limit {
            request.fetchLimit = limit
        }
        
        do {
            return try viewContext.fetch(request)
        } catch {
            logger.error("Error fetching \(String(describing: type)): \(error.localizedDescription)")
            return []
        }
    }
    
    // Fetch that returns an async Combine publisher for better UI responsiveness
    func fetchPublisher<T: NSManagedObject>(_ type: T.Type,
                                           predicate: NSPredicate? = nil,
                                           sortDescriptors: [NSSortDescriptor]? = nil,
                                           limit: Int? = nil,
                                           batchSize: Int? = nil) -> AnyPublisher<[T], Error> {
        return Future<[T], Error> { promise in
            self.performBackgroundTask { context in
                let request = NSFetchRequest<T>(entityName: String(describing: type))
                request.predicate = predicate
                request.sortDescriptors = sortDescriptors
                
                if let batchSize = batchSize {
                    request.fetchBatchSize = batchSize
                } else if UIDevice.current.userInterfaceIdiom == .pad {
                    request.fetchBatchSize = 50
                }
                
                if let limit = limit {
                    request.fetchLimit = limit
                }
                
                do {
                    let results = try context.fetch(request)
                    
                    // Get the object IDs for the fetched objects
                    let objectIDs = results.map { $0.objectID }
                    
                    // Get the corresponding objects from the view context on the main thread
                    DispatchQueue.main.async {
                        let viewContextObjects = objectIDs.compactMap {
                            self.viewContext.object(with: $0) as? T
                        }
                        promise(.success(viewContextObjects))
                    }
                } catch {
                    self.logger.error("Error in fetchPublisher: \(error.localizedDescription)")
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    // Fetch in batches for large datasets (especially useful for FamilyTree visualization)
    func fetchLargeDataset<T: NSManagedObject>(_ type: T.Type,
                                              predicate: NSPredicate? = nil,
                                              sortDescriptors: [NSSortDescriptor]? = nil,
                                              batchHandler: @escaping ([T]) -> Void,
                                              completion: @escaping (Error?) -> Void) {
        let batchSize = UIDevice.current.userInterfaceIdiom == .pad ? 100 : 50
        let context = newBackgroundContext()
        
        context.perform {
            let request = NSFetchRequest<NSFetchRequestResult>(entityName: String(describing: type))
            request.predicate = predicate
            request.sortDescriptors = sortDescriptors
            request.fetchBatchSize = batchSize
            
            do {
                // Use NSBatchFetchRequest on iOS 13+
                let batchFetchRequest = NSBatchFetchRequest(fetchRequest: request)
                batchFetchRequest.resultType = .objectIDs
                batchFetchRequest.fetchBatchSize = batchSize
                
                guard let fetchResult = try context.execute(batchFetchRequest) as? NSBatchFetchResult<NSManagedObjectID>,
                      let objectIDs = fetchResult.result as? [NSManagedObjectID] else {
                    completion(NSError(domain: "com.example.AncestryClone", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to fetch object IDs"]))
                    return
                }
                
                // Process the results in batches
                let totalObjects = objectIDs.count
                let numberOfBatches = (totalObjects + batchSize - 1) / batchSize
                
                for batchIndex in 0..<numberOfBatches {
                    let start = batchIndex * batchSize
                    let end = min(start + batchSize, totalObjects)
                    let batchObjectIDs = Array(objectIDs[start..<end])
                    
                    let batchPredicate = NSPredicate(format: "SELF IN %@", batchObjectIDs)
                    let batchFetchRequest = NSFetchRequest<T>(entityName: String(describing: type))
                    batchFetchRequest.predicate = batchPredicate
                    
                    let batchObjects = try context.fetch(batchFetchRequest)
                    DispatchQueue.main.async {
                        batchHandler(batchObjects)
                    }
                }
                
                DispatchQueue.main.async {
                    completion(nil)
                }
            } catch {
                self.logger.error("Error in fetchLargeDataset: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion(error)
                }
            }
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
    
    // MARK: - Memory Management
    
    private func setupMemoryManagement() {
        // Register for memory warnings
        lowMemoryObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleMemoryWarning()
        }
    }
    
    private func handleMemoryWarning() {
        logger.warning("Memory warning received, clearing caches")
        
        // Reset the view context - this will drop all non-fault objects
        viewContext.refreshAllObjects()
        
        // For large datasets on iPad, we should also clear our in-memory caches
        // and aggressively release memory
        if UIDevice.current.userInterfaceIdiom == .pad {
            NSFetchedResultsController<NSFetchRequestResult>.deleteCache(withName: nil)
            
            // Reset any registered NSFetchedResultsControllers
            NotificationCenter.default.post(name: .memoryWarningReceived, object: nil)
        }
    }
    
    // MARK: - Scene Management for iPad
    
    private func setupSceneHandling() {
        // Only needed on iPad
        guard UIDevice.current.userInterfaceIdiom == .pad else { return }
        
        // Track scene activation to manage context per scene
        let activationObserver = NotificationCenter.default.addObserver(
            forName: UIScene.didActivateNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let scene = notification.object as? UIScene else { return }
            self?.handleSceneActivation(scene)
        }
        
        let deactivationObserver = NotificationCenter.default.addObserver(
            forName: UIScene.didDisconnectNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let scene = notification.object as? UIScene else { return }
            self?.handleSceneDeactivation(scene)
        }
        
        sceneActivationObservers.append(contentsOf: [activationObserver, deactivationObserver])
    }
    
    private func handleSceneActivation(_ scene: UIScene) {
        // In a more complex app, we might associate a specific context with each scene
        // For now, we're tracking activations but still using the shared viewContext
        logger.debug("Scene activated: \(scene.description)")
        
        // Save any pending changes
        if viewContext.hasChanges {
            saveContext(viewContext)
        }
    }
    
    private func handleSceneDeactivation(_ scene: UIScene) {
        logger.debug("Scene deactivated: \(scene.description)")
        
        // Save any pending changes from this scene
        if viewContext.hasChanges {
            saveContext(viewContext)
        }
    }
    
    // MARK: - Prefetching for Tree Visualization
    
    // Prefetch relationships for smoother tree rendering
    func prefetchPersonRelationships(for person: Person) {
        let objectID = person.objectID
        
        performBackgroundTask { context in
            guard let personInContext = try? context.existingObject(with: objectID) as? Person else {
                return
            }
            
            // Prefetch first-degree relationships
            let relationships = personInContext.relationships
            
            // Touch all the related objects to ensure they're loaded
            for relationship in relationships {
                let _ = relationship.relatedPerson
            }
            
            // Also prefetch media and events
            if let media = personInContext.media {
                let _ = media.count
            }
            
            if let events = personInContext.events {
                let _ = events.count
            }
            
            // Update UI on main thread if needed
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .relationshipsPreloaded, object: person.objectID)
            }
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let memoryWarningReceived = Notification.Name("com.example.AncestryClone.memoryWarningReceived")
    static let relationshipsPreloaded = Notification.Name("com.example.AncestryClone.relationshipsPreloaded")
}

// MARK: - Preview Helper

#if DEBUG
extension CoreDataStack {
    static var preview: CoreDataStack = {
        let result = CoreDataStack()
        let viewContext = result.persistentContainer.viewContext
        
        // Create sample data for previews
        let samplePerson = Person(context: viewContext)
        samplePerson.id = UUID()
        samplePerson.firstName = "John"
        samplePerson.lastName = "Smith"
        samplePerson.birthDate = Calendar.current.date(byAdding: .year, value: -45, to: Date())
        samplePerson.birthPlace = "New York, NY"
        
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error creating preview data: \(nsError), \(nsError.userInfo)")
        }
        
        return result
    }()
}
#endif
