# SwiftUI Snapshot Testing

A Swift package that provides snapshot testing capabilities for SwiftUI views on both iOS and macOS platforms.

[github.com/gabriel/swiftui-snapshot-testing](https://github.com/gabriel/swiftui-snapshot-testing)

This package uses [github.com/pointfreeco/swift-snapshot-testing](https://github.com/pointfreeco/swift-snapshot-testing) with custom extensions for ImageRenderer and fallbacks otherwise.

## Usage

### Pure SwiftUI Views

```swift
import SwiftUISnapshotTesting
import Testing

@Test @MainActor
func testMyViewRender() throws {
    let view = MyView()
    assertRender(view: view, device: .size(400, 400))
}
```

### UIKit-based SwiftUI Views

```swift
@Test @MainActor
func testMyViewSnapshot() throws {
    let view = NavigationStack {
        MyView()
    }    
    assertSnapshot(view: view, device: .iOS(width: 400, height: 1000))
}
```

### Async Testing

```swift
@Test
func testAsyncTask() async throws {
    let model = await MyViewModel()
    let view = MyView(model: model)
    
    await assertRender(view: view, device: .any)
    try #require(await expression { model.loaded })
    await assertRender(view: view, device: .any)
}
```

## When to Use assertRender vs assertSnapshot

### Use `assertRender` when

- Testing **pure SwiftUI views** that don't rely on UIKit components
- You want **faster test execution** (renders directly to images)
- You need **cross-platform compatibility** (works on both iOS and macOS)

### Use `assertSnapshot` when

- Testing **UIKit-based SwiftUI views** (like `NavigationStack`, `TabView`, etc.)
- You need **more accurate rendering** that matches the actual app behavior
- Testing **complex view hierarchies** that may have UIKit dependencies
- You want **better debugging** capabilities (more detailed error messages)
- Testing views that use **UIKit-specific features** or integrations

### Performance Considerations

- `assertRender` is generally **faster** as it renders directly to images
- `assertSnapshot` may be **slower** but provides more accurate results for complex views

## Device Options

- `.size(width, height)` - Custom size for any platform
- `.iOS(width, height)` - iOS-specific device simulation
- `.macOS(width, height)` - macOS-specific device simulation
- `.any` - Uses a default size based on platform (e.g. 400x1200 for iOS and 1200x800 for macOS)
