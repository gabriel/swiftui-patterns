# ScrollViewport

`ScrollViewport` is a thin wrapper around `ScrollView` that captures the viewport geometry **before** SwiftUI hands control to the scroll view. Once you're already inside a `ScrollView`, a `GeometryReader` only knows about its own content, not the surrounding container, so sizing logic quickly becomes blind. `ScrollViewport` records that outer geometry exactly once and re-injects it through a `Viewport` environment value so every descendant can still reason about the original viewport.

## When to Use It

- You need the scroll container's size inside lazily loaded content (e.g., to size cards, carousels, or grid items).
- You need geometry information that would otherwise be lost after entering a `ScrollView` where `GeometryReader` reports the content's space instead of the viewport.
- You nest scroll views and only want the outermost one to pay the geometry-measurement cost.

`ScrollViewport` tracks a private `viewportDepth` in the environment so only the first level injects the measurement; inner scroll views behave like plain `ScrollView`s.

## Basic Usage

```swift
struct InboxView: View {
  var body: some View {
    ScrollViewport { // defaults to vertical axes
      LazyVStack(alignment: .leading, spacing: 16) {
        ForEach(messages) { message in
          MessageRow(message: message)
        }
      }
      .padding()
    }
  }
}
```

Inside the hierarchy you can read the viewport via the `.viewport` environment key:

```swift
struct MessageRow: View {
  let message: Message
  @Environment(\.viewport) private var viewport

  var body: some View {
    Text(message.body)
      .frame(maxWidth: viewport.size.width * 0.9, alignment: .leading)
      .padding()
      .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
  }
}
```

The `Viewport` value includes both `size` and `safeAreaInsets`, which is handy for layouts targeting full-screen presentations.

## Nested Scroll Views

`ScrollViewport` shines when the layout inside needs to spin up its own `ScrollView`. The outer viewport captures the device geometry before the inner scroll view changes the coordinate space.

```swift
struct FeaturedCarousel: View {
  @Environment(\.viewport) private var viewport

  var body: some View {
    ScrollViewport {
      ScrollView(.horizontal, showsIndicators: false) {
        LazyHStack(spacing: 24) {
          ForEach(features) { feature in
            FeatureCard(feature)
              .frame(width: viewport.size.width * 0.8)
          }
        }
        .padding(.horizontal, viewport.safeAreaInsets.leading + 16)
      }
    }
  }
}
```

The inner `ScrollView` behaves normally, but every descendant can still read the outer viewport to size cards, adjust safe-area padding, or drive animations.

## Tips

- Combine with lazy stacks/grids to keep large feeds performant while still adapting item widths to the container.
- Read `viewport.safeAreaInsets` when you need precise padding for edge-to-edge designs.
- If you deliberately need a new measurement inside a nested scroll, wrap that section in a plain `ScrollView` + `GeometryReader` manually.
