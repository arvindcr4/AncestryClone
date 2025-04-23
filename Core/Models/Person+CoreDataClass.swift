import Foundation
import CoreData

@objc(Person)
public class Person: NSManagedObject {
    // Convenience methods for person management
    func addEvent(_ event: Event) {
        addToEvents(event)
    }
    
    func addRelationship(_ relationship: Relationship) {
        addToRelationships(relationship)
    }
    
    func addMedia(_ media: Media) {
        addToMedia(media)
    }
    
    func addSource(_ source: Source) {
        addToSources(source)
    }
    
    var fullName: String {
        [firstName, lastName].compactMap { $0 }.joined(separator: " ")
    }
}

