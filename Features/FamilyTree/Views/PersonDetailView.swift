import SwiftUI

struct PersonDetailView: View {
    let person: Person
    @ObservedObject var viewModel: FamilyTreeViewModel
    @State private var isEditing = false
    @State private var showingDeleteAlert = false
    @State private var showingAddRelationship = false
    
    var body: some View {
        List {
            Section(header: Text("Personal Information")) {
                LabeledContent("Name", value: person.fullName)
                LabeledContent("Gender", value: person.gender ?? "Unknown")
                if let birthDate = person.birthDate {
                    LabeledContent("Birth Date") {
                        Text(birthDate, style: .date)
                    }
                }
                if let birthPlace = person.birthPlace {
                    LabeledContent("Birth Place", value: birthPlace)
                }
                LabeledContent("Living", value: person.isLiving ? "Yes" : "No")
                if let notes = person.notes {
                    LabeledContent("Notes", value: notes)
                }
            }
            
            Section(header: Text("Relationships")) {
                ForEach(Array(person.relationships), id: \.id) { relationship in
                    NavigationLink(destination: PersonDetailView(person: relationship.relatedPerson, viewModel: viewModel)) {
                        VStack(alignment: .leading) {
                            Text(relationship.type)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(relationship.relatedPerson.fullName)
                                .font(.body)
                        }
                    }
                }
                Button(action: { showingAddRelationship = true }) {
                    Label("Add Relationship", systemImage: "person.badge.plus")
                }
            }
            
            Section(header: Text("Events")) {
                ForEach(Array(person.events), id: \.id) { event in
                    VStack(alignment: .leading) {
                        Text(event.type)
                            .font(.headline)
                        if let date = event.date {
                            Text(date, style: .date)
                                .font(.subheadline)
                        }
                        if let place = event.place {
                            Text(place)
                                .font(.caption)
                        }
                        Text(event.eventDescription)
                            .font(.body)
                            .padding(.top, 2)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle(person.fullName)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button("Edit", action: { isEditing = true })
                    Button("Delete", role: .destructive) {
                        showingDeleteAlert = true
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $isEditing) {
            EditPersonView(person: person, viewModel: viewModel)
        }
        .sheet(isPresented: $showingAddRelationship) {
            AddRelationshipView(person: person, viewModel: viewModel)
        }
        .alert("Delete Person", isPresented: $showingDeleteAlert) {
            Button("Delete", role: .destructive) {
                viewModel.deletePerson(person)
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to delete \(person.fullName)? This action cannot be undone.")
        }
    }
}

