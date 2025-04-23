# iPad Support in AncestryClone

This document outlines the iPad-specific features, implementation details, and best practices for the AncestryClone application. It serves as a reference for developers working on maintaining and extending the iPad functionality.

## Table of Contents

1. [Overview](#overview)
2. [Key Features](#key-features)
3. [Technical Implementation](#technical-implementation)
4. [Usage Guidelines](#usage-guidelines)
5. [Performance Considerations](#performance-considerations)
6. [Testing Recommendations](#testing-recommendations)
7. [Known Issues](#known-issues)

## Overview

AncestryClone provides a fully native iPad experience that takes advantage of the iPad's larger screen, multitasking capabilities, and advanced input methods. The app is designed to provide an immersive genealogy experience on iPad devices, with optimized layouts and interaction patterns.

### Design Philosophy

Our iPad implementation follows these core principles:

1. **Adapt, don't just scale** - We've reimagined interactions for iPad rather than simply scaling up the iPhone UI
2. **Leverage iPad-specific features** - Support for multitasking, keyboard shortcuts, Apple Pencil, and drag-and-drop
3. **Optimize for performance** - Special handling for larger genealogy datasets common on iPad
4. **Maintain visual consistency** - While embracing iPad UI patterns, we maintain brand and visual consistency

## Key Features

### iPad-Optimized UI

- **Split View Navigation** - Uses `NavigationSplitView` on iPad for master-detail interfaces
- **Adaptive Layouts** - Content adapts to different screen sizes and orientations
- **Enhanced Visualizations** - Family tree visualizations optimized for larger iPad displays
- **Keyboard Support** - Comprehensive keyboard shortcuts for external keyboard users

### Multitasking Support

- **Multi-Window** - Support for multiple windows of the app running simultaneously
- **Slide Over and Split View** - Full support for iPadOS multitasking features
- **Scene State Preservation** - Each window maintains its own state and navigation history
- **Drag and Drop** - Support for dragging and dropping content between windows or apps

### Performance Optimizations

- **Batch Data Loading** - Optimized CoreData fetching for handling large family trees
- **Memory Management** - Special handling for memory constraints when displaying large trees
- **Background Processing** - Offloading heavy computation to background threads
- **Adaptive Detail Levels** - Different levels of detail based on zoom level and device capabilities

## Technical Implementation

### Project Configuration

The app is configured as a Universal app with the following settings:

- Target devices set to iPhone/iPad Universal
- Deployment target of iOS 15.0+
- iPad interface orientations: All supported
- iPadOS multitasking: Fully supported

### Core Architecture

#### NavigationSplitView

We use `NavigationSplitView` conditionally on iPad:

```swift
if horizontalSizeClass == .regular {
    NavigationSplitView {
        // Sidebar content
    } detail: {
        // Detail content
    }
    .navigationSplitViewStyle(.balanced)
} else {
    NavigationStack {
        // iPhone navigation
    }
}
```

#### Size Classes

We detect and respond to size classes throughout the app:

```swift
@Environment(\.horizontalSizeClass) private var horizontalSizeClass

var isIpad: Bool {
    return horizontalSizeClass == .regular
}
```

#### Scene Handling

For multi-window support, we implement appropriate scene handling:

```swift
// Handle scene connections in SceneDelegate
func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
    // Create and configure a window for the scene
}
```

#### CoreData Optimizations

We've optimized CoreData for iPad's larger datasets:

```swift
// Example of batch fetching
func fetchLargeDataset<T: NSManagedObject>(_ type: T.Type,
                                          predicate: NSPredicate? = nil,
                                          batchHandler: @escaping ([T]) -> Void) {
    // Implementation shown in CoreDataStack.swift
}
```

### Tree Visualization

Our tree visualization components use adaptive layouts and gestures:

- `ZoomableTreeView` for pinch-to-zoom and panning
- Adaptive node sizing and spacing based on device and orientation
- Resolution independence with vector drawing

## Usage Guidelines

### Layout Best Practices

1. **Always use size classes** rather than device checks when possible
2. **Design for both orientations** - Test layouts in portrait and landscape
3. **Use relative spacing** rather than fixed dimensions
4. **Support keyboard focus** for all interactive elements

### Multi-Window Development

1. Avoid singleton state when possible
2. Use `@SceneStorage` for per-window persistent state
3. Use scene notifications to coordinate between windows
4. Test window transitions and state preservation

### Performance Guidelines

1. **Load data lazily** and only when needed
2. **Implement pagination** for large datasets
3. **Monitor memory usage** especially for large family trees
4. **Cache results** of expensive calculations

## Performance Considerations

### Memory Management

iPad users often work with larger family trees, requiring special memory considerations:

1. **Batch Loading** - Use `fetchBatchSize` for large result sets
2. **Background Processing** - Move expensive operations off the main thread
3. **Memory Warnings** - Implement proper handling of memory warnings
4. **Efficient Rendering** - Use appropriate level of detail based on zoom level

### Large Tree Optimization

For very large family trees:

1. **Virtualized Rendering** - Only render nodes that are visible
2. **Progressive Loading** - Load branches as they're expanded
3. **Detail Reduction** - Show simplified nodes at distant zoom levels
4. **Pagination** - Load ancestors/descendants in pages

## Testing Recommendations

### Testing Matrix

| Device | iOS | Orientation | Mode |
|--------|-----|-------------|------|
| iPad 9th Gen | 16.6+ | Portrait/Landscape | Full screen |
| iPad mini 6 | 17.0+ | Both | Slide Over |
| iPad Air 5 | 17.0+ | Both | Split View (50/50 & 70/30) |
| iPad Pro 12.9 | 17.0+ | Both | Stage Manager & external display |

### Testing Tools

Use the following tools to aid testing:

1. **Xcode Device Previews** - For quick UI checks
2. **Xcode Instruments** - For performance profiling
3. **SceneHandlingDemoView** - For testing multi-window behavior
4. **PreviewHelper** - For generating test data

### Test Cases

1. **Orientation Changes** - Verify UI adapts properly when rotating the device
2. **Multitasking Transitions** - Test slide over, split view, and full screen transitions
3. **Memory Pressure** - Test with large datasets and monitor memory usage
4. **Multiple Windows** - Test creating, using, and closing multiple windows
5. **External Display** - Test Stage Manager and external display support

## Known Issues

- Extremely large family trees (>10,000 individuals) may experience performance issues when fully expanded
- Keyboard shortcuts not yet localized for international keyboards
- Stage Manager animations may stutter on older iPad models

---

Document Last Updated: April 23, 2025

