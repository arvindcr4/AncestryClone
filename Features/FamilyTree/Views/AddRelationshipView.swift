import SwiftUI

struct AddRelationshipView: View {
    let person: Person
    @ObservedObject var viewModel: FamilyTreeViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedPerson: Person?
    @State private var relationType = "Parent"
    @State private var searchText = ""
    @State private var showingAlert = false
    @State private var errorMessage = ""
    
    let relationshipTypes = ["Parent", "Child", "Spouse", "Sibling"]
    
    var filteredPeople: [Person] {
        let otherPeople = viewModel.people.filter { $0.id != person.id }
        if searchText.isEmpty {
            return otherPeople
        }
        return otherPeople.filter {
            $0.fullName.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Relationship Type")) {
                    Picker("Type", selection: $relationType) {
                        ForEach(relationshipTypes, id: \.self) {
                            Text($0)
                        }
                    }
                }
                
                Section(header: Text("Select Person")) {
                    ForEach(filteredPeople, id: \.id) { person in
                        Button(action: { selectedPerson = person }) {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(person.fullName)
                                        .font(.body)
                                    if let birthDate = person.birthDate {
                                        Text(birthDate, style: .date)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                Spacer()
                                if selectedPerson?.id == person.id {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.accentColor)
                                }
                            }
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search people")
            .navigationTitle("Add Relationship")
            .navigationBarItems(
                leading: Button("Cancel") { dismiss() },
                trailing: Button("Save") {
                    saveRelationship()
                }
                .disabled(selectedPerson == nil)
            )
            .alert("Error", isPresented: $showingAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func saveRelationship() {
        guard let selectedPerson = selectedPerson else { return }
        
        do {
            viewModel.createRelationship(
                type: relationType,
                person: person,
                relatedPerson: selectedPerson
            )
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            showingAlert = true
        }
    }
}

