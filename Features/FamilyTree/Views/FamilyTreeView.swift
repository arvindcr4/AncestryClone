import SwiftUI

enum TreeViewMode {
    case list
    case vertical
    case horizontal
    case fan
}

struct FamilyTreeView: View {
    @StateObject private var viewModel = FamilyTreeViewModel()
    @State private var showingAddPerson = false
    @State private var showingEditPerson = false
    @State private var selectedPerson: Person?
    @State private var viewMode: TreeViewMode = .vertical
    @State private var showingSidebar = true
    
    var body: some View {
        NavigationSplitView {
            sidebarContent
        } detail: {
            mainContent
        }
        .sheet(isPresented: $showingAddPerson) {
            AddPersonView(viewModel: viewModel)
        }
        .sheet(isPresented: $showingEditPerson) {
            if let person = selectedPerson {
                EditPersonView(person: person, viewModel: viewModel)
            }
        }
        .onAppear {
            viewModel.fetchPeople()
        }
    }
    
    private var sidebarContent: some View {
        List(selection: $selectedPerson) {
            if viewModel.isLoading {
                ProgressView()
            } else {
                ForEach(viewModel.people, id: \.id) { person in
                    PersonRowView(person: person)
                        .tag(person)
                }
            }
        }
        .searchable(text: $viewModel.searchText, prompt: "Search people")
        .navigationTitle("Family Tree")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { showingAddPerson = true }) {
                    Label("Add Person", systemImage: "person.badge.plus")
                }
            }
        }
    }
    
    private var mainContent: some View {
        Group {
            if let person = selectedPerson {
                VStack(spacing: 0) {
                    viewModeSelector
                    
                    switch viewMode {
                    case .list:
                        PersonDetailView(person: person, viewModel: viewModel)
                    case .vertical:
                        TreeCanvasView(
                            person: person,
                            selectedPerson: $selectedPerson,
                            viewModel: viewModel,
                            orientation: .vertical
                        )
                    case .horizontal:
                        TreeCanvasView(
                            person: person,
                            selectedPerson: $selectedPerson,
                            viewModel: viewModel,
                            orientation: .horizontal
                        )
                    case .fan:
                        Text("Fan chart view coming soon")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color(UIColor.systemGroupedBackground))
                    }
                }
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        HStack {
                            Button(action: { showingSidebar.toggle() }) {
                                Label("Toggle Sidebar", systemImage: "sidebar.right")
                            }
                            
                            Menu {
                                Button("Edit") {
                                    showingEditPerson = true
                                }
                                Button("Share", action: { /* Handle share */ })
                                Button("Delete", role: .destructive) {
                                    viewModel.deletePerson(person)
                                    selectedPerson = nil
                                }
                            } label: {
                                Image(systemName: "ellipsis.circle")
                            }
                        }
                    }
                }
            } else {
                Text("Select a person to view their family tree")
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var viewModeSelector: some View {
        Picker("View Mode", selection: $viewMode) {
            Label("List", systemImage: "list.bullet")
                .tag(TreeViewMode.list)
            Label("Vertical", systemImage: "arrow.up.and.down")
                .tag(TreeViewMode.vertical)
            Label("Horizontal", systemImage: "arrow.left.and.right")
                .tag(TreeViewMode.horizontal)
            Label("Fan", systemImage: "dial.min")
                .tag(TreeViewMode.fan)
        }
        .pickerStyle(.segmented)
        .padding()
        .labelsHidden()
    }
}

struct PersonRowView: View {
    let person: Person
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(person.fullName)
                .font(.headline)
            if let birthDate = person.birthDate {
                Text(birthDate, style: .date)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            if let birthPlace = person.birthPlace {
                Text(birthPlace)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct FamilyTreeView_Previews: PreviewProvider {
    static var previews: some View {
        FamilyTreeView()
            .environment(\.managedObjectContext, CoreDataStack.shared.viewContext)
    }
}

