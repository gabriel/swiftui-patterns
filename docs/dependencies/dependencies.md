# Swift Dependencies - Dependency Injection for Swift

Swift Dependencies
[github.com/pointfreeco/swift-dependencies](https://github.com/pointfreeco/swift-dependencies)
is a powerful dependency injection library from Point-Free that provides a clean, type-safe way to manage dependencies in Swift applications. It's designed with SwiftUI in mind and offers excellent support for testing and modular architecture.

How it Works: You define a DependencyKey that specifies a liveValue for your app and a testValue for testing. You then extend DependencyValues to create a new key path for your dependency. In your views or view models, you use the @Dependency property wrapper to access the dependency.

## Basic Usage

### 1. Define Dependencies

```swift
import Dependencies

// Define your dependency as a protocol
protocol NetworkClient {
    func fetch<T: Decodable>(_ url: URL) async throws -> T
}

// Create a dependency key
private enum NetworkClientKey: DependencyKey {
    // In Swift, static properties are initialized lazily by default.
    static let liveValue: NetworkClient = LiveNetworkClient()
    static let testValue: NetworkClient = TestNetworkClient()
}

// Extend DependencyValues to include your dependency
extension DependencyValues {
    var networkClient: NetworkClient {
        get { self[NetworkClientKey.self] }
        set { self[NetworkClientKey.self] = newValue }
    }
}

// Live implementation
struct LiveNetworkClient: NetworkClient {
    func fetch<T: Decodable>(_ url: URL) async throws -> T {
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode(T.self, from: data)
    }
}

// Test implementation
struct TestNetworkClient: NetworkClient {
    func fetch<T: Decodable>(_ url: URL) async throws -> T {
        // Return mock data for testing
        fatalError("Implement test data")
    }
}
```

### 2. Use in SwiftUI Views

```swift
import SwiftUI
import Dependencies

struct ContentView: View {
    @Dependency(\.networkClient) private var networkClient
    @State private var items: [Item] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            Group {
                if isLoading {
                    ProgressView("Loading...")
                } else if let error = errorMessage {
                    VStack {
                        Text("Error")
                            .font(.headline)
                        Text(error)
                            .foregroundColor(.red)
                        Button("Retry") {
                            Task {
                                await fetchItems()
                            }
                        }
                    }
                } else {
                    List(items) { item in
                        ItemRow(item: item)
                    }
                }
            }
            .navigationTitle("Items")
            .toolbar {
                Button("Refresh") {
                    Task {
                        await fetchItems()
                    }
                }
            }
        }
        .task {
            await fetchItems()
        }
    }
    
    private func fetchItems() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let url = URL(string: "https://api.example.com/items")!
            items = try await networkClient.fetch(url)
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
}

struct ItemRow: View {
    let item: Item
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(item.title)
                .font(.headline)
            Text(item.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

struct Item: Identifiable, Codable {
    let id: Int
    let title: String
    let description: String
}
```

## View Models with Dependencies

### Observable View Models

```swift
import SwiftUI
import Dependencies

@MainActor
@Observable
class ItemsViewModel {
    @Dependency(\.networkClient) private var networkClient
    @Dependency(\.analyticsClient) private var analyticsClient
    
    var items: [Item] = []
    var isLoading = false
    var errorMessage: String?
    
    func fetchItems() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let url = URL(string: "https://api.example.com/items")!
            items = try await networkClient.fetch(url)
            analyticsClient.track("items_loaded", properties: ["count": items.count])
        } catch {
            errorMessage = error.localizedDescription
            analyticsClient.track("items_load_failed", properties: ["error": error.localizedDescription])
        }
        
        isLoading = false
    }
    
    func refreshItems() async {
        await fetchItems()
    }
}

// Analytics dependency
protocol AnalyticsClient {
    func track(_ event: String, properties: [String: Any]?)
}

private enum AnalyticsClientKey: DependencyKey {
    static let liveValue: AnalyticsClient = LiveAnalyticsClient()
    static let testValue: AnalyticsClient = TestAnalyticsClient()
}

extension DependencyValues {
    var analyticsClient: AnalyticsClient {
        get { self[AnalyticsClientKey.self] }
        set { self[AnalyticsClientKey.self] = newValue }
    }
}

struct LiveAnalyticsClient: AnalyticsClient {
    func track(_ event: String, properties: [String: Any]?) {
        // Send to your analytics service
        print("📊 Analytics: \(event) - \(properties ?? [:])")
    }
}

struct TestAnalyticsClient: AnalyticsClient {
    func track(_ event: String, properties: [String: Any]?) {
        // No-op for testing
    }
}
```

### Using View Models in SwiftUI

```swift
struct ItemsListView: View {
    @State private var viewModel = ItemsViewModel()
    
    var body: some View {
        NavigationView {
            Group {
                if viewModel.isLoading {
                    ProgressView("Loading...")
                } else if let error = viewModel.errorMessage {
                    VStack {
                        Text("Error")
                            .font(.headline)
                        Text(error)
                            .foregroundColor(.red)
                        Button("Retry") {
                            Task {
                                await viewModel.refreshItems()
                            }
                        }
                    }
                } else {
                    List(viewModel.items) { item in
                        ItemRow(item: item)
                    }
                }
            }
            .navigationTitle("Items")
            .toolbar {
                Button("Refresh") {
                    Task {
                        await viewModel.refreshItems()
                    }
                }
            }
        }
        .task {
            await viewModel.fetchItems()
        }
    }
}
```

## Testing with Dependencies

### Unit Testing

```swift
import Testing
import Dependencies

  
  @Test("fetchItems loads items successfully")
  func testFetchItemsSuccess() async throws {
      let mockItems = [
          Item(id: 1, title: "Test Item", description: "Test Description")
      ]
      
      let viewModel = withDependencies {
          $0.networkClient = MockNetworkClient(items: mockItems, error: nil)
      } operation: {
          ItemsViewModel()
      }
      
      await viewModel.fetchItems()
      
      #expect(viewModel.items == mockItems)
      #expect(viewModel.isLoading == false)
      #expect(viewModel.errorMessage == nil)
  }


struct MockNetworkClient: NetworkClient {
    let items: [Item]?
    let error: Error?
    
    func fetch<T: Decodable>(_ url: URL) async throws -> T {
        if let error = error {
            throw error
        }
        return items as! T
    }
}

### SwiftUI Preview Testing

```swift
#Preview("Success") {
    ItemsListView()
        .dependency(\.networkClient, MockNetworkClient(items: [
            Item(id: 1, title: "Preview Item 1", description: "Description 1"),
            Item(id: 2, title: "Preview Item 2", description: "Description 2")
        ], error: nil))
}

#Preview("Loading") {
    ItemsListView()
        .dependency(\.networkClient, MockNetworkClient(items: nil, error: nil))
}

#Preview("Error") {
    ItemsListView()
        .dependency(\.networkClient, MockNetworkClient(items: nil, error: NetworkError.invalidResponse))
}
```

## Advanced Patterns

### Composable Dependencies

```swift
// Combine multiple dependencies
struct AppDependencies {
    @Dependency(\.networkClient) var networkClient
    @Dependency(\.analyticsClient) var analyticsClient
    @Dependency(\.userDefaults) var userDefaults
    @Dependency(\.keychain) var keychain
}

// Use in your app
class AppCoordinator {
    @Dependency(\.networkClient) private var networkClient
    @Dependency(\.analyticsClient) private var analyticsClient
    
    func initialize() async {
        analyticsClient.track("app_launched", properties: nil)
        // Initialize your app
    }
}
```

### Environment-Specific Dependencies

```swift
// Different implementations for different environments
private enum NetworkClientKey: DependencyKey {
    static let liveValue: NetworkClient = LiveNetworkClient()
    static let testValue: NetworkClient = TestNetworkClient()
    static let previewValue: NetworkClient = PreviewNetworkClient()
}

// Use in your app
#if DEBUG
extension DependencyValues {
    var networkClient: NetworkClient {
        get { self[NetworkClientKey.self] }
        set { self[NetworkClientKey.self] = newValue }
    }
}
#endif
```

### Dependency Scoping

```swift
// Scoped dependencies for specific features
struct FeatureDependencies {
    @Dependency(\.networkClient) var networkClient
    @Dependency(\.analyticsClient) var analyticsClient
    
    // Feature-specific dependency
    @Dependency(\.featureFlags) var featureFlags
}

// Use with scoping
func withFeatureDependencies<T>(_ operation: () -> T) -> T {
    withDependencies {
        $0.featureFlags = LiveFeatureFlags()
    } operation: {
        operation()
    }
}
```
