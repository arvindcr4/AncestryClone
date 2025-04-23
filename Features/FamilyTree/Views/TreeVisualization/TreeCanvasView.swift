import SwiftUI

struct TreeCanvasView: View {
    let person: Person
    @Binding var selectedPerson: Person?
    @ObservedObject var viewModel: FamilyTreeViewModel
    var orientation: TreeOrientation = .vertical
    
    // These are used internally but will be overridden by ZoomableTreeView parent
    @State private var scale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastScale: CGFloat = 1.0
    @State private var lastOffset: CGSize = .zero
    @State private var showingPersonDetail = false
    
    // For iPad-specific layout adjustments
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    var body: some View {
        GeometryReader { geometry in
            // Now handled by parent ZoomableTreeView - keeping for backward compatibility
            let magnification = MagnificationGesture()
                .onChanged { value in
                    // Only apply if not inside ZoomableTreeView
                    if self.parent(ofType: ZoomableTreeView<TreeCanvasView>.self) == nil {
                        let delta = value / lastScale
                        lastScale = value
                        scale *= delta
                    }
                }
                .onEnded { _ in
                    lastScale = 1.0
                }
            
            let drag = DragGesture()
                .onChanged { value in
                    // Only apply if not inside ZoomableTreeView
                    if self.parent(ofType: ZoomableTreeView<TreeCanvasView>.self) == nil {
                        offset = CGSize(
                            width: lastOffset.width + value.translation.width,
                            height: lastOffset.height + value.translation.height
                        )
                    }
                }
                .onEnded { _ in
                    lastOffset = offset
                }
            
            ZStack {
                Canvas { context, size in
                    // Only apply local transform if not inside ZoomableTreeView
                    if self.parent(ofType: ZoomableTreeView<TreeCanvasView>.self) == nil {
                        context.translateBy(x: offset.width, y: offset.height)
                        context.scaleBy(x: scale, y: scale)
                    }
                    drawTree(context: context, in: size, for: person, orientation: orientation)
                }
                
                // Interactive nodes layer
                ForEach(getVisiblePeople(), id: \.id) { person in
                    TreeNodeView(
                        person: person,
                        isSelected: selectedPerson?.id == person.id,
                        isTablet: horizontalSizeClass == .regular,
                        onTap: {
                            selectedPerson = person
                            showingPersonDetail = true
                        }
                    )
                    .position(getNodePosition(for: person, in: geometry.size, orientation: orientation))
                    .contentShape(Rectangle().size(CGSize(width: 150, height: 80)))
                    .accessibility(label: Text(person.fullName))
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
    
    // Detect if view is inside another view of specific type
    private func parent<T>(ofType type: T.Type) -> Bool {
        var currentView = self._viewListCount
        while let ancestor = Mirror(reflecting: currentView).superclassMirror {
            if ancestor.subjectType == type {
                return true
            }
            currentView = ancestor.subject
        }
        return false
    }
    
    private func drawTree(context: GraphicsContext, in size: CGSize, for person: Person, orientation: TreeOrientation) {
        let centerX = size.width / 2
        let centerY = size.height / 2
        
        // Adjust node size and spacing based on device size class
        let baseNodeWidth: CGFloat = horizontalSizeClass == .regular ? 150 : 120
        let baseNodeHeight: CGFloat = horizontalSizeClass == .regular ? 80 : 60
        let nodeSize = CGSize(width: baseNodeWidth, height: baseNodeHeight)
        
        // Adjust spacing multipliers for iPad
        let spacingMultiplier: CGFloat = horizontalSizeClass == .regular ? 1.8 : 1.5
        
        // Only draw connection lines in the Canvas, nodes will be drawn as interactive SwiftUI views
        
        if orientation == .vertical {
            drawVerticalTree(context: context, in: size, for: person, centerX: centerX, centerY: centerY, nodeSize: nodeSize, spacingMultiplier: spacingMultiplier)
        } else {
            drawHorizontalTree(context: context, in: size, for: person, centerX: centerX, centerY: centerY, nodeSize: nodeSize, spacingMultiplier: spacingMultiplier)
        }
    }
    
    private func drawVerticalTree(context: GraphicsContext, in size: CGSize, for person: Person, centerX: CGFloat, centerY: CGFloat, nodeSize: CGSize, spacingMultiplier: CGFloat) {
        // Draw parents
        let parentRelationships = person.relationships.filter { $0.type == "Parent" }
        let parentSpacing = nodeSize.width * spacingMultiplier
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
    }
    
    private func drawHorizontalTree(context: GraphicsContext, in size: CGSize, for person: Person, centerX: CGFloat, centerY: CGFloat, nodeSize: CGSize, spacingMultiplier: CGFloat) {
        // Draw parents - on the left side in horizontal layout
        let parentRelationships = person.relationships.filter { $0.type == "Parent" }
        let parentSpacing = nodeSize.height * spacingMultiplier
        let parentX = centerX - nodeSize.width * 2
        
        for (index, _) in parentRelationships.enumerated() {
            let parentY = centerY + (CGFloat(index - parentRelationships.count / 2) * parentSpacing)
            let parentPoint = CGPoint(x: parentX, y: parentY)
            
            // Draw line to parent
            context.stroke(
                Path { path in
                    path.move(to: CGPoint(x: centerX, y: centerY))
                    path.line(to: parentPoint)
                },
                with: .color(.gray),
                lineWidth: 1.5
            )
        }
        
        // Draw siblings - above in horizontal layout
        let siblingRelationships = person.relationships.filter { $0.type == "Sibling" }
        let siblingSpacing = nodeSize.height * spacingMultiplier
        
        for (index, _) in siblingRelationships.enumerated() {
            let siblingY = centerY - (CGFloat(index + 1) * siblingSpacing)
            let siblingPoint = CGPoint(x: centerX, y: siblingY)
            
            // Draw line to sibling
            context.stroke(
                Path { path in
                    path.move(to: CGPoint(x: centerX, y: centerY))
                    path.line(to: siblingPoint)
                },
                with: .color(.gray),
                lineWidth: 1.5
            )
        }
        
        // Draw children - on the right side in horizontal layout
        let childRelationships = person.relationships.filter { $0.type == "Child" }
        let childSpacing = nodeSize.height * spacingMultiplier
        let childX = centerX + nodeSize.width * 2
        
        for (index, _) in childRelationships.enumerated() {
            let childY = centerY + (CGFloat(index - childRelationships.count / 2) * childSpacing)
            let childPoint = CGPoint(x: childX, y: childY)
            
            // Draw line to child
            context.stroke(
                Path { path in
                    path.move(to: CGPoint(x: centerX, y: centerY))
                    path.line(to: childPoint)
                },
                with: .color(.gray),
                lineWidth: 1.5
            )
        }
    }
    
    private func getVisiblePeople() -> [Person] {
        var people = [person]
        people.append(contentsOf: person.relationships.map { $0.relatedPerson })
        return people
    }
    
    private func getNodePosition(for person: Person, in size: CGSize, orientation: TreeOrientation) -> CGPoint {
        let centerX = size.width / 2
        let centerY = size.height / 2
        
        // Base spacing that changes based on device size
        let baseSpacing: CGFloat = horizontalSizeClass == .regular ? 220 : 180
        
        // If this is the central person
        if person.id == self.person.id {
            return CGPoint(x: centerX, y: centerY)
        }
        
        // Find relationship and calculate position
        if let relationship = self.person.relationships.first(where: { $0.relatedPerson.id == person.id }) {
            let relationshipType = relationship.type
            
            if orientation == .vertical {
                // Vertical tree layout
                switch relationshipType {
                case "Parent":
                    let parentRelationships = self.person.relationships.filter { $0.type == "Parent" }
                    let index = parentRelationships.firstIndex(where: { $0.id == relationship.id }) ?? 0
                    let count = parentRelationships.count
                    let x = centerX + (CGFloat(index - count / 2) * baseSpacing)
                    return CGPoint(x: x, y: centerY - baseSpacing)
                    
                case "Child":
                    let childRelationships = self.person.relationships.filter { $0.type == "Child" }
                    let index = childRelationships.firstIndex(where: { $0.id == relationship.id }) ?? 0
                    let count = childRelationships.count
                    let x = centerX + (CGFloat(index - count / 2) * baseSpacing)
                    return CGPoint(x: x, y: centerY + baseSpacing)
                    
                case "Sibling":
                    let siblingRelationships = self.person.relationships.filter { $0.type == "Sibling" }
                    let index = siblingRelationships.firstIndex(where: { $0.id == relationship.id }) ?? 0
                    return CGPoint(x: centerX + ((CGFloat(index) + 1) * baseSpacing), y: centerY)
                    
                default:
                    return CGPoint(x: centerX + baseSpacing, y: centerY + baseSpacing)
                }
            } else {
                // Horizontal tree layout
                switch relationshipType {
                case "Parent":
                    let parentRelationships = self.person.relationships.filter { $0.type == "Parent" }
                    let index = parentRelationships.firstIndex(where: { $0.id == relationship.id }) ?? 0
                    let count = parentRelationships.count
                    let y = centerY + (CGFloat(index - count / 2) * baseSpacing * 0.8)
                    return CGPoint(x: centerX - baseSpacing, y: y)
                    
                case "Child":
                    let childRelationships = self.person.relationships.filter { $0.type == "Child" }
                    let index = childRelationships.firstIndex(where: { $0.id == relationship.id }) ?? 0
                    let count = childRelationships.count
                    let y = centerY + (CGFloat(index - count / 2) * baseSpacing * 0.8)
                    return CGPoint(x: centerX + baseSpacing, y: y)
                    
                case "Sibling":
                    let siblingRelationships = self.person.relationships.filter { $0.type == "Sibling" }
                    let index = siblingRelationships.firstIndex(where: { $0.id == relationship.id }) ?? 0
                    return CGPoint(x: centerX, y: centerY - ((CGFloat(index) + 1) * baseSpacing * 0.8))
                    
                default:
                    return CGPoint(x: centerX + baseSpacing, y: centerY + baseSpacing)
                }
            }
        }
        
        // Default position if relationship not found
        return CGPoint(x: centerX, y: centerY)
    }
}

enum TreeOrientation {
    case vertical
    case horizontal
}
