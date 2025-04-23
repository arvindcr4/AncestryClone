import SwiftUI
import Combine
import UIKit
import os.log

/// A view that demonstrates and tests scene handling for iPad
struct SceneHandlingDemoView: View {
    // Scene state
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.managedObjectContext) private var viewContext
    
    // State for this view
    @State private var sceneEvents: [SceneEvent] = []
    @State private var memoryUsage: Double = 0
    @State private var cpuUsage: Double = 0
    @State private var isMonitoringActive = false
    @State private var monitoringTimer: Timer?
    @State private var allocatedMemory: Int = 0
    
    // Persistent scene state
    @SceneStorage("demoCounter") private var counter: Int = 0
    @SceneStorage("demoString") private var storedText: String = ""
    
    // Publishers for scene notifications
    @State private var cancellables = Set<AnyCancellable>()
    
    // Scene identifier
    private let sceneID = UUID()
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Scene Information")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Scene ID: \(sceneID.uuidString.prefix(8))", systemImage: "doc.badge.gearshape")
                        Label("Size Class: \(horizontalSizeClass == .regular ? "Regular (iPad)" : "Compact")", systemImage: "ipad")
                        Label("Color Scheme: \(colorScheme == .dark ? "Dark" : "Light")", systemImage: "circle.lefthalf.filled")
                        Label("Scene Phase: \(scenePhaseString)", systemImage: "rays")
                    }
                    .padding(.vertical, 8)
                }
                
                Section(header: Text("Scene Storage Demo")) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Test @SceneStorage state persistence across scene lifecycle events")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        TextField("Enter text to store", text: $storedText)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        HStack {
                            Text("Counter: \(counter)")
                            
                            Spacer()
                            
                            Button(action: {
                                counter += 1
                            }) {
                                Label("Increment", systemImage: "plus.circle")
                            }
                            
                            Button(action: {
                                counter = 0
                                storedText = ""
                            }) {
                                Label("Reset", systemImage: "arrow.counterclockwise.circle")
                            }
                        }
                        
                        Text("Note: Open this view in multiple windows to see per-scene state")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 8)
                }
                
                Section(header: Text("Memory Management Testing")) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Test how the app responds to memory pressure")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            Button(action: {
                                PreviewHelper.simulateMemoryWarning()
                                addEvent(.memoryWarning)
                            }) {
                                Label("Simulate Memory Warning", systemImage: "exclamationmark.triangle")
                                    .padding(8)
                                    .background(Color.orange.opacity(0.2))
                                    .cornerRadius(8)
                            }
                        }
                        
                        VStack(alignment: .leading) {
                            Text("Allocate Memory: \(allocatedMemory) MB")
                            
                            Slider(value: Binding(
                                get: { Double(allocatedMemory) },
                                set: { allocatedMemory = Int($0) }
                            ), in: 0...500, step: 50)
                            
                            HStack {
                                Button("Allocate") {
                                    PreviewHelper.allocateLargeMemory(megabytes: allocatedMemory)
                                    addEvent(.allocatedMemory(mb: allocatedMemory))
                                }
                                .disabled(allocatedMemory == 0)
                                
                                Spacer()
                                
                                Button("Clear") {
                                    // Force a cleanup
                                    autoreleasepool {
                                        PreviewHelper.simulateMemoryWarning()
                                    }
                                    addEvent(.clearedMemory)
                                }
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                Section(header: Text("System Monitoring")) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Toggle("Performance Monitoring", isOn: $isMonitoringActive)
                                .onChange(of: isMonitoringActive) { active in
                                    if active {
                                        startMonitoring()
                                    } else {
                                        stopMonitoring()
                                    }
                                }
                        }
                        
                        if isMonitoringActive {
                            VStack(alignment: .leading, spacing: 8) {
                                ProgressView(value: memoryUsage, total: 100)
                                    .progressViewStyle(LinearProgressViewStyle(tint: memoryColor))
                                
                                HStack {
                                    Text("Memory Usage:")
                                    Spacer()
                                    Text("\(Int(memoryUsage))%")
                                        .foregroundColor(memoryColor)
                                }
                                
                                ProgressView(value: cpuUsage, total: 100)
                                    .progressViewStyle(LinearProgressViewStyle(tint: cpuColor))
                                
                                HStack {
                                    Text("CPU Usage:")
                                    Spacer()
                                    Text("\(Int(cpuUsage))%")
                                        .foregroundColor(cpuColor)
                                }
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                Section(header: Text("Scene Events")) {
                    if sceneEvents.isEmpty {
                        Text("No events recorded yet")
                            .foregroundColor(.secondary)
                            .italic()
                    } else {
                        ForEach(sceneEvents) { event in
                            HStack {
                                Image(systemName: event.iconName)
                                    .foregroundColor(event.color)
                                
                                VStack(alignment: .leading) {
                                    Text(event.description)
                                    Text(event.timestamp, style: .time)
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        
                        Button("Clear Events") {
                            sceneEvents.removeAll()
                        }
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Scene Handling Demo")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        createNewWindow()
                    }) {
                        Label("New Window", systemImage: "macwindow.badge.plus")
                    }
                }
            }
        }
        .onAppear {
            setupSceneEventObservers()
            addEvent(.appeared)
        }
        .onDisappear {
            stopMonitoring()
            addEvent(.disappeared)
        }
        .onChange(of: scenePhase) { newPhase in
            switch newPhase {
            case .active:
                addEvent(.becameActive)
            case .inactive:
                addEvent(.becameInactive)
            case .background:
                addEvent(.enteredBackground)
            @unknown default:
                break
            }
        }
    }
    
    // MARK: - Helper Properties
    
    private var scenePhaseString: String {
        switch scenePhase {
        case .active: return "Active"
        case .inactive: return "Inactive"
        case .background: return "Background"
        @unknown default: return "Unknown"
        }
    }
    
    private var memoryColor: Color {
        switch memoryUsage {
        case 0..<50: return .green
        case 50..<75: return .yellow
        default: return .red
        }
    }
    
    private var cpuColor: Color {
        switch cpuUsage {
        case 0..<30: return .green
        case 30..<70: return .yellow
        default: return .red
        }
    }
    
    // MARK: - Methods
    
    private func setupSceneEventObservers() {
        // Observe notifications for scene connections/disconnections
        NotificationCenter.default.publisher(for: UIScene.didActivateNotification)
            .sink { _ in addEvent(.sceneActivated) }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: UIScene.didDisconnectNotification)
            .sink { _ in addEvent(.sceneDisconnected) }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: UIScene.willConnectNotification)
            .sink { _ in addEvent(.sceneWillConnect) }
            .store(in: &cancellables)
        
        // Observe memory warnings
        NotificationCenter.default.publisher(for: UIApplication.didReceiveMemoryWarningNotification)
            .sink { _ in addEvent(.systemMemoryWarning) }
            .store(in: &cancellables)
    }
    
    private func addEvent(_ type: SceneEventType) {
        let event = SceneEvent(type: type)
        sceneEvents.insert(event, at: 0)
        
        // Limit the number of events to prevent excessive memory usage
        if sceneEvents.count > 50 {
            sceneEvents.removeLast()
        }
    }
    
    private func startMonitoring() {
        monitoringTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            updatePerformanceMetrics()
        }
    }
    
    private func stopMonitoring() {
        monitoringTimer?.invalidate()
        monitoringTimer = nil
    }
    
    private func updatePerformanceMetrics() {
        // This is a simplified simulation of performance monitoring
        // In a real app, you would use proper performance APIs
        
        // Update memory usage (simulated)
        var newMemoryUsage = memoryUsage + Double.random(in: -5...5)
        newMemoryUsage = max(min(newMemoryUsage, 100), 0)
        
        // Update CPU usage (simulated)
        var newCPUUsage = cpuUsage + Double.random(in: -8...8)
        newCPUUsage = max(min(newCPUUsage, 100), 0)
        
        // If we've allocated memory, increase the memory usage accordingly
        if allocatedMemory > 0 {
            newMemoryUsage = min(newMemoryUsage + Double(allocatedMemory) / 10, 100)
        }
        
        memoryUsage = newMemoryUsage
        cpuUsage = newCPUUsage
    }
    
    private func createNewWindow() {
        // This works only in iPad
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let sceneDelegate = scene.delegate as? UIWindowSceneDelegate else {
            return
        }
        
        // Use UIApplication's requestSceneSessionActivation method if available in your app
        UIApplication.shared.requestSceneSessionActivation(nil, userActivity: nil, options: nil, errorHandler: nil)
        
        // Note: In a real implementation, you would need to handle the scene connection in your App Delegate
        addEvent(.requestedNewWindow)
    }
}

// MARK: - Scene Event Types

struct SceneEvent: Identifiable {
    let id = UUID()
    let type: SceneEventType
    let timestamp = Date()
    
    var description: String {
        switch type {
        case .appeared:
            return "View Appeared"
        case .disappeared:
            return "View Disappeared"
        case .becameActive:
            return "Scene Became Active"
        case .becameInactive:
            return "Scene Became Inactive"
        case .enteredBackground:
            return "Scene Entered Background"
        case .sceneActivated:
            return "Scene Activated"
        case .sceneWillConnect:
            return "Scene Will Connect"
        case .sceneDisconnected:
            return "Scene Disconnected"
        case .memoryWarning:
            return "Memory Warning Simulated"
        case .systemMemoryWarning:
            return "System Memory Warning"
        case .allocatedMemory(let mb):
            return "Allocated \(mb) MB Memory"
        case .clearedMemory:
            return "Cleared Allocated Memory"
        case .requestedNewWindow:
            return "Requested New Window"
        }
    }
    
    var iconName: String {
        switch type {
        case .appeared, .becameActive, .sceneActivated, .sceneWillConnect:
            return "checkmark.circle.fill"
        case .disappeared, .becameInactive, .enteredBackground, .sceneDisconnected:
            return "xmark.circle.fill"
        case .memoryWarning, .systemMemoryWarning:
            return "exclamationmark.triangle.fill"
        case .allocatedMemory:
            return "memorychip.fill"
        case .clearedMemory:
            return "trash.fill"
        case .requestedNewWindow:
            return "macwindow.badge.plus"
        }
    }
    
    var color: Color {
        switch type {
        case .appeared, .becameActive, .sceneActivated, .sceneWillConnect:
            return .green
        case .disappeared, .becameInactive, .enteredBackground, .sceneDisconnected:
            return .gray
        case .memoryWarning, .systemMemoryWarning:
            return .orange
        case .allocatedMemory:
            return .blue
        case .clearedMemory:
            return .purple
        case .requestedNewWindow:
            return .blue
        }
    }
}

enum SceneEventType {
    case appeared
    case disappeared
    case becameActive
    case becameInactive
    case enteredBackground
    case sceneActivated
    case sceneWillConnect
    case sceneDisconnected
    case memoryWarning
    case systemMemoryWarning
    case allocatedMemory(mb: Int)
    case clearedMemory
    case requestedNewWindow
}

