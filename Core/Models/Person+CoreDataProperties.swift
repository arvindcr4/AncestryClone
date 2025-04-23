import Foundation
import CoreData

extension Person {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Person> {
        return NSFetchRequest<Person>(entityName: "Person")
    }

    @NSManaged public var id: UUID
    @NSManaged public var firstName: String?
    @NSManaged public var lastName: String?
    @NSManaged public var birthDate: Date?
    @NSManaged public var birthPlace: String?
    @NSManaged public var deathDate: Date?
    @NSManaged public var deathPlace: String?
    @NSManaged public var gender: String?
    @NSManaged public var isLiving: Bool
    @NSManaged public var notes: String?
    @NSManaged public var createdAt: Date
    @NSManaged public var updatedAt: Date
    @NSManaged public var relationships: Set<Relationship>
    @NSManaged public var events: Set<Event>
    @NSManaged public var media: Set<Media>
    @NSManaged public var sources: Set<Source>
}

// MARK: Generated accessors for relationships
extension Person {
    @objc(addRelationshipsObject:)
    @NSManaged public func addToRelationships(_ value: Relationship)

    @objc(removeRelationshipsObject:)
    @NSManaged public func removeFromRelationships(_ value: Relationship)

    @objc(addRelationships:)
    @NSManaged public func addToRelationships(_ values: NSSet)

    @objc(removeRelationships:)
    @NSManaged public func removeFromRelationships(_ values: NSSet)
}

// MARK: Generated accessors for events
extension Person {
    @objc(addEventsObject:)
    @NSManaged public func addToEvents(_ value: Event)

    @objc(removeEventsObject:)
    @NSManaged public func removeFromEvents(_ value: Event)

    @objc(addEvents:)
    @NSManaged public func addToEvents(_ values: NSSet)

    @objc(removeEvents:)
    @NSManaged public func removeFromEvents(_ values: NSSet)
}

// MARK: Generated accessors for media
extension Person {
    @objc(addMediaObject:)
    @NSManaged public func addToMedia(_ value: Media)

    @objc(removeMediaObject:)
    @NSManaged public func removeFromMedia(_ value: Media)

    @objc(addMedia:)
    @NSManaged public func addToMedia(_ values: NSSet)

    @objc(removeMedia:)
    @NSManaged public func removeFromMedia(_ values: NSSet)
}

// MARK: Generated accessors for sources
extension Person {
    @objc(addSourcesObject:)
    @NSManaged public func addToSources(_ value: Source)

    @objc(removeSourcesObject:)
    @NSManaged public func removeFromSources(_ value: Source)

    @objc(addSources:)
    @NSManaged public func addToSources(_ values: NSSet)

    @objc(removeSources:)
    @NSManaged public func removeFromSources(_ values: NSSet)
}

