import SwiftUI

struct Viewport {
    let size: CGSize
    let safeAreaInsets: EdgeInsets

    init(size: CGSize, safeAreaInsets: EdgeInsets? = nil) {
        self.size = size
        self.safeAreaInsets = safeAreaInsets ?? .init(top: 0, leading: 0, bottom: 0, trailing: 0)
    }

    init(length: CGFloat) {
        size = CGSize(width: length, height: length)
        safeAreaInsets = .init(top: 0, leading: 0, bottom: 0, trailing: 0)
    }

    static func width(_ length: CGFloat) -> Self {
        .init(length: length)
    }
}

// MARK: - Environment

private struct ViewportKey: EnvironmentKey {
    static let defaultValue: Viewport = .init(size: .zero, safeAreaInsets: EdgeInsets())
}

extension EnvironmentValues {
    var viewport: Viewport {
        get { self[ViewportKey.self] }
        set { self[ViewportKey.self] = newValue }
    }
}

// Tracks nesting depth for ScrollViewport to avoid re-injecting viewport
private struct ViewportDepthKey: EnvironmentKey {
    static let defaultValue: Int = 0
}

extension EnvironmentValues {
    var viewportDepth: Int {
        get { self[ViewportDepthKey.self] }
        set { self[ViewportDepthKey.self] = newValue }
    }
}

/// A convenience wrapper around `ScrollView` that injects the current
/// `Viewport`, but only for the first level of nesting.
struct ScrollViewport<Content: View>: View {
    let axes: Axis.Set
    let showsIndicators: Bool
    private let content: () -> Content

    @Environment(\.viewportDepth) private var viewportDepth

    init(
        _ axes: Axis.Set = .vertical,
        showsIndicators: Bool = true,
        @ViewBuilder content: @escaping () -> Content,
    ) {
        self.axes = axes
        self.showsIndicators = showsIndicators
        self.content = content
    }

    var body: some View {
        // If we're already inside a ScrollViewport, just render a ScrollView
        if viewportDepth > 0 {
            ScrollView(axes, showsIndicators: showsIndicators) {
                content()
            }
        } else {
            GeometryReader { geo in
                let viewport = Viewport(size: geo.size, safeAreaInsets: geo.safeAreaInsets)
                ScrollView(axes, showsIndicators: showsIndicators) {
                    content()
                }
                .environment(\.viewport, viewport)
                .environment(\.viewportDepth, viewportDepth + 1)
            }
        }
    }
}

// MARK: - Previews

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
        ScrollViewport {
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(alignment: .top, spacing: 0) {
                    ForEach(0 ..< 10) { idx in
                        Text("#\(idx): " + HipsterLorem.paragraphs(1, seed: UInt64(idx)))
                            .frame(width: viewport.size.width * 0.6)
                            .padding()
                            .background(Color.secondary.opacity(0.2))
                            .cornerRadius(8)
                            .padding(.leading, 8)
                    }
                }
            }

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(alignment: .top, spacing: 0) {
                    ForEach(10 ..< 20) { idx in
                        Text("#\(idx): " + HipsterLorem.paragraphs(1, seed: UInt64(idx)))
                            .frame(width: viewport.size.width * 0.6)
                            .padding()
                            .background(Color.secondary.opacity(0.2))
                            .cornerRadius(8)
                            .padding(.leading, 8)
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        CarouselView()
    }
}
