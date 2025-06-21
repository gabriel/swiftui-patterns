# SwiftUI Routes

[github.com/gabriel/swiftui-routes](https://github.com/gabriel/swiftui-routes)

##

SwiftUI Routes is designed to solve navigation challenges in complex SwiftUI applications, particularly when dealing with multiple packages and dependencies. It provides a unified routing system that can handle both URL-based deep linking and type-safe navigation.

## Key Features

- **Dual Routing Approaches**: Support for both URL-based and Type-based routes
- **Package Independence**: Routes can be registered from different packages without tight coupling
- **Environment Integration**: Routes are accessible via SwiftUI's Environment system
- **Deep Linking Support**: URL-based routes enable deep linking capabilities
- **Type Safety**: Type-based routes provide compile-time safety
- **Observable**: Routes are Observable and integrate seamlessly with SwiftUI's reactive system

## Usage

### Basic Setup

```swift
import SwiftUI
import SwiftUIRoutes

struct MyApp: View {
    @State var routes: Routes

    init() {
        let routes = Routes()
        
        // Register your routes
        routes.register(path: "/my/route", myRoute)
        routes.register(type: MyValue.self, myTypeRoute)

        _routes = State(initialValue: routes)
    }

    var body: some View {
        NavigationStack(path: $routes.path) {
            MyView()                
                .routesDestination(routes)
        }
    }

    @ViewBuilder
    func myRoute(_ url: RouteURL) -> some View {
        MyRoute()
    }
    
    @ViewBuilder
    func myTypeRoute(_ value: MyValue) -> some View {
        MyTypeRoute(value: value)
    }
}
```

### URL-Based Routes (Loosely Coupled)

URL-based routes are ideal for deep linking and when working with complex package dependencies.

#### Registering URL Routes

```swift
// In your package
routes.register(path: "/my/route") { url in
    MyRouteView(url: url)
}
```

#### Defining Route Views

```swift
@ViewBuilder
func myRoute(_ url: RouteURL) -> some View {
    VStack {
        Text("Route: \(url.path)")
        Text("Params: \(url.params)")
    }
}
```

#### Using URL Routes

```swift
struct MyView: View {
    @Environment(Routes.self) var routes

    var body: some View {
        Button("Navigate") {
            routes.push("/my/route", params: ["text": "Hello!"])
        }
    }
}
```

### Type-Based Routes (Strongly Coupled)

Type-based routes provide compile-time safety and are ideal for internal navigation within your app.

#### Registering Type Routes

```swift
// In your package
routes.register(type: MyValue.self) { value in
    MyTypeRouteView(value: value)
}
```

#### Defining Type Route Views

```swift
@ViewBuilder
func myTypeRoute(_ value: MyValue) -> some View {
    VStack {
        Text(value.title)
        Text(value.description)
    }
}
```

#### Using Type Routes

```swift
struct MyView: View {
    @Environment(Routes.self) var routes

    var body: some View {
        Button("Navigate") {
            routes.push(MyValue(title: "Hello", description: "World"))
        }
    }
}
```

### Navigation Methods

The Routes object provides several navigation methods:

```swift
@Environment(Routes.self) var routes

// Push a new route
routes.push("/my/route")
routes.push(MyValue())

// Pop the current route
routes.pop()
```

### Multi-Package Example

Here's how to use SwiftUI Routes across multiple packages:

#### Main App

```swift
import PackageA
import PackageB
import SwiftUI
import SwiftUIRoutes

public struct ExampleView: View {
    @State private var routes: Routes

    public init() {
        let routes = Routes()
        PackageA.register(routes: routes)
        PackageB.register(routes: routes)
        _routes = State(initialValue: routes)
    }

    public var body: some View {
        NavigationStack(path: $routes.path) {
            List {
                Button("Package A (Type)") {
                    routes.push(PackageA.Value(text: "Hello World!"))
                }

                Button("Package A (URL)") {
                    routes.push("/package-a/value", params: ["text": "Hello!"])
                }

                Button("Package B (Type)") {
                    routes.push(PackageB.Value(systemImage: "heart.fill"))
                }

                Button("Package B (URL)") {
                    routes.push("/package-b/value", params: ["systemName": "heart"])
                }
            }
            .navigationTitle("Example")
            .routesDestination(routes)
        }
    }
}
```

#### Package Registration

```swift
// In PackageA
import SwiftUI
import SwiftUIRoutes

@MainActor
public func register(routes: Routes) {
    routes.register(type: Value.self) { value in
        PackageAView(value: value)
    }
    routes.register(path: "/package-a/value") { url in
        PackageAView(value: Value(text: url.params["text"] ?? ""))
    }
}

struct PackageAView: View {
    @Environment(Routes.self) var routes
    let value: Value

    var body: some View {
        VStack {
            Text(value.text)
            Button("Back") {
                routes.pop()
            }
            .buttonStyle(.bordered)
        }
        .navigationTitle("Package A")
    }
}
```

```swift
// In PackageB
import SwiftUI
import SwiftUIRoutes

@MainActor
public func register(routes: Routes) {
    routes.register(type: Value.self) { value in
        PackageBView(value: value)
    }
    routes.register(path: "/package-b/value") { url in
        PackageBView(value: Value(systemImage: url.params["systemName"] ?? "heart.fill"))
    }
}

struct PackageBView: View {
    @Environment(Routes.self) var routes
    let value: Value

    var body: some View {
        VStack {
            Image(systemName: value.systemImage)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            Button("Back") {
                routes.pop()
            }
            .buttonStyle(.bordered)
        }
        .navigationTitle("Package B")
    }
}
```

## Best Practices

- Use URL-based routes for deep linking and cross-package navigation
- Use Type-based routes for internal navigation within packages
- Register routes in a dedicated function within each package
- Access routes via `@Environment(Routes.self)` in registered views
