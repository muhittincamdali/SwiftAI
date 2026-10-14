#if canImport(SwiftUI)
import Foundation
import SwiftUI
import Testing
@testable import SwiftAI

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// Training the four models takes a few seconds, so all tests share one result.
private let boundaryPanels = Result { try BoundaryPanel.iris() }

/// Renders the decision-boundary gallery from DecisionBoundaries.swift off screen. This checks
/// that the four models train and the view draws, and, when `IMAGE_DIR` is set, writes the
/// README images (see scripts/generate-images.sh).
@MainActor
@Suite("Rendering")
struct RenderTests {
    @Test("The boundary panels predict every grid cell")
    func panels() throws {
        let panels = try boundaryPanels.get()
        #expect(panels.map(\.name) == ["k-nearest neighbours", "Logistic regression", "Decision tree", "Neural network"])
        for panel in panels {
            #expect(panel.cells.count == BoundaryPanel.rows)
            #expect(panel.cells.allSatisfy { $0.count == BoundaryPanel.columns })
            // Every species owns part of the plane, and the cross-validated accuracy is high.
            #expect(Set(panel.cells.joined()) == [0, 1, 2])
            #expect(panel.accuracy > 0.9)
        }
    }

    @Test("The gallery renders in light and dark", arguments: [ColorScheme.light, .dark])
    func gallery(scheme: ColorScheme) throws {
        guard #available(iOS 16, macOS 13, tvOS 16, watchOS 9, visionOS 1, *) else { return }
        let view = DecisionBoundaryGallery(panels: try boundaryPanels.get(), samples: try BoundaryPanel.petalData())
            .frame(width: 780)
            .background(scheme == .dark ? Color(red: 13 / 255, green: 17 / 255, blue: 23 / 255) : .white)
            .environment(\.colorScheme, scheme)
        let renderer = ImageRenderer(content: view)
        renderer.scale = 2
        let image = try #require(renderer.cgImage)
        #expect(image.width == 1560)
        #expect(image.height > 800)

        if let directory = ProcessInfo.processInfo.environment["IMAGE_DIR"] {
            let name = "decision-boundaries-\(scheme == .dark ? "dark" : "light").png"
            try writePNG(image, to: URL(fileURLWithPath: directory).appendingPathComponent(name))
        }
    }

    private func writePNG(_ image: CGImage, to url: URL) throws {
        #if canImport(UIKit)
        let data = try #require(UIImage(cgImage: image).pngData())
        #else
        let data = try #require(NSBitmapImageRep(cgImage: image).representation(using: .png, properties: [:]))
        #endif
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try data.write(to: url)
    }
}
#endif
