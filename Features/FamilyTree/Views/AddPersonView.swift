import SwiftUI

struct AddPersonView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: FamilyTreeViewModel
    
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var gender = "Unknown"
    @State private var isLiving = true
    @State private var birthDate = Date()
    @State private var birthPlace = ""
    @State private var showingAlert = false
    @State private var errorMessage = ""
    
    let genderOptions = ["Male", "Female", "Other", "Unknown"]
    
    var isValid: Bool {
        !firstName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !lastName.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Basic Information")) {
                    TextField("First Name", text: $firstName)
                        .textContentType(.givenName)
                        .autocapitalization(.words)
                    
                    TextField("Last Name", text: $lastName)
                        .textContentType(.familyName)
                        .autocapitalization(.words)
                    
                    Picker("Gender", selection: $gender) {
                        ForEach(genderOptions, id: \.self) {
                            Text($0)
                        }
                    }
                    
                    Toggle("Is Living", isOn: $isLiving)
                }
                
                Section(header: Text("Birth Information")) {
                    DatePicker(
                        "Birth Date",
                        selection: $birthDate,
                        displayedComponents: [.date]
                    )
                    
                    TextField("Birth Place", text: $birthPlace)
                        .textContentType(.location)
                }
            }
            .navigationTitle("Add Person")
            .navigationBarItems(
                leading: Button("Cancel") { dismiss() },
                trailing: Button("Save") {
                    savePerson()
                }
                .disabled(!isValid)
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
            viewModel.addPerson(
                firstName: firstName.trimmingCharacters(in: .whitespaces),
                lastName: lastName.trimmingCharacters(in: .whitespaces),
                gender: gender,
                isLiving: isLiving
            )
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            showingAlert = true
        }
    }
}

struct AddPersonView_Previews: PreviewProvider {
    static var previews: some View {
        AddPersonView(viewModel: FamilyTreeViewModel())
    }
}

