import SwiftUI

struct EditPersonView: View {
    let person: Person
    @ObservedObject var viewModel: FamilyTreeViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var firstName: String
    @State private var lastName: String
    @State private var gender: String
    @State private var isLiving: Bool
    @State private var birthDate: Date?
    @State private var birthPlace: String
    @State private var notes: String
    @State private var showingAlert = false
    @State private var errorMessage = ""
    
    let genderOptions = ["Male", "Female", "Other", "Unknown"]
    
    init(person: Person, viewModel: FamilyTreeViewModel) {
        self.person = person
        self.viewModel = viewModel
        _firstName = State(initialValue: person.firstName ?? "")
        _lastName = State(initialValue: person.lastName ?? "")
        _gender = State(initialValue: person.gender ?? "Unknown")
        _isLiving = State(initialValue: person.isLiving)
        _birthDate = State(initialValue: person.birthDate)
        _birthPlace = State(initialValue: person.birthPlace ?? "")
        _notes = State(initialValue: person.notes ?? "")
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Basic Information")) {
                    TextField("First Name", text: $firstName)
                        .textContentType(.givenName)
                    TextField("Last Name", text: $lastName)
                        .textContentType(.familyName)
                    Picker("Gender", selection: $gender) {
                        ForEach(genderOptions, id: \.self) {
                            Text($0)
                        }
                    }
                    Toggle("Is Living", isOn: $isLiving)
                }
                
                Section(header: Text("Birth Information")) {
                    Toggle("Has Birth Date", isOn: Binding(
                        get: { birthDate != nil },
                        set: { if !$0 { birthDate = nil } }
                    ))
                    if birthDate != nil {
                        DatePicker(
                            "Birth Date",
                            selection: Binding(
                                get: { birthDate ?? Date() },
                                set: { birthDate = $0 }
                            ),
                            displayedComponents: [.date]
                        )
                    }
                    TextField("Birth Place", text: $birthPlace)
                }
                
                Section(header: Text("Additional Information")) {
                    TextEditor(text: $notes)
                        .frame(height: 100)
                }
            }
            .navigationTitle("Edit Person")
            .navigationBarItems(
                leading: Button("Cancel") { dismiss() },
                trailing: Button("Save") { savePerson() }
            )
            .alert("Error", isPresented: $showingAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func savePerson() {
        do {
            viewModel.updatePerson(
                person,
                firstName: firstName,
                lastName: lastName,
                birthDate: birthDate,
                birthPlace: birthPlace,
                gender: gender,
                notes: notes
            )
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            showingAlert = true
        }
    }
}

