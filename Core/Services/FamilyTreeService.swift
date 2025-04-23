import Foundation
import CoreData
import Combine

class FamilyTreeService {
    private let coreDataStack: CoreDataStack
    
    init(coreDataStack: CoreDataStack = .shared) {
        self.coreDataStack = coreDataStack
    }
    
    // MARK: - Person Operations
    
    func createPerson(firstName: String, lastName: String, gender: String, isLiving: Bool) -> Person {
        let context = coreDataStack.viewContext
        let person = Person(context: context)
        person.id = UUID()
        person.firstName = firstName
        person.lastName = lastName
        person.gender = gender
        person.isLiving = isLiving
        person.createdAt = Date()
        person.updatedAt = Date()
        
        coreDataStack.saveContext()
        return person
    }
    
    func updatePerson(_ person: Person, firstName: String? = nil, lastName: String? = nil,
                     birthDate: Date? = nil, birthPlace: String? = nil,
                     deathDate: Date? = nil, deathPlace: String? = nil,
                     gender: String? = nil, notes: String? = nil) {
        
        if let firstName = firstName { person.firstName = firstName }
        if let lastName = lastName { person.lastName = lastName }
        if let birthDate = birthDate { person.birthDate = birthDate }
        if let birthPlace = birthPlace { person.birthPlace = birthPlace }
        if let deathDate = deathDate { person.deathDate = deathDate }
        if let deathPlace = deathPlace { person.deathPlace = deathPlace }
        if let gender = gender { person.gender = gender }
        if let notes = notes { person.notes = notes }
        
        person.updatedAt = Date()
        coreDataStack.saveContext()
    }
    
    func deletePerson(_ person: Person) {
        coreDataStack.delete(person)
    }
    
    // MARK: - Relationship Operations
    
    func createRelationship(type: String, person: Person, relatedPerson: Person) -> Relationship {
        let context = coreDataStack.viewContext
        
        // Validate relationship
        guard validateRelationship(type: type, between: person, and: relatedPerson) else {
            throw FamilyTreeError.invalidRelationship
        }
        
        // Check for existing relationship
        if let existingRelationship = findExistingRelationship(between: person, and: relatedPerson) {
            return existingRelationship
        }
        
        // Create new relationship
        let relationship = Relationship(context: context)
        relationship.id = UUID()
        relationship.type = type
        relationship.person = person
        relationship.relatedPerson = relatedPerson
        relationship.createdAt = Date()
        relationship.updatedAt = Date()
        
        // Create reciprocal relationship
        let reciprocalType = getReciprocalRelationType(type)
        let reciprocalRelationship = Relationship(context: context)
        reciprocalRelationship.id = UUID()
        reciprocalRelationship.type = reciprocalType
        reciprocalRelationship.person = relatedPerson
        reciprocalRelationship.relatedPerson = person
        reciprocalRelationship.createdAt = Date()
        reciprocalRelationship.updatedAt = Date()
        
        coreDataStack.saveContext()
        return relationship
    }
    
    func deleteRelationship(_ relationship: Relationship) {
        let context = coreDataStack.viewContext
        
        // Find and delete reciprocal relationship
        let reciprocalRelationships = relationship.relatedPerson.relationships.filter {
            $0.relatedPerson.id == relationship.person.id
        }
        
        for reciprocal in reciprocalRelationships {
            context.delete(reciprocal)
        }
        
        context.delete(relationship)
        coreDataStack.saveContext()
    }
    
    // MARK: - Relationship Helpers
    
    private func findExistingRelationship(between person1: Person, and person2: Person) -> Relationship? {
        return person1.relationships.first { relationship in
            relationship.relatedPerson.id == person2.id
        }
    }
    
    private func validateRelationship(type: String, between person1: Person, and person2: Person) -> Bool {
        // Prevent self-relationships
        if person1.id == person2.id {
            return false
        }
        
        // Validate based on relationship type
        switch type {
        case "Parent":
            // Parent must be older than child
            if let parentBirth = person1.birthDate, let childBirth = person2.birthDate {
                return parentBirth < childBirth
            }
            // If birth dates aren't available, allow the relationship
            return true
            
        case "Child":
            // Child must be younger than parent
            if let childBirth = person1.birthDate, let parentBirth = person2.birthDate {
                return childBirth > parentBirth
            }
            return true
            
        case "Spouse":
            // Check for existing spouse relationships (uncommenting would limit to one spouse)
            // let existingSpouses = person1.relationships.filter { $0.type == "Spouse" }
            // let person2ExistingSpouses = person2.relationships.filter { $0.type == "Spouse" }
            
            // if !existingSpouses.isEmpty || !person2ExistingSpouses.isEmpty {
            //     return false
            // }
            return true
            
        case "Sibling":
            // Optional: Validate shared parents if parent relationships exist
            return true
            
        default:
            return true
        }
    }
    
    private func getReciprocalRelationType(_ type: String) -> String {
        switch type {
        case "Parent": return "Child"
        case "Child": return "Parent"
        case "Spouse": return "Spouse"
        case "Sibling": return "Sibling"
        default: return type
        }
    }
    
    // MARK: - Event Operations
    
    func createEvent(type: String, date: Date?, place: String?, description: String, person: Person) -> Event {
        let context = coreDataStack.viewContext
        let event = Event(context: context)
        event.id = UUID()
        event.type = type
        event.date = date
        event.place = place
        event.eventDescription = description
        event.person = person
        event.createdAt = Date()
        event.updatedAt = Date()
        
        coreDataStack.saveContext()
        return event
    }
    
    // MARK: - Media Operations
    
    func createMedia(type: String, url: String, caption: String?, date: Date?) -> Media {
        let context = coreDataStack.viewContext
        let media = Media(context: context)
        media.id = UUID()
        media.type = type
        media.url = url
        media.caption = caption
        media.date = date
        media.createdAt = Date()
        media.updatedAt = Date()
        
        coreDataStack.saveContext()
        return media
    }
    
    // MARK: - Source Operations
    
    func createSource(type: String, title: String, citation: String, url: String?, notes: String?) -> Source {
        let context = coreDataStack.viewContext
        let source = Source(context: context)
        source.id = UUID()
        source.type = type
        source.title = title
        source.citation = citation
        source.url = url
        source.notes = notes
        source.createdAt = Date()
        source.updatedAt = Date()
        
        coreDataStack.saveContext()
        return source
    }
    
    // MARK: - Fetch Operations
    
    func fetchPeople(searchTerm: String? = nil) -> [Person] {
        var predicate: NSPredicate?
        if let searchTerm = searchTerm, !searchTerm.isEmpty {
            predicate = NSPredicate(format: "firstName CONTAINS[cd] %@ OR lastName CONTAINS[cd] %@", 
                                  searchTerm, searchTerm)
        }
        return coreDataStack.fetch(Person.self, predicate: predicate, 
                                 sortDescriptors: [NSSortDescriptor(key: "lastName", ascending: true)])
    }
}

// MARK: - Error Types

enum FamilyTreeError: LocalizedError {
    case invalidRelationship
    case duplicateRelationship
    case invalidData
    
    var errorDescription: String? {
        switch self {
        case .invalidRelationship:
            return "Invalid relationship: The relationship cannot be created between these people."
        case .duplicateRelationship:
            return "A relationship already exists between these people."
        case .invalidData:
            return "Invalid data: Please check the entered information."
        }
    }
}
}

