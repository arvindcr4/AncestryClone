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
    @State private var zoomScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    
    // For iPad specific UI adjustments
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    var body: some View {
        NavigationSplitView {
            sidebarContent
        } detail: {
            mainContent
        }
        .navigationSplitViewStyle(horizontalSizeClass == .regular ? .balanced : .automatic)
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
            
            // iPad specific toolbar items
            if horizontalSizeClass == .regular {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { 
                        // Import functionality
                    }) {
                        Label("Import", systemImage: "square.and.arrow.down")
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { 
                        // Export functionality
                    }) {
                        Label("Export", systemImage: "square.and.arrow.up")
                    }
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
                        ZoomableTreeView {
                            TreeCanvasView(
                                person: person,
                                selectedPerson: $selectedPerson,
                                viewModel: viewModel,
                                orientation: .vertical
                            )
                        }
                    case .horizontal:
                        ZoomableTreeView {
                            TreeCanvasView(
                                person: person,
                                selectedPerson: $selectedPerson,
                                viewModel: viewModel,
                                orientation: .horizontal
                            )
                        }
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
        Group {
            if horizontalSizeClass == .regular {
                // More spacious layout for iPad
                HStack(spacing: 12) {
                    ForEach([
                        (TreeViewMode.list, "List", "list.bullet"),
                        (TreeViewMode.vertical, "Vertical", "arrow.up.and.down"),
                        (TreeViewMode.horizontal, "Horizontal", "arrow.left.and.right"),
                        (TreeViewMode.fan, "Fan Chart", "dial.min")
                    ], id: \.0) { mode, title, icon in
                        Button {
                            viewMode = mode
                        } label: {
                            VStack {
                                Image(systemName: icon)
                                    .font(.title2)
                                Text(title)
                                    .font(.caption)
                            }
                            .frame(width: 80, height: 60)
                            .background(viewMode == mode ? Color.accentColor.opacity(0.2) : Color.clear)
                            .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
            } else {
                // Compact layout for iPhone
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

// ZoomableTreeView for iPad support
struct ZoomableTreeView<Content: View>: View {
    let content: () -> Content
    
    @State private var zoomScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    @State private var lastZoomScale: CGFloat = 1.0
    
    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView([.horizontal, .vertical]) {
                content()
                    .frame(minWidth: geometry.size.width, minHeight: geometry.size.height)
                    .scaleEffect(zoomScale)
                    .offset(x: offset.width, y: offset.height)
                    .gesture(
                        MagnificationGesture()
                            .onChanged { value in
                                let delta = value / lastZoomScale
                                lastZoomScale = value
                                // Limit zoom scale to reasonable bounds
                                zoomScale = min(max(zoomScale * delta, 0.5), 3.0)
                            }
                            .onEnded { _ in
                                lastZoomScale = 1.0
                            }
                    )
                    .simultaneousGesture(
                        DragGesture(minimumDistance: 10)
                            .onChanged { value in
                                offset = CGSize(
                                    width: lastOffset.width + value.translation.width,
                                    height: lastOffset.height + value.translation.height
                                )
                            }
                            .onEnded { value in
                                lastOffset = offset
                            }
                    )
                    .onTapGesture(count: 2) {
                        // Double tap to reset zoom and position
                        withAnimation {
                            zoomScale = 1.0
                            offset = .zero
                            lastOffset = .zero
                        }
                    }
            }
            .coordinateSpace(name: "treeCanvas")
        }
    }
}

// Add keyboard shortcuts for iPad users with keyboards
struct TreeNavigationCommands: Commands {
    @Binding var zoomScale: CGFloat
    @Binding var viewMode: TreeViewMode
    
    var body: some Commands {
        CommandGroup(after: .sidebar) {
            Button("Zoom In") {
                zoomScale = min(zoomScale + 0.1, 3.0)
            }
            .keyboardShortcut("+", modifiers: .command)
            
            Button("Zoom Out") {
                zoomScale = max(zoomScale - 0.1, 0.5)
            }
            .keyboardShortcut("-", modifiers: .command)
            
            Button("Reset View") {
                zoomScale = 1.0
            }
            .keyboardShortcut("0", modifiers: .command)
            
            Divider()
            
            Button("List View") {
                viewMode = .list
            }
            .keyboardShortcut("1", modifiers: .command)
            
            Button("Vertical Tree") {
                viewMode = .vertical
            }
            .keyboardShortcut("2", modifiers: .command)
            
            Button("Horizontal Tree") {
                viewMode = .horizontal
            }
            .keyboardShortcut("3", modifiers: .command)
            
            Button("Fan Chart") {
                viewMode = .fan
            }
            .keyboardShortcut("4", modifiers: .command)
        }
    }
}

struct FamilyTreeView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            FamilyTreeView()
                .previewDevice(PreviewDevice(rawValue: "iPhone 14 Pro"))
                .previewDisplayName("iPhone 14 Pro")
            
            FamilyTreeView()
                .previewDevice(PreviewDevice(rawValue: "iPad Pro (12.9-inch) (6th generation)"))
                .previewDisplayName("iPad Pro 12.9-inch")
                .previewInterfaceOrientation(.landscapeLeft)
        }
        .environment(\.managedObjectContext, CoreDataStack.shared.viewContext)
    }
}
