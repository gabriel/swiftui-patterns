# Factory - Dependency Injection for SwiftUI

Factory
[github.com/hmlongco/Factory](https://github.com/hmlongco/Factory)
is a modern, container-based dependency injection system designed specifically for Swift and SwiftUI applications. It provides a clean, type-safe way to manage dependencies with minimal boilerplate code.

How it Works: You register your dependencies within an extension on a Container object. For each dependency, you provide a factory closure that creates an instance. You can assign a scope (like .singleton or .session) to control the instance's lifetime. Dependencies are then resolved using property wrappers like @Injected or @InjectedObservable.

## Basic Usage

### 1. Define Your Services

```swift
// Protocol defining the service interface
protocol NetworkServiceProtocol {
    func fetchData() async throws -> [Item]
}

// Concrete implementation
class NetworkService: NetworkServiceProtocol {
    func fetchData() async throws -> [Item] {
        // Implementation here
        return []
    }
}

// Another service
protocol AnalyticsServiceProtocol {
    func trackEvent(_ event: String)
}

class AnalyticsService: AnalyticsServiceProtocol {
    func trackEvent(_ event: String) {
        print("Tracking: \(event)")
    }
}
```

### 2. Register Dependencies

```swift
import FactoryKit

extension Container {
    // Register network service as singleton
    var networkService: Factory<NetworkServiceProtocol> {
        self { NetworkService() }
            .singleton
    }
    
    // Register analytics service with session scope
    var analyticsService: Factory<AnalyticsServiceProtocol> {
        self { AnalyticsService() }
            .scope(.session)
    }
    
    // Register view model factory
    var contentViewModel: Factory<ContentViewModel> {
        self { ContentViewModel() }
    }
}
```

### 3. Use in SwiftUI Views

```swift
struct ContentView: View {
    @Injected(\.networkService) private var networkService
    @Injected(\.analyticsService) private var analyticsService
    @InjectedObservable(\.contentViewModel) var viewModel
    
    var body: some View {
        VStack {
            Text("Hello, Factory!")
            
            Button("Fetch Data") {
                Task {
                    do {
                        let items = try await networkService.fetchData()
                        analyticsService.trackEvent("data_fetched")
                        await viewModel.updateItems(items)
                    } catch {
                        print("Error: \(error)")
                    }
                }
            }
        }
        .onAppear {
            analyticsService.trackEvent("view_appeared")
        }
    }
}
```

## View Models with Factory

### Observable View Models

```swift
@MainActor
@Observable
class ContentViewModel {
    @ObservationIgnored @Injected(\.networkService) private var networkService
    @ObservationIgnored @Injected(\.analyticsService) private var analyticsService
    
    var items: [Item] = []
    var isLoading = false
    var errorMessage: String?
    
    func fetchItems() async {
        isLoading = true
        errorMessage = nil
        
        do {
            items = try await networkService.fetchData()
            analyticsService.trackEvent("items_loaded")
        } catch {
            errorMessage = error.localizedDescription
            analyticsService.trackEvent("items_load_failed")
        }
        
        isLoading = false
    }
    
    func updateItems(_ newItems: [Item]) {
        items = newItems
    }
}

// Register the view model
extension Container {
    @MainActor
    var contentViewModel: Factory<ContentViewModel> {
        self { @MainActor in ContentViewModel() }
    }
}
```

### Using InjectedObservable

```swift
struct ItemsListView: View {
    @InjectedObservable(\.contentViewModel) var viewModel
    
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
                                await viewModel.fetchItems()
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
                        await viewModel.fetchItems()
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

## Scopes

Factory provides several scopes to control object lifetime:

### Singleton Scope

```swift
extension Container {
    var networkService: Factory<NetworkServiceProtocol> {
        self { NetworkService() }
            .singleton  // Same instance for entire app lifecycle
    }
}
```

### Session Scope

```swift
extension Container {
    var userSession: Factory<UserSession> {
        self { UserSession() }
            .scope(.session)  // Same instance per app session
    }
}
```

### Cached Scope

```swift
extension Container {
    var imageCache: Factory<ImageCache> {
        self { ImageCache() }
            .cached  // Persisted until cache is reset
    }
}
```

### Shared Scope

```swift
extension Container {
    var temporaryData: Factory<TemporaryData> {
        self { TemporaryData() }
            .shared  // Exists as long as someone holds a reference
    }
}
```

### Unique Scope (Default)

```swift
extension Container {
    var viewModel: Factory<SomeViewModel> {
        self { SomeViewModel() }  // New instance every time
    }
}
```

## Contexts and Testing

### Debug Context Override

```swift
// Override for debug builds
container.analyticsService.onDebug { 
    StubAnalyticsService()
}
```

### Testing Context

```swift
// In your test setup
container.networkService.onTest { 
    MockNetworkService()
}
```

### SwiftUI Preview Context

```swift
// For SwiftUI previews
container.networkService.onPreview { 
    PreviewNetworkService()
}
```

## Advanced Patterns

### Circular Dependencies

```swift
extension Container {
    var serviceA: Factory<ServiceA> {
        self { ServiceA() }
            .scope(.shared)
    }
    
    var serviceB: Factory<ServiceB> {
        self { ServiceB() }
            .scope(.shared)
    }
}

class ServiceA {
    @Injected(\.serviceB) private var serviceB
    // ServiceA can now use ServiceB
}

class ServiceB {
    @Injected(\.serviceA) private var serviceA
    // ServiceB can now use ServiceA
}
```

### Factory with Parameters

```swift
extension Container {
    var userProfileViewModel: Factory<UserProfileViewModel> {
        self { userId in
            UserProfileViewModel(userId: userId)
        }
    }
}

// Usage
@Injected(\.userProfileViewModel) private var userProfileViewModelFactory

// In your view
let viewModel = userProfileViewModelFactory(123)
```

### Lazy Injection

```swift
class SomeClass {
    @LazyInjected(\.heavyService) private var heavyService
    
    func doSomething() {
        // heavyService is only created when first accessed
        heavyService.performHeavyOperation()
    }
}
```

## Debugging

Factory provides debugging tools to trace dependency resolution:

```swift
// Enable tracing in DEBUG builds
#if DEBUG
Container.shared.trace.toggle()
#endif
```

This will output dependency resolution traces like:

```txt
0: Factory.Container.contentViewModel<ContentViewModel> = N:105553131389696
1:     Factory.Container.networkService<NetworkServiceProtocol> = N:105553119821680
2:     Factory.Container.analyticsService<AnalyticsServiceProtocol> = N:105553119821681
```

## Migration from Factory 1.x

If you're upgrading from Factory 1.x:

1. Update to latest package version
2. Remove `Factory` library, add `FactoryKit` library
3. Replace `import Factory` with `import FactoryKit`
4. Clean and build your project

## Best Practices

1. **Use protocols** for service interfaces to enable testing and flexibility
2. **Register dependencies** in container extensions for better organization
3. **Choose appropriate scopes** based on object lifetime requirements
4. **Use contexts** for different environments (debug, test, preview)
5. **Leverage `@InjectedObservable`** for SwiftUI view models
6. **Consider `@MainActor`** for UI-related services and view models

## Example: Complete App Structure

```swift
// MARK: - Services
protocol DataServiceProtocol {
    func fetchItems() async throws -> [Item]
    func saveItem(_ item: Item) async throws
}

class DataService: DataServiceProtocol {
    func fetchItems() async throws -> [Item] {
        // Implementation
        return []
    }
    
    func saveItem(_ item: Item) async throws {
        // Implementation
    }
}

// MARK: - View Models
@MainActor
@Observable
class ItemListViewModel {
    @ObservationIgnored @Injected(\.dataService) private var dataService
    @ObservationIgnored @Injected(\.analyticsService) private var analyticsService
    
    var items: [Item] = []
    var isLoading = false
    
    func loadItems() async {
        isLoading = true
        do {
            items = try await dataService.fetchItems()
            analyticsService.trackEvent("items_loaded")
        } catch {
            analyticsService.trackEvent("items_load_failed")
        }
        isLoading = false
    }
}

// MARK: - Container Registration
extension Container {
    var dataService: Factory<DataServiceProtocol> {
        self { DataService() }
            .singleton
    }
    
    var analyticsService: Factory<AnalyticsServiceProtocol> {
        self { AnalyticsService() }
            .scope(.session)
    }
    
    @MainActor
    var itemListViewModel: Factory<ItemListViewModel> {
        self { @MainActor in ItemListViewModel() }
    }
}

// MARK: - SwiftUI View
struct ItemListView: View {
    @InjectedObservable(\.itemListViewModel) var viewModel
    
    var body: some View {
        NavigationView {
            Group {
                if viewModel.isLoading {
                    ProgressView()
                } else {
                    List(viewModel.items) { item in
                        ItemRow(item: item)
                    }
                }
            }
            .navigationTitle("Items")
        }
        .task {
            await viewModel.loadItems()
        }
    }
}
```

## Resources

- [Factory GitHub Repository](https://github.com/hmlongco/Factory)
- [Factory Documentation](https://github.com/hmlongco/Factory/tree/main/docs)
- [Factory 2.0 Discussion Forum](https://github.com/hmlongco/Factory/discussions)

Factory provides a powerful, yet simple dependency injection solution that integrates seamlessly with SwiftUI's declarative programming model, making it an excellent choice for modern iOS applications.
