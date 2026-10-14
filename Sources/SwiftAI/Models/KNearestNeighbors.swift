/// How the k nearest neighbours of a sample count towards its prediction.
public enum NeighborWeighting: String, Sendable, Codable, CaseIterable {
    /// Every neighbour counts the same.
    case uniform
    /// Closer neighbours count more: each one is weighted by 1 / distance. Training samples at
    /// distance 0 decide alone.
    case distance
}

/// Predicts the majority label among the `k` training samples closest to a sample.
///
/// k-nearest neighbours learns nothing up front; it keeps the training data and compares every
/// new sample with it (Euclidean distance). Scale the features first, for example with a
/// ``Pipeline`` and ``StandardScaler``, so that a feature with large numbers does not dominate the
/// distance.
///
/// ```swift
/// let model = try KNearestNeighborsClassifier.fit(training, k: 5)
/// let species = try model.predict([5.9, 3.0, 4.2, 1.5])
/// ```
public struct KNearestNeighborsClassifier<Label: Hashable & Sendable>: ProbabilisticClassifier {
    /// The number of neighbours that vote.
    public let k: Int
    /// How the votes are weighted.
    public let weighting: NeighborWeighting
    public let classes: [Label]
    let neighbors: NeighborSearch
    let targetIndices: [Int]

    public var featureCount: Int { neighbors.features.columns }

    /// Stores the training data.
    ///
    /// - Throws: ``SwiftAIError/invalidParameter(name:reason:)`` when `k` is less than 1 and
    ///   ``SwiftAIError/insufficientSamples(required:actual:)`` when `k` exceeds the number of samples.
    public static func fit(
        _ data: Dataset<Label>, k: Int = 5, weighting: NeighborWeighting = .uniform
    ) throws -> KNearestNeighborsClassifier {
        try checkNeighborCount(k, sampleCount: data.count)
        let index = ClassIndex(data.targets)
        return KNearestNeighborsClassifier(
            k: k, weighting: weighting, classes: index.classes,
            neighbors: NeighborSearch(features: data.features), targetIndices: index.encode(data.targets)
        )
    }

    private init(k: Int, weighting: NeighborWeighting, classes: [Label], neighbors: NeighborSearch, targetIndices: [Int]) {
        self.k = k
        self.weighting = weighting
        self.classes = classes
        self.neighbors = neighbors
        self.targetIndices = targetIndices
    }

    /// The weighted share of the neighbours' votes for each class.
    public func classProbabilities(_ sample: [Double]) throws -> [Double] {
        try checkSample(sample, featureCount: featureCount)
        var votes = [Double](repeating: 0, count: classes.count)
        for (neighbor, weight) in try neighbors.weightedNeighbors(of: sample, k: k, weighting: weighting) {
            votes[targetIndices[neighbor]] += weight
        }
        let total = votes.reduce(0, +)
        return votes.map { $0 / total }
    }

    /// The label with the most (weighted) votes; a tie goes to the class seen first in training.
    public func predict(_ sample: [Double]) throws -> Label {
        classes[argmax(try classProbabilities(sample))]
    }
}

extension KNearestNeighborsClassifier: Equatable where Label: Equatable {}

extension KNearestNeighborsClassifier: Codable where Label: Codable {
    private enum CodingKeys: String, CodingKey {
        case k, weighting, classes, features, targetIndices
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let features = try container.decode(Matrix.self, forKey: .features)
        let classes = try container.decode([Label].self, forKey: .classes)
        let targetIndices = try container.decode([Int].self, forKey: .targetIndices)
        let k = try container.decode(Int.self, forKey: .k)
        try requireValidClasses(classes)
        try requireConsistent(targetIndices.count == features.rows, "there must be one target per training sample")
        try requireConsistent(targetIndices.allSatisfy(classes.indices.contains), "a target refers to an unknown class")
        try self.init(
            k: k, weighting: container.decode(NeighborWeighting.self, forKey: .weighting), classes: classes,
            neighbors: NeighborSearch(decoded: features, k: k), targetIndices: targetIndices
        )
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(k, forKey: .k)
        try container.encode(weighting, forKey: .weighting)
        try container.encode(classes, forKey: .classes)
        try container.encode(neighbors.features, forKey: .features)
        try container.encode(targetIndices, forKey: .targetIndices)
    }
}

/// Predicts the (weighted) mean target of the `k` training samples closest to a sample.
///
/// ```swift
/// let model = try KNearestNeighborsRegressor.fit(houses, k: 3, weighting: .distance)
/// let price = try model.predict([100, 2])
/// ```
public struct KNearestNeighborsRegressor: Regressor, Codable, Equatable {
    /// The number of neighbours that are averaged.
    public let k: Int
    /// How the neighbours are weighted.
    public let weighting: NeighborWeighting
    let neighbors: NeighborSearch
    let targets: [Double]

    public var featureCount: Int { neighbors.features.columns }

    /// Stores the training data.
    ///
    /// - Throws: The errors of ``KNearestNeighborsClassifier/fit(_:k:weighting:)``, and
    ///   ``SwiftAIError/nonFiniteTarget(row:)``.
    public static func fit(
        _ data: Dataset<Double>, k: Int = 5, weighting: NeighborWeighting = .uniform
    ) throws -> KNearestNeighborsRegressor {
        try checkNeighborCount(k, sampleCount: data.count)
        try checkFinite(targets: data.targets)
        return KNearestNeighborsRegressor(
            k: k, weighting: weighting, neighbors: NeighborSearch(features: data.features), targets: data.targets
        )
    }

    private init(k: Int, weighting: NeighborWeighting, neighbors: NeighborSearch, targets: [Double]) {
        self.k = k
        self.weighting = weighting
        self.neighbors = neighbors
        self.targets = targets
    }

    public func predict(_ sample: [Double]) throws -> Double {
        try checkSample(sample, featureCount: featureCount)
        var weightedSum = 0.0
        var totalWeight = 0.0
        for (neighbor, weight) in try neighbors.weightedNeighbors(of: sample, k: k, weighting: weighting) {
            weightedSum += weight * targets[neighbor]
            totalWeight += weight
        }
        return try finitePrediction(weightedSum / totalWeight)
    }

    private enum CodingKeys: String, CodingKey {
        case k, weighting, features, targets
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let features = try container.decode(Matrix.self, forKey: .features)
        let targets = try container.decode([Double].self, forKey: .targets)
        let k = try container.decode(Int.self, forKey: .k)
        try requireConsistent(targets.count == features.rows, "there must be one target per training sample")
        try requireFinite(targets, "targets")
        try self.init(
            k: k, weighting: container.decode(NeighborWeighting.self, forKey: .weighting),
            neighbors: NeighborSearch(decoded: features, k: k), targets: targets
        )
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(k, forKey: .k)
        try container.encode(weighting, forKey: .weighting)
        try container.encode(neighbors.features, forKey: .features)
        try container.encode(targets, forKey: .targets)
    }
}

/// Brute-force nearest-neighbour search over the training samples.
struct NeighborSearch: Sendable, Equatable {
    let features: Matrix

    init(features: Matrix) {
        self.features = features
    }

    /// Validates training features read from a file.
    init(decoded features: Matrix, k: Int) throws {
        try requireConsistent(features.rows > 0 && features.columns > 0, "there are no training samples")
        try requireFinite(features.values, "features")
        try requireConsistent(k >= 1 && k <= features.rows, "k must be between 1 and the number of samples")
        self.init(features: features)
    }

    /// The `k` nearest training samples and their weights. Equal distances are ordered by
    /// training index, so results do not depend on the sort algorithm.
    func weightedNeighbors(of sample: [Double], k: Int, weighting: NeighborWeighting) throws -> [(index: Int, weight: Double)] {
        let values = features.values
        let columns = features.columns
        let distances = (0..<features.rows).map { row in
            var sum = 0.0
            for column in 0..<columns {
                let difference = values[row * columns + column] - sample[column]
                sum += difference * difference
            }
            return sum
        }
        let nearest = (0..<features.rows)
            .sorted { distances[$0] == distances[$1] ? $0 < $1 : distances[$0] < distances[$1] }
            .prefix(k)
        // A squared distance that overflows would make every weight 0 or NaN.
        guard nearest.allSatisfy({ distances[$0].isFinite }) else {
            throw SwiftAIError.invalidParameter(
                name: "sample", reason: "the distances are too large to represent; rescale the features"
            )
        }
        switch weighting {
        case .uniform:
            return nearest.map { ($0, 1) }
        case .distance:
            if nearest.contains(where: { distances[$0] == 0 }) {
                return nearest.filter { distances[$0] == 0 }.map { ($0, 1) }
            }
            return nearest.map { ($0, 1 / distances[$0].squareRoot()) }
        }
    }
}

func checkNeighborCount(_ k: Int, sampleCount: Int) throws {
    try requirePositive(k, "k")
    guard k <= sampleCount else {
        throw SwiftAIError.insufficientSamples(required: k, actual: sampleCount)
    }
}

/// Checks the class list of a saved classifier: at least one class and no duplicates.
func requireValidClasses<Label: Hashable>(_ classes: [Label]) throws {
    try requireConsistent(!classes.isEmpty, "there are no classes")
    try requireConsistent(Set(classes).count == classes.count, "a class appears twice")
}
