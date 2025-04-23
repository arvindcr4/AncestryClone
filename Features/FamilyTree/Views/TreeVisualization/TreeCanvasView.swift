import SwiftUI

struct TreeCanvasView: View {
    let person: Person
    @Binding var selectedPerson: Person?
    @ObservedObject var viewModel: FamilyTreeViewModel
    
    @State private var scale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastScale: CGFloat = 1.0
    @State private var lastOffset: CGSize = .zero
    @State private var showingPersonDetail = false
    
    var body: some View {
        GeometryReader { geometry in
            let magnification = MagnificationGesture()
                .onChanged { value in
                    let delta = value / lastScale
                    lastScale = value
                    scale *= delta
                }
                .onEnded { _ in
                    lastScale = 1.0
                }
            
            let drag = DragGesture()
                .onChanged { value in
                    offset = CGSize(
                        width: lastOffset.width + value.translation.width,
                        height: lastOffset.height + value.translation.height
                    )
                }
                .onEnded { _ in
                    lastOffset = offset
                }
            
            ZStack {
                Canvas { context, size in
                    context.translateBy(x: offset.width, y: offset.height)
                    context.scaleBy(x: scale, y: scale)
                    drawTree(context: context, in: size, for: person)
                }
                
                // Interactive nodes layer
                ForEach(getVisiblePeople(), id: \.id) { person in
                    TreeNodeView(
                        person: person,
                        isSelected: selectedPerson?.id == person.id,
                        onTap: {
                            selectedPerson = person
                            showingPersonDetail = true
                        }
                    )
                    .position(getNodePosition(for: person, in: geometry.size))
                }
            }
            .gesture(SimultaneousGesture(magnification, drag))
            .sheet(isPresented: $showingPersonDetail) {
                if let selected = selectedPerson {
                    PersonDetailView(person: selected, viewModel: viewModel)
                }
            }
        }
        .navigationTitle("Family Tree")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Reset") {
                    withAnimation {
                        scale = 1.0
                        offset = .zero
                        lastOffset = .zero
                    }
                }
            }
        }
    }
    
    private func drawTree(context: GraphicsContext, in size: CGSize, for person: Person) {
        let centerX = size.width / 2
        let centerY = size.height / 2
        let nodeSize = CGSize(width: 120, height: 60)
        
        // Only draw connection lines in the Canvas, nodes will be drawn as interactive SwiftUI views
        
        // Draw parents
        let parentRelationships = person.relationships.filter { $0.type == "Parent" }
        let parentSpacing = nodeSize.width * 1.5
        let parentY = centerY - nodeSize.height * 2
        
        for (index, relationship) in parentRelationships.enumerated() {
            let parentX = centerX + (CGFloat(index - parentRelationships.count / 2) * parentSpacing)
            let parentPoint = CGPoint(x: parentX, y: parentY)
            
            // Draw line to parent
            context.stroke(
                Path { path in
                    path.move(to: CGPoint(x: centerX, y: centerY))
                    path.line(to: parentPoint)
                },
                with: .color(.gray),
                lineWidth: 1
            )
        }
        
        // Draw siblings
        let siblingRelationships = person.relationships.filter { $0.type == "Sibling" }
        let siblingSpacing = nodeSize.width * 1.2
        
        for (index, relationship) in siblingRelationships.enumerated() {
            let siblingX = centerX + (CGFloat(index + 1) * siblingSpacing)
            let siblingPoint = CGPoint(x: siblingX, y: centerY)
            
            // Draw line to sibling
            context.stroke(
                Path { path in
                    path.move(to: CGPoint(x: centerX, y: centerY))
                    path.line(to: siblingPoint)
                },
                with: .color(.gray),
                lineWidth: 1
            )
        }
        
        // Draw children
        let childRelationships = person.relationships.filter { $0.type == "Child" }
        let childSpacing = nodeSize.width * 1.5
        let childY = centerY + nodeSize.height * 2
        
        for (index, relationship) in childRelationships.enumerated() {
            let childX = centerX + (CGFloat(index - childRelationships.count / 2) * childSpacing)
            let childPoint = CGPoint(x: childX, y: childY)
            
            // Draw line to child
            context.stroke(
                Path { path in
                    path.move(to: CGPoint(x: centerX, y: centerY))
                    path.line(to: childPoint)
                },
                with: .color(.gray),
                lineWidth: 1
            )
        }
    }
    
    private func getVisiblePeople() -> [Person] {
        var people = [person]
        people.append(contentsOf: person.relationships.map { $0.relatedPerson })
        return people
    }
    
    private func getNodePosition(for person: Person, in size: CGSize) -> CGPoint {
        let centerX = size.width / 2
        let centerY = size.height / 2
        
        if person.id == self.person.id {
            return CGPoint(x: centerX, y: centerY)
        }
        
        // Find relationship and calculate position
        if let relationship = self.person.relationships.first(where: { $0.relatedPerson.id == person.id }) {
            switch relationship.type {
            case "Parent":
                let index = self.person.relationships.filter { $0.type == "Parent" }
                    .firstIndex(where: { $0.id == relationship.id }) ?? 0
                let count = self.person.relationships.filter { $0.type == "Parent" }.count
                let x = centerX + (CGFloat(index - count / 2) * 180)
                return CGPoint(x: x, y: centerY - 120)
            case "Child":
                let index = self.person.relationships.filter { $0.type == "Child" }
                    .firstIndex(where: { $0.id == relationship.id }) ?? 0
                let count = self.person.relationships.filter { $0.type == "Child" }.count
                let x = centerX + (CGFloat(index - count / 2) * 180)
                return CGPoint(x: x, y: centerY + 120)
            case "Sibling":
                let index = self.person.relationships.filter { $0.type == "Sibling" }
                    .firstIndex(where: { $0.id == relationship.id }) ?? 0
                return CGPoint(x: centerX + ((CGFloat(index) + 1) * 180), y: centerY)
            default:
                return CGPoint(x: centerX, y: centerY)
            }
        }
        
        return CGPoint(x: centerX, y: centerY)
    }
}

