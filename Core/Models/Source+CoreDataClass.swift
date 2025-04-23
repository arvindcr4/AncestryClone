import Foundation
import CoreData

@objc(Source)
public class Source: NSManagedObject {
    func addPerson(_ person: Person) {
        addToPersons(person)
    }
    
    func addEvent(_ event: Event) {
        addToEvents(event)
    }
    
    func addRelationship(_ relationship: Relationship) {
        addToRelationships(relationship)
    }
}

