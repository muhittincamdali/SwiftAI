import Foundation

/// A classifier that averages the class probabilities of many decision trees.
///
/// Each tree is trained on a bootstrap sample (drawn with replacement) and considers only a
/// random subset of the features at each split. The average is much less sensitive to noise than
/// a single tree. Trees are trained in parallel; the same `seed` always gives the same forest.
///
/// ```swift
/// let forest = try RandomForestClassifier.fit(training, treeCount: 200, seed: 42)
/// let species = try forest.predict([6.3, 2.8, 5.1, 1.5])
/// ```
public struct RandomForestClassifier<Label: Hashable & Sendable>: ProbabilisticClassifier {
    public let classes: [Label]
    let trees: [TreeModel]

    public var featureCount: Int { trees[0].featureCount }
    /// The number of trees.
    public var treeCount: Int { trees.count }
    /// The mean of the trees' feature importances.
    public var featureImportances: [Double] { meanImportances(trees) }

    /// Trains the forest.
    ///
    /// - Parameters:
    ///   - data: The training samples.
    ///   - treeCount: The number of trees, at least 1.
    ///   - maxDepth: The most splits from the root to a leaf in each tree; `nil` for no limit.
    ///   - minSamplesLeaf: Every leaf keeps at least this many samples.
    ///   - maxFeatures: The features tried at each split; the square root of the feature count
    ///     (rounded down, at least 1) when `nil`, as in scikit-learn.
    ///   - seed: Determines the bootstrap samples and feature subsets.
    /// - Throws: ``SwiftAIError/invalidParameter(name:reason:)`` for invalid settings.
    public static func fit(
        _ data: Dataset<Label>, treeCount: Int = 100, maxDepth: Int? = nil, minSamplesLeaf: Int = 1,
        maxFeatures: Int? = nil, seed: UInt64 = 0
    ) throws -> RandomForestClassifier {
        let settings = TreeSettings(
            maxDepth: maxDepth, minSamplesSplit: 2, minSamplesLeaf: minSamplesLeaf,
            maxFeatures: maxFeatures ?? max(1, Int(Double(data.featureCount).squareRoot()))
        )
        try settings.validate(featureCount: data.featureCount)
        try requirePositive(treeCount, "treeCount")
        let index = ClassIndex(data.targets)
        let targets = TreeTargets.classes(index.encode(data.targets), classCount: index.classes.count)
        let trees = growForest(data.features, targets, settings: settings, treeCount: treeCount, seed: seed)
        return RandomForestClassifier(classes: index.classes, trees: trees)
    }

    init(classes: [Label], trees: [TreeModel]) {
        self.classes = classes
        self.trees = trees
    }

    /// The mean of the trees' class probabilities.
    public func classProbabilities(_ sample: [Double]) throws -> [Double] {
        try checkSample(sample, featureCount: featureCount)
        var sums = [Double](repeating: 0, count: classes.count)
        for tree in trees {
            for (index, share) in tree.leaf(for: sample).value.enumerated() {
                sums[index] += share
            }
        }
        return sums.map { $0 / Double(trees.count) }
    }

    public func predict(_ sample: [Double]) throws -> Label {
        classes[argmax(try classProbabilities(sample))]
    }
}

extension RandomForestClassifier: Equatable where Label: Equatable {}

extension RandomForestClassifier: Codable where Label: Codable {
    private enum CodingKeys: String, CodingKey {
        case classes, featureCount, trees
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let classes = try container.decode([Label].self, forKey: .classes)
        try requireValidClasses(classes)
        let trees = try decodeTrees(container, featureKey: .featureCount, treesKey: .trees, valueCount: classes.count)
        self.init(classes: classes, trees: trees)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(classes, forKey: .classes)
        try container.encode(featureCount, forKey: .featureCount)
        try container.encode(trees.map(\.nodes), forKey: .trees)
    }
}

/// A regressor that averages the predictions of many decision trees.
///
/// ```swift
/// let forest = try RandomForestRegressor.fit(houses, treeCount: 100)
/// let price = try forest.predict([100, 2])
/// ```
public struct RandomForestRegressor: Regressor, Equatable, Codable {
    let trees: [TreeModel]

    public var featureCount: Int { trees[0].featureCount }
    /// The number of trees.
    public var treeCount: Int { trees.count }
    /// The mean of the trees' feature importances.
    public var featureImportances: [Double] { meanImportances(trees) }

    /// Trains the forest.
    ///
    /// - Parameters:
    ///   - data: The training samples.
    ///   - treeCount: The number of trees, at least 1.
    ///   - maxDepth: The most splits from the root to a leaf in each tree; `nil` for no limit.
    ///   - minSamplesLeaf: Every leaf keeps at least this many samples.
    ///   - maxFeatures: The features tried at each split; all of them when `nil`, as in
    ///     scikit-learn.
    ///   - seed: Determines the bootstrap samples and feature subsets.
    /// - Throws: ``SwiftAIError/invalidParameter(name:reason:)`` for invalid settings or targets
    ///   too large to compute with, and ``SwiftAIError/nonFiniteTarget(row:)``.
    public static func fit(
        _ data: Dataset<Double>, treeCount: Int = 100, maxDepth: Int? = nil, minSamplesLeaf: Int = 1,
        maxFeatures: Int? = nil, seed: UInt64 = 0
    ) throws -> RandomForestRegressor {
        let settings = TreeSettings(
            maxDepth: maxDepth, minSamplesSplit: 2, minSamplesLeaf: minSamplesLeaf, maxFeatures: maxFeatures
        )
        try settings.validate(featureCount: data.featureCount)
        try requirePositive(treeCount, "treeCount")
        try checkRegressionTargets(data.targets)
        let trees = growForest(data.features, .values(data.targets), settings: settings, treeCount: treeCount, seed: seed)
        return RandomForestRegressor(trees: trees)
    }

    init(trees: [TreeModel]) {
        self.trees = trees
    }

    public func predict(_ sample: [Double]) throws -> Double {
        try checkSample(sample, featureCount: featureCount)
        // Leaf values lie between the smallest and largest target, so the mean of the trees'
        // predictions is computed incrementally to keep it in that range without overflowing.
        var mean = 0.0
        for (offset, tree) in trees.enumerated() {
            mean += (tree.leaf(for: sample).value[0] - mean) / Double(offset + 1)
        }
        return try finitePrediction(mean)
    }

    private enum CodingKeys: String, CodingKey {
        case featureCount, trees
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        trees = try decodeTrees(container, featureKey: .featureCount, treesKey: .trees, valueCount: 1)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(featureCount, forKey: .featureCount)
        try container.encode(trees.map(\.nodes), forKey: .trees)
    }
}

/// Trains `treeCount` trees on bootstrap samples, in parallel.
///
/// Each tree gets its own generator, seeded in order from `seed`, so the result does not depend
/// on which thread trains which tree.
private func growForest(
    _ features: Matrix, _ targets: TreeTargets, settings: TreeSettings, treeCount: Int, seed: UInt64
) -> [TreeModel] {
    var seeds = SeededGenerator(seed: seed)
    let treeSeeds = (0..<treeCount).map { _ in seeds.next() }
    let results = TreeResults(count: treeCount)
    let sampleCount = features.rows
    DispatchQueue.concurrentPerform(iterations: treeCount) { index in
        var generator = SeededGenerator(seed: treeSeeds[index])
        let bootstrap = (0..<sampleCount).map { _ in generator.nextIndex(below: sampleCount) }
        let tree = buildTree(features: features, targets: targets, samples: bootstrap, settings: settings, generator: &generator)
        results.store(tree, at: index)
    }
    return results.trees
}

/// Collects the trees that the parallel loop trains.
private final class TreeResults: @unchecked Sendable {
    private let lock = NSLock()
    private var slots: [TreeModel?]

    init(count: Int) {
        slots = Array(repeating: nil, count: count)
    }

    func store(_ tree: TreeModel, at index: Int) {
        lock.withLock { slots[index] = tree }
    }

    var trees: [TreeModel] {
        lock.withLock { slots.map { $0! } }
    }
}

private func meanImportances(_ trees: [TreeModel]) -> [Double] {
    var sums = [Double](repeating: 0, count: trees[0].featureCount)
    for tree in trees {
        for (index, value) in tree.impurityDecreases.enumerated() {
            sums[index] += value
        }
    }
    return sums.map { $0 / Double(trees.count) }
}

private func decodeTrees<Key: CodingKey>(
    _ container: KeyedDecodingContainer<Key>, featureKey: Key, treesKey: Key, valueCount: Int
) throws -> [TreeModel] {
    let featureCount = try container.decode(Int.self, forKey: featureKey)
    let nodeLists = try container.decode([[TreeNode]].self, forKey: treesKey)
    try requireConsistent(!nodeLists.isEmpty, "the forest has no trees")
    return try nodeLists.map { try TreeModel(validating: $0, featureCount: featureCount, valueCount: valueCount) }
}
