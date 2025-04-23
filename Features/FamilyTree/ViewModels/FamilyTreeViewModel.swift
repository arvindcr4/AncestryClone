import Foundation
import Combine
import CoreData

class FamilyTreeViewModel: ObservableObject {
    private let familyTreeService: FamilyTreeService
    private var cancellables = Set<AnyCancellable>()
    
    @Published var people: [Person] = []
    @Published var searchText: String = ""
    @Published var isLoading = false
    @Published var error: Error?
    
    init(familyTreeService: FamilyTreeService = FamilyTreeService()) {
        self.familyTreeService = familyTreeService
        setupSearchSubscription()
    }
    
    private func setupSearchSubscription() {
        $searchText
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] searchTerm in
                self?.fetchPeople(searchTerm: searchTerm)
            }
            .store(in: &cancellables)
    }
    
    func fetchPeople(searchTerm: String? = nil) {
        isLoading = true
        people = familyTreeService.fetchPeople(searchTerm: searchTerm)
        isLoading = false
    }
    
    func addPerson(firstName: String, lastName: String, gender: String, isLiving: Bool) {
        _ = familyTreeService.createPerson(
            firstName: firstName,
            lastName: lastName,
            gender: gender,
            isLiving: isLiving
        )
        fetchPeople(searchTerm: searchText)
    }
    
    func updatePerson(_ person: Person, firstName: String? = nil, lastName: String? = nil,
                     birthDate: Date? = nil, birthPlace: String? = nil,
                     deathDate: Date? = nil, deathPlace: String? = nil,
                     gender: String? = nil, notes: String? = nil) {
        familyTreeService.updatePerson(
            person,
            firstName: firstName,
            lastName: lastName,
            birthDate: birthDate,
            birthPlace: birthPlace,
            deathDate: deathDate,
            deathPlace: deathPlace,
            gender: gender,
            notes: notes
        )
        fetchPeople(searchTerm: searchText)
    }
    
    func deletePerson(_ person: Person) {
        familyTreeService.deletePerson(person)
        fetchPeople(searchTerm: searchText)
    }
    
    // MARK: - Relationship Operations
    
    func createRelationship(type: String, person: Person, relatedPerson: Person) {
        _ = familyTreeService.createRelationship(
            type: type,
            person: person,
            relatedPerson: relatedPerson
        )
        fetchPeople(searchTerm: searchText)
    }
    
    func deleteRelationship(_ relationship: Relationship) {
        familyTreeService.deleteRelationship(relationship)
        fetchPeople(searchTerm: searchText)
    }
    
    func getRelationships(for person: Person) -> [Relationship] {
        Array(person.relationships).sorted { $0.type < $1.type }
    }
}

