import SwiftUI

struct TreeNodeView: View {
    let person: Person
    var isSelected: Bool
    var isTablet: Bool = false
    var onTap: () -> Void
    
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var isPressed = false
    
    // For haptic feedback
    private let feedbackGenerator = UIImpactFeedbackGenerator(style: .medium)
    
    var body: some View {
        // Use local variable or environment value for size determination
        let isIpad = isTablet || horizontalSizeClass == .regular
        
        VStack(spacing: isIpad ? 8 : 4) {
            // Photo/Avatar if available
            if isIpad, let photoData = person.photoData, let uiImage = UIImage(data: photoData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 50, height: 50)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.gray, lineWidth: 1))
            } else {
                Image(systemName: "person.fill")
                    .font(.system(size: isIpad ? 24 : 18))
                    .foregroundColor(.secondary)
                    .frame(width: isIpad ? 40 : 30, height: isIpad ? 40 : 30)
            }
            
            Text(person.fullName)
                .font(.system(size: isIpad ? 16 : 14, weight: .medium))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
            
            if let birthDate = person.birthDate {
                Text(birthDate, style: .date)
                    .font(.system(size: isIpad ? 14 : 12))
                    .foregroundColor(.secondary)
            }
            
            if isIpad, let age = calculateAge() {
                Text("\(age) years")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(width: isIpad ? 160 : 120, height: isIpad ? 120 : 60)
        .padding(isIpad ? 12 : 8)
        .background(Color(UIColor.systemBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color.accentColor : Color.gray, lineWidth: isSelected ? 3 : 1)
        )
        .shadow(color: isSelected ? Color.accentColor.opacity(0.4) : Color.black.opacity(0.2), 
                radius: isSelected ? 5 : 2, x: 0, y: 2)
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
        // Make the hit target larger
        .contentShape(Rectangle())
        // Gesture handling with haptic feedback
        .onTapGesture {
            feedbackGenerator.prepare()
            feedbackGenerator.impactOccurred()
            onTap()
        }
        .onLongPressGesture(minimumDuration: 0.5, pressing: { isPressing in
            self.isPressed = isPressing
            if isPressing {
                feedbackGenerator.impactOccurred(intensity: 0.8)
            }
        }) {
            // Long press action
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
        // Context menu for quick actions
        .contextMenu {
            Button(action: {
                onTap()
            }) {
                Label("View Details", systemImage: "person.text.rectangle")
            }
            
            Button(action: {
                // Edit action would go here
            }) {
                Label("Edit", systemImage: "pencil")
            }
            
            Button(action: {
                // Add child action
            }) {
                Label("Add Child", systemImage: "person.badge.plus")
            }
            
            Button(action: {
                // Add parent action
            }) {
                Label("Add Parent", systemImage: "arrow.up.to.line")
            }
            
            Divider()
            
            Button(role: .destructive, action: {
                // Delete action
            }) {
                Label("Delete", systemImage: "trash")
            }
        }
        // Accessibility improvements
        .accessibility(label: Text("\(person.fullName), \(getAccessibilityAgeText())"))
        .accessibility(hint: Text("Double tap to view details. Long press for more options."))
        .accessibility(addTraits: .isButton)
        .accessibilityAction {
            onTap()
        }
    }
    
    // Helper function to calculate age
    private func calculateAge() -> Int? {
        guard let birthDate = person.birthDate else { return nil }
        
        let calendar = Calendar.current
        let ageComponents = calendar.dateComponents([.year], from: birthDate, to: Date())
        return ageComponents.year
    }
    
    // Helper function for accessibility
    private func getAccessibilityAgeText() -> String {
        if let birthDate = person.birthDate {
            if let age = calculateAge() {
                return "\(age) years old"
            } else {
                return "Born on \(DateFormatter.localizedString(from: birthDate, dateStyle: .medium, timeStyle: .none))"
            }
        } else if let birthPlace = person.birthPlace {
            return "Born in \(birthPlace)"
        }
        return "No birth information available"
    }
}

// Preview for the TreeNodeView
struct TreeNodeView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // iPhone preview
            TreeNodeView(
                person: createSamplePerson(),
                isSelected: false,
                onTap: {}
            )
            .previewLayout(.sizeThatFits)
            .padding()
            .previewDisplayName("iPhone - Normal")
            
            // iPhone Selected preview
            TreeNodeView(
                person: createSamplePerson(),
                isSelected: true,
                onTap: {}
            )
            .previewLayout(.sizeThatFits)
            .padding()
            .previewDisplayName("iPhone - Selected")
            
            // iPad preview
            TreeNodeView(
                person: createSamplePerson(),
                isSelected: false,
                isTablet: true,
                onTap: {}
            )
            .previewLayout(.sizeThatFits)
            .padding()
            .previewDisplayName("iPad - Normal")
            
            // iPad Selected preview
            TreeNodeView(
                person: createSamplePerson(),
                isSelected: true,
                isTablet: true,
                onTap: {}
            )
            .previewLayout(.sizeThatFits)
            .padding()
            .previewDisplayName("iPad - Selected")
        }
    }
    
    // Helper function to create a sample person for previews
    static func createSamplePerson() -> Person {
        let context = PersistenceController.preview.container.viewContext
        let person = Person(context: context)
        person.id = UUID()
        person.firstName = "John"
        person.lastName = "Smith"
        person.birthDate = Calendar.current.date(byAdding: .year, value: -45, to: Date())
        person.birthPlace = "New York, NY"
        return person
    }
}

