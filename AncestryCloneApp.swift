import SwiftUI

@main
struct AncestryCloneApp: App {
    @StateObject private var appState = AppState()
    @State private var zoomScale: CGFloat = 1.0
    @State private var viewMode: TreeViewMode = .vertical
    let coreDataStack = CoreDataStack.shared
    
    var body: some Scene {
        WindowGroup {
            // Use a conditional view for iPad vs iPhone
            Group {
                if UIDevice.current.userInterfaceIdiom == .pad {
                    FamilyTreeView()
                        .environment(\.managedObjectContext, coreDataStack.viewContext)
                        .environment(\.zoomScale, $zoomScale)
                        .environment(\.treeViewMode, $viewMode)
                } else {
                    NavigationView {
                        FamilyTreeView()
                            .environment(\.managedObjectContext, coreDataStack.viewContext)
                    }
                    .navigationViewStyle(.stack)
                }
            }
            .environmentObject(appState)
            // Handle URL scheme for sharing
            .onOpenURL { url in
                handleIncomingURL(url)
            }
        }
        
        // Add keyboard shortcuts for iPad users
        .commands {
            TreeNavigationCommands(zoomScale: $zoomScale, viewMode: $viewMode)
            SidebarCommands() // Built-in commands for showing/hiding sidebar
        }
    }
    
    private func handleIncomingURL(_ url: URL) {
        // Handle deep linking for shared trees or relationships
        // Implementation to be added later
    }
}

// Application state management
class AppState: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: Person?
    @Published var selectedTree: UUID?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // iPad-specific state
    @Published var isMultiWindowSupported = UIDevice.current.userInterfaceIdiom == .pad
    @Published var useCompactLayout = false
    
    func showError(_ message: String) {
        errorMessage = message
        // Auto-dismiss after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.errorMessage = nil
        }
    }
}

// Extension for error handling
extension View {
    func handleError(_ error: Binding<String?>) -> some View {
        self.modifier(ErrorAlert(error: error))
    }
}

// Error alert modifier
struct ErrorAlert: ViewModifier {
    @Binding var error: String?
    
    func body(content: Content) -> some View {
        content
            .alert("Error", isPresented: .constant(error != nil)) {
                Button("OK") {
                    error = nil
                }
            } message: {
                if let error = error {
                    Text(error)
                }
            }
    }
}

// Environment keys for tree visualization state
struct ZoomScaleKey: EnvironmentKey {
    static let defaultValue: Binding<CGFloat> = .constant(1.0)
}

struct TreeViewModeKey: EnvironmentKey {
    static let defaultValue: Binding<TreeViewMode> = .constant(.vertical)
}

extension EnvironmentValues {
    var zoomScale: Binding<CGFloat> {
        get { self[ZoomScaleKey.self] }
        set { self[ZoomScaleKey.self] = newValue }
    }
    
    var treeViewMode: Binding<TreeViewMode> {
        get { self[TreeViewModeKey.self] }
        set { self[TreeViewModeKey.self] = newValue }
    }
}

// Keyboard commands implementation
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
        
        CommandMenu("Family Tree") {
            Button("Add Person") {
                NotificationCenter.default.post(name: .addPersonRequested, object: nil)
            }
            .keyboardShortcut("n", modifiers: [.command])
            
            Button("Add Relationship") {
                NotificationCenter.default.post(name: .addRelationshipRequested, object: nil)
            }
            .keyboardShortcut("r", modifiers: [.command])
            
            Divider()
            
            Button("Export Tree") {
                NotificationCenter.default.post(name: .exportTreeRequested, object: nil)
            }
            .keyboardShortcut("e", modifiers: [.command, .shift])
            
            Button("Import Tree") {
                NotificationCenter.default.post(name: .importTreeRequested, object: nil)
            }
            .keyboardShortcut("i", modifiers: [.command, .shift])
        }
    }
}

// Notification names for command actions
extension Notification.Name {
    static let addPersonRequested = Notification.Name("addPersonRequested")
    static let addRelationshipRequested = Notification.Name("addRelationshipRequested")
    static let exportTreeRequested = Notification.Name("exportTreeRequested")
    static let importTreeRequested = Notification.Name("importTreeRequested")
}
