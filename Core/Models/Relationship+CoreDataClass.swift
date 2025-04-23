import Foundation
import CoreData

@objc(Relationship)
public class Relationship: NSManagedObject {
    func addSource(_ source: Source) {
        addToSources(source)
    }
}

