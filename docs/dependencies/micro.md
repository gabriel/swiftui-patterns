# Dependencies in a Microapps Architecture

## Overview

See [swiftwithmajid.com/2022/02/02/microapps-architecture-in-swift-dependency-injection](https://swiftwithmajid.com/2022/02/02/microapps-architecture-in-swift-dependency-injection/).

The dependency injection pattern involves:

1. **Defining dependencies** as function types or protocols within the feature module
2. **Injecting dependencies** through the view model's initializer
3. **Creating mock implementations** for testing and previews
4. **Centralizing dependency management** in an app container

### 1. Define Dependencies

```swift
@MainActor
@Observable
public final class SearchViewModel {
    public struct Dependencies {
        var search: (String) async throws -> [String]
        var fetchRecent: () async throws -> [String]
        var saveQuery: (String) async throws -> Void
    }
    
    let dependencies: Dependencies
    
    public init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }
    
    private(set) var items: [String] = []
    private(set) var recent: [String] = []
    private(set) var isLoading = false
    private(set) var errorMessage: String?
    
    func fetchRecent() async {
        isLoading = true
        errorMessage = nil
        
        do {
            recent = try await dependencies.fetchRecent()
        } catch {
            errorMessage = "Failed to load recent searches"
        }
        
        isLoading = false
    }
    
    func search(matching query: String) async {
        guard !query.isEmpty else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            items = try await dependencies.search(query)
            try await dependencies.saveQuery(query)
        } catch {
            errorMessage = "Search failed"
            items = []
        }
        
        isLoading = false
    }
}
```

### 2. SwiftUI View

```swift
public struct SearchView: View {
    @Bindable var viewModel: SearchViewModel
    @State private var query = ""
    
    public init(viewModel: SearchViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        List {
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, alignment: .center)
            } else {
                ForEach(viewModel.items, id: \.self) { item in
                    Text(item)
                }
            }
        }
        .navigationTitle("Search")
        .searchable(text: $query) {
            ForEach(viewModel.recent, id: \.self) { recentQuery in
                Text(recentQuery)
                    .searchCompletion(recentQuery)
            }
        }
        .onSubmit(of: .search) {
            Task {
                await viewModel.search(matching: query)
            }
        }
        .task {
            await viewModel.fetchRecent()
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") { }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }
}
```

### 3. Mock Dependencies for Testing

```swift
extension SearchViewModel.Dependencies {
    static let mock = Self(
        search: { query in
            try await Task.sleep(nanoseconds: 500_000_000) // Simulate network delay
            return ["Result 1 for \(query)", "Result 2 for \(query)", "Result 3 for \(query)"]
        },
        fetchRecent: {
            try await Task.sleep(nanoseconds: 200_000_000)
            return ["swift", "swiftui", "ios", "testing"]
        },
        saveQuery: { _ in
            // Mock implementation
        }
    )
    
    static let failing = Self(
        search: { _ in
            throw NSError(domain: "TestError", code: 1, userInfo: nil)
        },
        fetchRecent: {
            throw NSError(domain: "TestError", code: 1, userInfo: nil)
        },
        saveQuery: { _ in
            throw NSError(domain: "TestError", code: 1, userInfo: nil)
        }
    )
}
```

### 4. Modern Preview Macro

```swift
#Preview("Search View") {
    NavigationStack {
        SearchView(
            viewModel: SearchViewModel(dependencies: .mock)
        )
    }
}

#Preview("Search View - Loading") {
    NavigationStack {
        SearchView(
            viewModel: SearchViewModel(dependencies: .mock)
        )
        .onAppear {
            // Simulate loading state
        }
    }
}
```

## App Container Pattern

### 1. Service Layer

```swift
public struct SearchService {
    private let networkClient: NetworkClient
    private let storage: Storage
    
    public init(networkClient: NetworkClient, storage: Storage) {
        self.networkClient = networkClient
        self.storage = storage
    }
    
    func search(matching query: String) async throws -> [String] {
        let endpoint = SearchEndpoint.query(query)
        let response: SearchResponse = try await networkClient.request(endpoint)
        return response.results
    }
    
    func fetchRecent() async throws -> [String] {
        return try await storage.fetchRecentQueries()
    }
    
    func saveQuery(_ query: String) async throws {
        try await storage.saveQuery(query)
    }
}
```

### 2. App Dependencies Container

```swift
public struct AppDependencies {
    public static let production = Self(
        networkClient: NetworkClient(),
        storage: Storage(),
        analytics: AnalyticsService()
    )
    
    let networkClient: NetworkClient
    let storage: Storage
    let analytics: AnalyticsService
    
    // Feature-specific dependency extractors
    var search: SearchViewModel.Dependencies {
        let searchService = SearchService(
            networkClient: networkClient,
            storage: storage
        )
        
        return .init(
            search: searchService.search,
            fetchRecent: searchService.fetchRecent,
            saveQuery: searchService.saveQuery
        )
    }
}
```

### 3. Root View Integration

```swift
@MainActor
public struct RootView: View {
    @State private var searchViewModel: SearchViewModel
    
    public init(dependencies: AppDependencies = .production) {
        self._searchViewModel = State(initialValue: SearchViewModel(
            dependencies: dependencies.search
        ))
    }
    
    public var body: some View {
        TabView {
            NavigationStack {
                SearchView(viewModel: searchViewModel)
            }
            .tabItem {
                Label("Search", systemImage: "magnifyingglass")
            }
            
            // Other tabs...
        }
    }
}
```

## Testing

```swift
@MainActor
func testSearchSuccess() async throws {
    let sut = SearchViewModel(dependencies: .mock)
    let query = "swift"
    
    await sut.search(matching: query)
    
    #expect(!sut.items.isEmpty)
    #expect(!sut.isLoading)
    #expect(sut.errorMessage == nil)
    #expect(sut.items.contains { $0.contains(query) })
}

@MainActor
func testSearchFailure() async throws {
    let sut = SearchViewModel(dependencies: .failing)
    let query = "swift"
    
    await sut.search(matching: query)
    
    #expect(sut.items.isEmpty)
    #expect(!sut.isLoading)
    #expect(sut.errorMessage != nil)
}
```
