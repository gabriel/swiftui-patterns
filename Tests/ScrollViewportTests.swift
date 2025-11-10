@testable import SwiftUIPatterns
import Foundation
import SwiftUI
import SwiftUISnapshotTesting
import Testing

@MainActor
@Suite(.snapshots(record: .failed))
struct ScrollViewportTests {
    @Test
    func viewport() throws {
        let view = CarouselView()
            .background(Color.white)
        assertSnapshot(view: view, device: .any)
    }
}

// Example from the docs
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
