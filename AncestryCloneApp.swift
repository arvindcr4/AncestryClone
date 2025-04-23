import SwiftUI

@main
struct AncestryCloneApp: App {
    @StateObject private var appState = AppState()
    let coreDataStack = CoreDataStack.shared
    
    var body: some Scene {
        WindowGroup {
            NavigationView {
                FamilyTreeView()
                    .environment(\.managedObjectContext, coreDataStack.viewContext)
            }
            .navigationViewStyle(.stack)
            .environmentObject(appState)
            // Handle URL scheme for sharing
            .onOpenURL { url in
                handleIncomingURL(url)
            }
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

