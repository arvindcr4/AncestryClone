import SwiftUI
import CoreData
import Combine
import UIKit

/// Helper class for previewing and testing iPad-specific features
class PreviewHelper {
    
    // MARK: - Sample Data Generation
    
    /// Generates a complete family tree with multiple generations for testing
    static func generateSampleFamilyTree(in context: NSManagedObjectContext) -> Person {
        // Create the root person (ego)
        let ego = createPerson(
            firstName: "James",
            lastName: "Smith",
            birthDate: Calendar.current.date(from: DateComponents(year: 1975, month: 4, day: 12))!,
            birthPlace: "Boston, MA",
            in: context
        )
        
        // Create parents
        let father = createPerson(
            firstName: "Robert",
            lastName: "Smith",
            birthDate: Calendar.current.date(from: DateComponents(year: 1945, month: 10, day: 5))!,
            birthPlace: "Chicago, IL",
            in: context
        )
        
        let mother = createPerson(
            firstName: "Mary",
            lastName: "Johnson",
            birthDate: Calendar.current.date(from: DateComponents(year: 1948, month: 6, day: 23))!,
            birthPlace: "New York, NY",
            in: context
        )
        
        // Create spouse
        let spouse = createPerson(
            firstName: "Jennifer",
            lastName: "Brown",
            birthDate: Calendar.current.date(from: DateComponents(year: 1978, month: 2, day: 15))!,
            birthPlace: "San Francisco, CA",
            in: context
        )
        
        // Create children
        let daughter = createPerson(
            firstName: "Emma",
            lastName: "Smith",
            birthDate: Calendar.current.date(from: DateComponents(year: 2010, month: 7, day: 8))!,
            birthPlace: "Boston, MA",
            in: context
        )
        
        let son = createPerson(
            firstName: "Michael",
            lastName: "Smith",
            birthDate: Calendar.current.date(from: DateComponents(year: 2012, month: 11, day: 19))!,
            birthPlace: "Boston, MA",
            in: context
        )
        
        // Create siblings
        let brother = createPerson(
            firstName: "Thomas",
            lastName: "Smith",
            birthDate: Calendar.current.date(from: DateComponents(year: 1977, month: 8, day: 30))!,
            birthPlace: "Chicago, IL",
            in: context
        )
        
        let sister = createPerson(
            firstName: "Sarah",
            lastName: "Smith",
            birthDate: Calendar.current.date(from: DateComponents(year: 1973, month: 1, day: 17))!,
            birthPlace: "Chicago, IL",
            in: context
        )
        
        // Create grandparents
        let paternalGrandfather = createPerson(
            firstName: "John",
            lastName: "Smith",
            birthDate: Calendar.current.date(from: DateComponents(year: 1920, month: 5, day: 10))!,
            birthPlace: "Detroit, MI",
            in: context
        )
        
        let paternalGrandmother = createPerson(
            firstName: "Elizabeth",
            lastName: "Davis",
            birthDate: Calendar.current.date(from: DateComponents(year: 1922, month: 9, day: 3))!,
            birthPlace: "Cleveland, OH",
            in: context
        )
        
        let maternalGrandfather = createPerson(
            firstName: "William",
            lastName: "Johnson",
            birthDate: Calendar.current.date(from: DateComponents(year: 1919, month: 3, day: 21))!,
            birthPlace: "Philadelphia, PA",
            in: context
        )
        
        let maternalGrandmother = createPerson(
            firstName: "Patricia",
            lastName: "Wilson",
            birthDate: Calendar.current.date(from: DateComponents(year: 1924, month: 12, day: 11))!,
            birthPlace: "Buffalo, NY",
            in: context
        )
        
        // Add relationships
        addRelationship(type: "Parent", from: ego, to: father, in: context)
        addRelationship(type: "Parent", from: ego, to: mother, in: context)
        addRelationship(type: "Child", from: father, to: ego, in: context)
        addRelationship(type: "Child", from: mother, to: ego, in: context)
        
        addRelationship(type: "Spouse", from: ego, to: spouse, in: context)
        addRelationship(type: "Spouse", from: spouse, to: ego, in: context)
        
        addRelationship(type: "Child", from: ego, to: daughter, in: context)
        addRelationship(type: "Child", from: ego, to: son, in: context)
        addRelationship(type: "Parent", from: daughter, to: ego, in: context)
        addRelationship(type: "Parent", from: son, to: ego, in: context)
        
        addRelationship(type: "Child", from: spouse, to: daughter, in: context)
        addRelationship(type: "Child", from: spouse, to: son, in: context)
        addRelationship(type: "Parent", from: daughter, to: spouse, in: context)
        addRelationship(type: "Parent", from: son, to: spouse, in: context)
        
        addRelationship(type: "Sibling", from: ego, to: brother, in: context)
        addRelationship(type: "Sibling", from: ego, to: sister, in: context)
        addRelationship(type: "Sibling", from: brother, to: ego, in: context)
        addRelationship(type: "Sibling", from: sister, to: ego, in: context)
        
        addRelationship(type: "Parent", from: father, to: paternalGrandfather, in: context)
        addRelationship(type: "Parent", from: father, to: paternalGrandmother, in: context)
        addRelationship(type: "Child", from: paternalGrandfather, to: father, in: context)
        addRelationship(type: "Child", from: paternalGrandmother, to: father, in: context)
        
        addRelationship(type: "Parent", from: mother, to: maternalGrandfather, in: context)
        addRelationship(type: "Parent", from: mother, to: maternalGrandmother, in: context)
        addRelationship(type: "Child", from: maternalGrandfather, to: mother, in: context)
        addRelationship(type: "Child", from: maternalGrandmother, to: mother, in: context)
        
        // Add media (photos) for people
        addPhoto(for: ego, named: "james", in: context)
        addPhoto(for: spouse, named: "jennifer", in: context)
        addPhoto(for: daughter, named: "emma", in: context)
        addPhoto(for: son, named: "michael", in: context)
        
        // Add events
        addEvent(type: "Birth", for: ego, date: ego.birthDate!, place: ego.birthPlace!, in: context)
        addEvent(type: "Birth", for: spouse, date: spouse.birthDate!, place: spouse.birthPlace!, in: context)
        addEvent(type: "Marriage", for: ego, date: Calendar.current.date(from: DateComponents(year: 2008, month: 6, day: 14))!, place: "Boston, MA", in: context)
        
        // Try to save the context
        do {
            try context.save()
        } catch {
            print("Error saving preview context: \(error)")
        }
        
        return ego
    }
    
    // Create a sample large dataset for stress testing iPad performance
    static func generateLargeFamilyTree(peopleCount: Int, in context: NSManagedObjectContext) -> Person {
        // Create a base person
        let rootPerson = createPerson(
            firstName: "Root",
            lastName: "Person",
            birthDate: Date(),
            birthPlace: "Test Location",
            in: context
        )
        
        // Create a batch of people
        var allPeople = [rootPerson]
        
        for i in 0..<peopleCount {
            let person = createPerson(
                firstName: "Test\(i)",
                lastName: "Person\(i % 100)",
                birthDate: Calendar.current.date(byAdding: .year, value: -(i % 80 + 20), to: Date())!,
                birthPlace: "Location \(i % 50)",
                in: context
            )
            allPeople.append(person)
            
            // Create some relationships to make a realistic tree
            // Every 10th person is a parent of the root
            if i % 10 == 0 {
                addRelationship(type: "Parent", from: rootPerson, to: person, in: context)
                addRelationship(type: "Child", from: person, to: rootPerson, in: context)
            }
            // Every 5th person is a child
            else if i % 5 == 0 {
                addRelationship(type: "Child", from: rootPerson, to: person, in: context)
                addRelationship(type: "Parent", from: person, to: rootPerson, in: context)
            }
            // Others are connected somehow to make a complex network
            else if i % 3 == 0 {
                let randomPerson = allPeople[Int.random(in: 0..<allPeople.count)]
                addRelationship(type: "Sibling", from: randomPerson, to: person, in: context)
                addRelationship(type: "Sibling", from: person, to: randomPerson, in: context)
            }
        }
        
        // Batch save
        do {
            try context.save()
        } catch {
            print("Error saving large dataset: \(error)")
        }
        
        return rootPerson
    }
    
    // Helper to create a person
    private static func createPerson(firstName: String, lastName: String, birthDate: Date, birthPlace: String, in context: NSManagedObjectContext) -> Person {
        let person = Person(context: context)
        person.id = UUID()
        person.firstName = firstName
        person.lastName = lastName
        person.birthDate = birthDate
        person.birthPlace = birthPlace
        return person
    }
    
    // Helper to add a relationship
    private static func addRelationship(type: String, from person1: Person, to person2: Person, in context: NSManagedObjectContext) {
        let relationship = Relationship(context: context)
        relationship.id = UUID()
        relationship.type = type
        relationship.person = person1
        relationship.relatedPerson = person2
    }
    
    // Helper to add a photo
    private static func addPhoto(for person: Person, named: String, in context: NSManagedObjectContext) {
        // In a real app, we'd load actual images, but for preview we'll just create the Media object
        let media = Media(context: context)
        media.id = UUID()
        media.type = "Photo"
        media.person = person
        media.dateAdded = Date()
        media.caption = "Photo of \(person.fullName)"
        
        // In a real implementation, we would load actual image data
        // media.data = UIImage(named: named)?.jpegData(compressionQuality: 0.8)
    }
    
    // Helper to add an event
    private static func addEvent(type: String, for person: Person, date: Date, place: String, in context: NSManagedObjectContext) {
        let event = Event(context: context)
        event.id = UUID()
        event.type = type
        event.date = date
        event.place = place
        event.person = person
    }
    
    // MARK: - Multi-Window Preview Support
    
    /// Creates preview content for multiple windows/scenes
    static func multiWindowPreview<Content: View>(@ViewBuilder content: @escaping () -> Content) -> some View {
        Group {
            // Main window preview
            content()
                .previewDisplayName("Main Window")
            
            // Secondary window preview - simulates iPad split screen
            content()
                .environment(\.windowInFocus, false)
                .previewDisplayName("Secondary Window")
        }
    }
    
    // MARK: - Layout Previews
    
    /// Shows the same view in both portrait and landscape orientations for iPad
    static func deviceOrientationPreviews<Content: View>(
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        Group {
            // iPad Pro 11-inch portrait
            content()
                .previewDevice(PreviewDevice(rawValue: "iPad Pro (11-inch)"))
                .previewDisplayName("iPad Pro 11\" Portrait")
                .previewInterfaceOrientation(.portrait)
            
            // iPad Pro 11-inch landscape
            content()
                .previewDevice(PreviewDevice(rawValue: "iPad Pro (11-inch)"))
                .previewDisplayName("iPad Pro 11\" Landscape")
                .previewInterfaceOrientation(.landscapeLeft)
            
            // iPad Pro 12.9-inch landscape
            content()
                .previewDevice(PreviewDevice(rawValue: "iPad Pro (12.9-inch)"))
                .previewDisplayName("iPad Pro 12.9\" Landscape")
                .previewInterfaceOrientation(.landscapeLeft)
            
            // iPhone for comparison
            content()
                .previewDevice(PreviewDevice(rawValue: "iPhone 14 Pro"))
                .previewDisplayName("iPhone 14 Pro")
        }
    }
    
    // MARK: - Memory Management Simulation
    
    /// Simulates a memory warning for testing memory handling
    static func simulateMemoryWarning() {
        NotificationCenter.default.post(
            name: UIApplication.didReceiveMemoryWarningNotification, 
            object: nil
        )
    }
    
    /// Creates large objects to stress test memory management
    static func allocateLargeMemory(megabytes: Int) {
        // Allocate a large array to simulate memory pressure
        // 1 MB is roughly 131,072 Int values (8 bytes each)
        let count = megabytes * 131_072
        var largeArray = [Int](repeating: 0, count: count)
        
        // Ensure the array is used so it doesn't get optimized away
        largeArray[0] = 1
        print("Allocated \(megabytes)MB of memory")
    }
    
    // MARK: - Scene Handling Demonstration
    
    /// Creates a view that demonstrates scene lifecycle handling
    static func sceneHandlingDemoView() -> some View {
        SceneHandlingDemoView()
    }
}

// MARK: - Environment Extension for Window Focus

// Extension to add window focus state to the environment
struct WindowInFocusKey: EnvironmentKey {
    static let defaultValue: Bool = true
}

extension EnvironmentValues {
    var windowInFocus: Bool {
        get { self[WindowInFocusKey.self] }
        set { self[WindowInFocusKey

