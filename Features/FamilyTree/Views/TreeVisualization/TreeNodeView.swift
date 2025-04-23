import SwiftUI

struct TreeNodeView: View {
    let person: Person
    var isSelected: Bool
    var onTap: () -> Void
    
    var body: some View {
        VStack(spacing: 4) {
            Text(person.fullName)
                .font(.system(size: 14, weight: .medium))
                .multilineTextAlignment(.center)
                .lineLimit(2)
            
            if let birthDate = person.birthDate {
                Text(birthDate, style: .date)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
        }
        .frame(width: 120, height: 60)
        .padding(8)
        .background(Color(UIColor.systemBackground))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isSelected ? Color.accentColor : Color.gray, lineWidth: isSelected ? 2 : 1)
        )
        .shadow(radius: isSelected ? 3 : 1)
        .onTapGesture(perform: onTap)
    }
}

