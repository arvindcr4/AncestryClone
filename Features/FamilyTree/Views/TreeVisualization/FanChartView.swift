import SwiftUI

struct FanChartView: View {
    let person: Person
    @Binding var selectedPerson: Person?
    @ObservedObject var viewModel: FamilyTreeViewModel
    
    @State private var scale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastScale: CGFloat = 1.0
    @State private var lastOffset: CGSize = .zero
    @State private var generations: Int = 4
    
    private func drawFanChart(context: GraphicsContext, in size: CGSize) {
        let radius = min(size.width, size.height) * 0.4
        let generationHeight = radius / CGFloat(generations)
        
        // Draw concentric arcs for generations
        for generation in 0..<generations {
            let currentRadius = generationHeight * CGFloat(generation + 1)
            let path = Path { path in
                path.addArc(
                    center: .zero,
                    radius: currentRadius,
                    startAngle: .degrees(-90),
                    endAngle: .degrees(270),
                    clockwise: false
                )
            }
            context.stroke(path, with: .color(.gray.opacity(0.5)), lineWidth: 1)
        }
        
        // Draw radial lines
        let numberOfSegments = pow(2.0, Double(generations - 1))
        let angleStep = 360.0 / numberOfSegments
        
        for i in 0..<Int(numberOfSegments) {
            let angle = Double(i) * angleStep - 90
            let path = Path { path in
                path.move(to: .zero)
                path.addLine(to: CGPoint(
                    x: radius * cos(angle * .pi / 180),
                    y: radius * sin(angle * .pi / 180)
                ))
            }
            context.stroke(path, with: .color(.gray.opacity(0.5)), lineWidth: 1)
        }
    }
    
    private func getVisiblePeople() -> [Person] {
        var people = [person]
        var currentGeneration = [person]
        
        for _ in 0..<generations {
            var nextGeneration: [Person] = []
            for person in currentGeneration {
                let parents = person.relationships
                    .filter { $0.type == "Parent" }
                    .map { $0.relatedPerson }
                nextGeneration.append(contentsOf: parents)
            }
            people.append(contentsOf: nextGeneration)
            currentGeneration = nextGeneration
        }
        
        return people
    }
    
    private func findPersonPosition(_ targetPerson: Person, from rootPerson: Person, generation: Int = 0) -> PersonPosition? {
        if targetPerson.id == rootPerson.id {
            return PersonPosition(generation: generation, position: 0, totalInGeneration: 1)
        }
        
        let parents = rootPerson.relationships
            .filter { $0.type == "Parent" }
            .map { $0.relatedPerson }
            .sorted { ($0.gender ?? "") < ($1.gender ?? "") }
        
        let totalInGeneration = Int(pow(2.0, Double(generation + 1)))
        let positionsPerParent = totalInGeneration / 2
        
        for (index, parent) in parents.enumerated() {
            if let position = findPersonPosition(targetPerson, from: parent, generation: generation + 1) {
                return PersonPosition(
                    generation: position.generation,
                    position: position.position + (index * positionsPerParent),
                    totalInGeneration: totalInGeneration
                )
            }
        }
        
        return nil
    }
    
    private func getNodeAngle(for person: Person) -> Double {
        guard let position = findPersonPosition(person, from: self.person) else {
            return 0
        }
        
        let totalAngle = 360.0
        let segmentCount = pow(2.0, Double(position.generation))
        let anglePerSegment = totalAngle / segmentCount
        let baseAngle = -90.0
        let positionAngle = Double(position.position) * anglePerSegment
        
        return baseAngle + positionAngle + (anglePerSegment / 2)
    }
    
    private func getNodeRadius(for person: Person) -> Double {
        guard let position = findPersonPosition(person, from: self.person) else {
            return 0
        }
        
        let baseRadius = min(UIScreen.main.bounds.width, UIScreen.main.bounds.height) * 0.35
        let generationHeight = baseRadius / CGFloat(generations)
        
        return Double(generationHeight * CGFloat(position.generation + 1))
    }
}
        let totalInGeneration: Int
    }
    
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
                // Background circles and lines
                Canvas { context, size in
                    context.translateBy(x: offset.width + size.width/2, y: offset.height + size.height/2)
                    context.scaleBy(x: scale, y: scale)
                    drawFanChart(context: context, in: size)
                }
                
                // Person nodes
                ForEach(getVisiblePeople(), id: \.id) { person in
                    FanChartNodeView(
                        person: person,
                        isSelected: selectedPerson?.id == person.id,
                        angle: getNodeAngle(for: person),
                        radius: getNodeRadius(for: person),
                        onTap: { selectedPerson = person }
                    )
                    .position(
                        x: geometry.size.width/2 + offset.width,
                        y: geometry.size.height/2 + offset.height
                    )
                }
            }
            .gesture(SimultaneousGesture(magnification, drag))
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Stepper(
                    value: $generations,
                    in: 2...7,
                    label: { Text("Generations: \(generations)") }
                )
            }
        }
    }
    
    private func drawFanChart(context: GraphicsContext, in size: CGSize) {
        let radius = min(size.width, size.height) * 0.4
        let generationHeight

