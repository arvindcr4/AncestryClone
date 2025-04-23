import Foundation
import CoreData

extension Relationship {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Relationship> {
        return NSFetchRequest<Relationship>(entityName: "Relationship")
    }

    @NSManaged public var id: UUID
    @NSManaged public var type: String
    @NSManaged public var createdAt: Date
    @NSManaged public var updatedAt: Date
    @NSManaged public var person: Person
    @NSManaged public var relatedPerson: Person
    @NSManaged public var sources: Set<Source>
}

// MARK: Generated accessors for sources
extension Relationship {
    @objc(addSourcesObject:)
    @NSManaged public func addToSources(_ value: Source)

    @objc(removeSourcesObject:)
    @NSManaged public func removeFromSources(_ value: Source)

    @objc(addSources:)
    @NSManaged public func addToSources(_ values: NSSet)

    @objc(removeSources:)
    @NSManaged public func removeFromSources(_ values: NSSet)
}

