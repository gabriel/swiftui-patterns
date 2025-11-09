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
        let view = ScrollViewport(content: {
            ForEach(0 ..< 100) { index in
                Text("Item \(index)")
            }
        })
        assertSnapshot(view: view)
    }
}
