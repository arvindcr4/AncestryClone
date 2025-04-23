import Foundation
import CoreData

@objc(Media)
public class Media: NSManagedObject {
    func addPerson(_ person: Person) {
        addToPersons(person)
    }
    
    func addEvent(_ event: Event) {
        addToEvents(event)
    }
}

