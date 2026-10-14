/// A classifier that learns a tree of yes/no questions about the features.
///
/// Each split asks whether one feature is at most a threshold; each leaf holds the class shares
/// of the training samples that reached it. Trees need no feature scaling and are easy to
/// explain, but a deep tree memorizes noise: limit `maxDepth` or `minSamplesLeaf`, or use a
/// ``RandomForestClassifier``.
///
/// ```swift
/// let tree = try DecisionTreeClassifier.fit(training, maxDepth: 3)
/// tree.featureImportances   // which features the splits rely on
/// ```
public struct DecisionTreeClassifier<Label: Hashable & Sendable>: ProbabilisticClassifier {
    public let classes: [Label]
    let tree: TreeModel

    public var featureCount: Int { tree.featureCount }
    /// The number of splits on the longest path from the root to a leaf.
    public var depth: Int { tree.depth }
    /// The number of leaves.
    public var leafCount: Int { tree.leafCount }
    /// How much each feature's splits reduce the Gini impurity, as shares that add up to 1
    /// (all 0 when the tree has no splits).
    public var featureImportances: [Double] { tree.impurityDecreases }

    /// Grows the tree with the CART algorithm and the Gini impurity.
    ///
    /// Among splits that are equally good, the one on the lower feature index wins, so the
    /// result is deterministic.
    ///
    /// - Parameters:
    ///   - maxDepth: The most splits from the root to a leaf; `nil` grows until leaves are pure.
    ///   - minSamplesSplit: A node needs at least this many samples to be split (at least 2).
    ///   - minSamplesLeaf: Every leaf keeps at least this many samples.
    /// - Throws: ``SwiftAIError/invalidParameter(name:reason:)`` for invalid limits.
    public static func fit(
        _ data: Dataset<Label>, maxDepth: Int? = nil, minSamplesSplit: Int = 2, minSamplesLeaf: Int = 1
    ) throws -> DecisionTreeClassifier {
        let settings = TreeSettings(maxDepth: maxDepth, minSamplesSplit: minSamplesSplit, minSamplesLeaf: minSamplesLeaf)
        try settings.validate(featureCount: data.featureCount)
        let index = ClassIndex(data.targets)
        var generator = SeededGenerator(seed: 0)
        let tree = buildTree(
            features: data.features, targets: .classes(index.encode(data.targets), classCount: index.classes.count),
            samples: Array(0..<data.count), settings: settings, generator: &generator
        )
        return DecisionTreeClassifier(classes: index.classes, tree: tree)
    }

    init(classes: [Label], tree: TreeModel) {
        self.classes = classes
        self.tree = tree
    }

    /// The class shares of the training samples in the sample's leaf.
    public func classProbabilities(_ sample: [Double]) throws -> [Double] {
        try checkSample(sample, featureCount: featureCount)
        return tree.leaf(for: sample).value
    }

    public func predict(_ sample: [Double]) throws -> Label {
        classes[argmax(try classProbabilities(sample))]
    }
}

extension DecisionTreeClassifier: Equatable where Label: Equatable {}

extension DecisionTreeClassifier: Codable where Label: Codable {
    private enum CodingKeys: String, CodingKey {
        case classes, featureCount, nodes
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let classes = try container.decode([Label].self, forKey: .classes)
        try requireValidClasses(classes)
        let tree = try TreeModel(
            validating: container.decode([TreeNode].self, forKey: .nodes),
            featureCount: container.decode(Int.self, forKey: .featureCount), valueCount: classes.count
        )
        self.init(classes: classes, tree: tree)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(classes, forKey: .classes)
        try container.encode(tree.featureCount, forKey: .featureCount)
        try container.encode(tree.nodes, forKey: .nodes)
    }
}

/// A regressor that learns a tree of yes/no questions and predicts the mean target of a leaf.
///
/// ```swift
/// let tree = try DecisionTreeRegressor.fit(houses, maxDepth: 4)
/// let price = try tree.predict([100, 2])
/// ```
public struct DecisionTreeRegressor: Regressor, Equatable, Codable {
    let tree: TreeModel

    public var featureCount: Int { tree.featureCount }
    /// The number of splits on the longest path from the root to a leaf.
    public var depth: Int { tree.depth }
    /// The number of leaves.
    public var leafCount: Int { tree.leafCount }
    /// How much each feature's splits reduce the squared error, as shares that add up to 1.
    public var featureImportances: [Double] { tree.impurityDecreases }

    /// Grows the tree with the CART algorithm and the squared error.
    ///
    /// - Throws: The errors of ``DecisionTreeClassifier/fit(_:maxDepth:minSamplesSplit:minSamplesLeaf:)``,
    ///   ``SwiftAIError/nonFiniteTarget(row:)``, and ``SwiftAIError/invalidParameter(name:reason:)``
    ///   when the targets are too large for their squared error to be represented.
    public static func fit(
        _ data: Dataset<Double>, maxDepth: Int? = nil, minSamplesSplit: Int = 2, minSamplesLeaf: Int = 1
    ) throws -> DecisionTreeRegressor {
        let settings = TreeSettings(maxDepth: maxDepth, minSamplesSplit: minSamplesSplit, minSamplesLeaf: minSamplesLeaf)
        try settings.validate(featureCount: data.featureCount)
        try checkRegressionTargets(data.targets)
        var generator = SeededGenerator(seed: 0)
        let tree = buildTree(
            features: data.features, targets: .values(data.targets),
            samples: Array(0..<data.count), settings: settings, generator: &generator
        )
        return DecisionTreeRegressor(tree: tree)
    }

    init(tree: TreeModel) {
        self.tree = tree
    }

    public func predict(_ sample: [Double]) throws -> Double {
        try checkSample(sample, featureCount: featureCount)
        return tree.leaf(for: sample).value[0]
    }

    private enum CodingKeys: String, CodingKey {
        case featureCount, nodes
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        tree = try TreeModel(
            validating: container.decode([TreeNode].self, forKey: .nodes),
            featureCount: container.decode(Int.self, forKey: .featureCount), valueCount: 1
        )
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(tree.featureCount, forKey: .featureCount)
        try container.encode(tree.nodes, forKey: .nodes)
    }
}

/// Regression trees sum squared deviations of the targets; they must fit in a `Double`.
func checkRegressionTargets(_ targets: [Double]) throws {
    try checkFinite(targets: targets)
    var mean = 0.0
    for (offset, value) in targets.enumerated() {
        mean += (value - mean) / Double(offset + 1)
    }
    let deviation = populationDeviation(targets, mean: mean)
    try requireRepresentable([mean, Double(targets.count) * deviation * deviation])
}
