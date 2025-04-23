import Foundation
import CoreData

extension Source {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Source> {
        return NSFetchRequest<Source>(entityName: "Source")
    }

    @NSManaged public var id: UUID
    @NSManaged public var type: String
    @NSManaged public var title: String
    @NSManaged public var citation: String
    @NSManaged public var url: String?
    @NSManaged public var notes: String?
    @NSManaged public var createdAt: Date
    @NSManaged public var updatedAt: Date
    @NSManaged public var persons: Set<Person>
    @NSManaged public var events: Set<Event>
    @NSManaged public var relationships: Set<Relationship>
    @NSManaged public var media: Media?
}

// MARK: Generated accessors for persons
extension Source {
    @objc(addPersonsObject:)
    @NSManaged public func addToPersons(_ value: Person)

    @objc(removePersonsObject:)
    @NSManaged public func removeFromPersons(_ value: Person)

    @objc(addPersons:)
    @NSManaged public func addToPersons(_ values: NSSet)

    @objc(removePersons:)
    @NSManaged public func removeFromPersons(_ values: NSSet)
}

// MARK: Generated accessors for events
extension Source {
    @objc(addEventsObject:)
    @NSManaged public func addToEvents(_ value: Event)

    @objc(removeEventsObject:)
    @NSManaged public func removeFromEvents(_ value: Event)

    @objc(addEvents:)
    @NSManaged public func addToEvents(_ values: NSSet)

    @objc(removeEvents:)
    @NSManaged public func removeFromEvents(_ values: NSSet)
}

// MARK: Generated accessors for relationships
extension Source {
    @objc(addRelationshipsObject:)
    @NSManaged public func addToRelationships(_ value: Relationship)

    @objc(removeRelationshipsObject:)
    @NSManaged public func removeFromRelationships(_ value: Relationship)

    @objc(addRelationships:)
    @NSManaged public func addToRelationships(_ values: NSSet)

    @objc(removeRelationships:)
    @NSManaged public func removeFromRelationships(_ values: NSSet)
}

