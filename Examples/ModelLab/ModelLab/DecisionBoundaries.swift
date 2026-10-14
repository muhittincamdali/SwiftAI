// Draws what four classifiers predict over the iris petal measurements. The ModelLab app shows
// it, and the package's test target (through the symlink Tests/SwiftAITests/DecisionBoundaries.swift)
// renders it into the README image with scripts/generate-images.sh.

#if canImport(SwiftUI)
import SwiftAI
import SwiftUI

/// One model's predictions over a grid of petal sizes.
struct BoundaryPanel: Identifiable, Sendable {
    let name: String
    /// Mean accuracy of 5-fold cross-validation on the petal features.
    let accuracy: Double
    /// The predicted class index of each grid cell, row by row from the bottom.
    let cells: [[Int]]

    var id: String { name }

    static let lengthRange = 0.5...7.5
    static let widthRange = 0.0...2.8
    static let columns = 56
    static let rows = 28

    /// The iris samples reduced to petal length and width.
    static func petalData() throws -> Dataset<String> {
        let rows = Dataset.iris.features.rowArrays.map { [$0[2], $0[3]] }
        return try Dataset(features: rows, targets: Dataset.iris.targets)
    }

    /// Trains four classifiers on the petal features and predicts every grid cell.
    static func iris() throws -> [BoundaryPanel] {
        let data = try petalData()
        func scaled(_ fit: @escaping (Dataset<String>) throws -> any Classifier<String>) -> (Dataset<String>) throws -> any Classifier<String> {
            { training in try ScaledModel.fit(training, fit) }
        }
        let models: [(String, (Dataset<String>) throws -> any Classifier<String>)] = [
            ("k-nearest neighbours", scaled { try KNearestNeighborsClassifier.fit($0, k: 15) }),
            ("Logistic regression", scaled { try LogisticRegression.fit($0) }),
            ("Decision tree", { try DecisionTreeClassifier.fit($0, maxDepth: 3) }),
            ("Neural network", scaled { try NeuralNetworkClassifier.fit($0, hiddenLayers: [16], learningRate: 0.01, epochs: 300, seed: 1) }),
        ]
        return try models.map { name, fit in
            let scores = try data.stratifiedFolds(5, seed: 0).map { fold in
                try fit(fold.training).accuracy(on: fold.validation)
            }
            let model = try fit(data)
            let cells = try (0..<rows).map { row in
                try (0..<columns).map { column in
                    let sample = [value(column, of: columns, in: lengthRange), value(row, of: rows, in: widthRange)]
                    return model.classes.firstIndex(of: try model.predict(sample)) ?? 0
                }
            }
            return BoundaryPanel(name: name, accuracy: scores.reduce(0, +) / Double(scores.count), cells: cells)
        }
    }

    /// The centre of grid cell `index` of `count` cells spanning `range`.
    static func value(_ index: Int, of count: Int, in range: ClosedRange<Double>) -> Double {
        range.lowerBound + (Double(index) + 0.5) / Double(count) * (range.upperBound - range.lowerBound)
    }
}

/// A standard scaler in front of a model, erased to `any Classifier` so different models fit in one list.
struct ScaledModel: Classifier {
    let scaler: StandardScaler
    let model: any Classifier<String>

    static func fit(_ data: Dataset<String>, _ fit: (Dataset<String>) throws -> any Classifier<String>) throws -> ScaledModel {
        let scaler = try StandardScaler.fit(data)
        return ScaledModel(scaler: scaler, model: try fit(scaler.transform(data)))
    }

    var featureCount: Int { scaler.inputFeatureCount }
    var classes: [String] { model.classes }

    func predict(_ sample: [Double]) throws -> String {
        try model.predict(scaler.transform(sample))
    }
}

/// The three iris species in the blues of the project palette.
enum SpeciesPalette {
    static func color(_ index: Int, _ scheme: ColorScheme) -> Color {
        rgb(index, scheme).color
    }

    /// The species colour blended into the page background, for the predicted regions. Opaque,
    /// so neighbouring cells can overlap without visible seams.
    static func region(_ index: Int, _ scheme: ColorScheme) -> Color {
        let (red, green, blue) = rgb(index, scheme).components
        let background: (Double, Double, Double) = scheme == .dark ? (13, 17, 23) : (255, 255, 255)
        let alpha = scheme == .dark ? 0.35 : 0.28
        return Color(
            red: (red * alpha + background.0 * (1 - alpha)) / 255,
            green: (green * alpha + background.1 * (1 - alpha)) / 255,
            blue: (blue * alpha + background.2 * (1 - alpha)) / 255
        )
    }

    private static func rgb(_ index: Int, _ scheme: ColorScheme) -> (components: (Double, Double, Double), color: Color) {
        let light: [UInt32] = [0x8CC4FF, 0x0071E3, 0x003A85]
        let dark: [UInt32] = [0xD0E2F7, 0x64D2FF, 0x0A84FF]
        let hex = (scheme == .dark ? dark : light)[index % 3]
        let components = (Double(hex >> 16 & 0xFF), Double(hex >> 8 & 0xFF), Double(hex & 0xFF))
        return (components, Color(red: components.0 / 255, green: components.1 / 255, blue: components.2 / 255))
    }
}

/// The predicted regions of one model, with the iris samples on top.
struct DecisionBoundaryView: View {
    let panel: BoundaryPanel
    let samples: Dataset<String>
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text(panel.name).font(.headline)
                Spacer()
                Text("CV accuracy \(panel.accuracy.formatted(.percent.precision(.fractionLength(1)).locale(Locale(identifier: "en_US"))))")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            Canvas { context, size in
                draw(in: &context, size: size)
            }
            .aspectRatio(2, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            HStack {
                Text("→ petal length, 0.5–7.5 cm")
                Spacer()
                Text("↑ petal width, 0–2.8 cm")
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
    }

    private func draw(in context: inout GraphicsContext, size: CGSize) {
        let cellWidth = size.width / CGFloat(BoundaryPanel.columns)
        let cellHeight = size.height / CGFloat(BoundaryPanel.rows)
        for (row, classes) in panel.cells.enumerated() {
            for (column, species) in classes.enumerated() {
                let rect = CGRect(
                    x: CGFloat(column) * cellWidth, y: size.height - CGFloat(row + 1) * cellHeight,
                    width: cellWidth + 0.5, height: cellHeight + 0.5
                )
                context.fill(Path(rect), with: .color(SpeciesPalette.region(species, scheme)))
            }
        }
        let classes = Array(Set(samples.targets)).sorted()
        for index in 0..<samples.count {
            let x = (samples.features[index, 0] - BoundaryPanel.lengthRange.lowerBound)
                / (BoundaryPanel.lengthRange.upperBound - BoundaryPanel.lengthRange.lowerBound)
            let y = (samples.features[index, 1] - BoundaryPanel.widthRange.lowerBound)
                / (BoundaryPanel.widthRange.upperBound - BoundaryPanel.widthRange.lowerBound)
            let center = CGPoint(x: x * size.width, y: (1 - y) * size.height)
            let dot = Path(ellipseIn: CGRect(x: center.x - 3.5, y: center.y - 3.5, width: 7, height: 7))
            let species = classes.firstIndex(of: samples.targets[index]) ?? 0
            context.fill(dot, with: .color(SpeciesPalette.color(species, scheme)))
            context.stroke(dot, with: .color(scheme == .dark ? .black : .white), lineWidth: 1)
        }
    }
}

/// Four models side by side with a legend: the README image and the app's Boundaries tab.
struct DecisionBoundaryGallery: View {
    let panels: [BoundaryPanel]
    let samples: Dataset<String>
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Four SwiftAI classifiers on the iris petal measurements")
                .font(.title3.weight(.semibold))
            HStack(spacing: 16) {
                ForEach(Array(["setosa", "versicolor", "virginica"].enumerated()), id: \.offset) { index, name in
                    HStack(spacing: 6) {
                        Circle().fill(SpeciesPalette.color(index, scheme)).frame(width: 10, height: 10)
                        Text(name).font(.caption)
                    }
                }
            }
            // Plain stacks instead of a lazy grid, so that ImageRenderer draws every panel.
            VStack(spacing: 20) {
                ForEach(Array(stride(from: 0, to: panels.count, by: 2)), id: \.self) { start in
                    HStack(alignment: .top, spacing: 20) {
                        ForEach(panels[start..<min(start + 2, panels.count)]) { panel in
                            DecisionBoundaryView(panel: panel, samples: samples)
                        }
                    }
                }
            }
        }
        .padding(24)
    }
}
#endif
