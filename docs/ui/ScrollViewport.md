# ScrollViewport

`ScrollViewport` is a thin wrapper around `ScrollView` that captures the viewport geometry **before** SwiftUI hands control to the scroll view. Once you're already inside a `ScrollView`, a `GeometryReader` only knows about its own content, not the surrounding container, so sizing logic quickly becomes blind. `ScrollViewport` records that outer geometry exactly once and re-injects it through a `Viewport` environment value so every descendant can still reason about the original viewport.

## When to Use It

- You need the scroll container's size inside lazily loaded content (e.g., to size cards, carousels, or grid items).
- You need geometry information that would otherwise be lost after entering a `ScrollView` where `GeometryReader` reports the content's space instead of the viewport.
- You nest scroll views and only want the outermost one to pay the geometry-measurement cost.

`ScrollViewport` tracks a private `viewportDepth` in the environment so only the first level injects the measurement; inner scroll views behave like plain `ScrollView`s.

## Example

```swift
private struct CarouselView: View {
    var body: some View {
        ScrollViewport {
            TextCarousel()
        }
    }
}

private struct TextCarousel: View {
    @Environment(\.viewport) private var viewport

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(alignment: .top, spacing: 0) {
                ForEach(0 ..< 10) { idx in
                    Text("#\(idx): " + HipsterLorem.paragraphs(1, seed: UInt64(idx)))
                        .frame(width: viewport.size.width * 0.6) // Viewport used here
                        .padding()
                        .background(Color.secondary.opacity(0.2))
                        .cornerRadius(8)
                        .padding(.leading, 8)
                }
            }
        }
    }
}
```

Inside the hierarchy you can read the viewport via the `.viewport` environment key; the nested `FeaturedCarousel` uses it to size cards relative to the screen and respect safe areas. The `Viewport` value includes both `size` and `safeAreaInsets`, which is handy for layouts targeting full-screen presentations. `ScrollViewport` shines when inner content needs to spin up its own `ScrollView`, because the outer viewport captures the device geometry before the inner scroll view changes the coordinate space. The inner `ScrollView` behaves normally, but every descendant can still read the outer viewport to size cards, adjust safe-area padding, or drive animations.

## Tips

- Combine with lazy stacks/grids to keep large feeds performant while still adapting item widths to the container.
- Read `viewport.safeAreaInsets` when you need precise padding for edge-to-edge designs.
- If you deliberately need a new measurement inside a nested scroll, wrap that section in a plain `ScrollView` + `GeometryReader` manually.
