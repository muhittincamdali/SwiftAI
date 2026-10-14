/// One node of a fitted decision tree.
///
/// A split node sends a sample left when `sample[feature] <= threshold`. Child indices are always
/// larger than the parent's index, so following them from the root ends after at most
/// `nodes.count` steps, also for a tree read from a file.
struct TreeNode: Sendable, Equatable, Codable {
    /// The feature a split node tests, or -1 for a leaf.
    var feature: Int
    var threshold: Double
    var left: Int
    var right: Int
    /// Class probabilities (classification) or the mean target (regression) of the training
    /// samples that reached the node.
    var value: [Double]
    /// Gini impurity or mean squared error of those samples.
    var impurity: Double
    var sampleCount: Int

    var isLeaf: Bool { feature < 0 }

    static let leafFeature = -1
}

/// A fitted decision tree: nodes in an array, the root first.
struct TreeModel: Sendable, Equatable, Codable {
    let nodes: [TreeNode]
    let featureCount: Int

    init(nodes: [TreeNode], featureCount: Int) {
        self.nodes = nodes
        self.featureCount = featureCount
    }

    /// The leaf a sample ends in. The sample must have `featureCount` finite values.
    func leaf(for sample: [Double]) -> TreeNode {
        var node = nodes[0]
        while !node.isLeaf {
            node = nodes[sample[node.feature] <= node.threshold ? node.left : node.right]
        }
        return node
    }

    /// The number of splits on the longest path from the root to a leaf.
    var depth: Int {
        var depths = [Int](repeating: 0, count: nodes.count)
        for (index, node) in nodes.enumerated() where !node.isLeaf {
            depths[node.left] = depths[index] + 1
            depths[node.right] = depths[index] + 1
        }
        return depths.max() ?? 0
    }

    var leafCount: Int { nodes.count(where: \.isLeaf) }

    /// The total impurity decrease of the splits on each feature, normalized to add up to 1.
    var impurityDecreases: [Double] {
        var decreases = [Double](repeating: 0, count: featureCount)
        for node in nodes where !node.isLeaf {
            let left = nodes[node.left]
            let right = nodes[node.right]
            let decrease = Double(node.sampleCount) * node.impurity
                - Double(left.sampleCount) * left.impurity - Double(right.sampleCount) * right.impurity
            decreases[node.feature] += max(decrease, 0)
        }
        let total = decreases.reduce(0, +)
        guard total > 0, total.isFinite else { return decreases.map { _ in 0 } }
        return decreases.map { $0 / total }
    }

    /// Checks a tree read from a file: every split refers to an existing feature and to two
    /// later nodes, values have the expected length and every number is finite.
    init(validating nodes: [TreeNode], featureCount: Int, valueCount: Int) throws {
        try requireConsistent(!nodes.isEmpty, "the tree has no nodes")
        try requireConsistent(featureCount > 0, "the tree has no features")
        for (index, node) in nodes.enumerated() {
            try requireConsistent(node.value.count == valueCount, "node \(index) has \(node.value.count) values, expected \(valueCount)")
            try requireFinite(node.value + [node.impurity], "node \(index)")
            try requireConsistent(node.impurity >= 0 && node.sampleCount > 0, "node \(index) has invalid statistics")
            if node.isLeaf {
                try requireConsistent(node.feature == TreeNode.leafFeature, "node \(index) has an invalid feature index")
                continue
            }
            try requireConsistent(node.feature < featureCount, "node \(index) tests feature \(node.feature) of \(featureCount)")
            try requireConsistent(node.threshold.isFinite, "node \(index) has a non-finite threshold")
            let childRange = (index + 1)..<nodes.count
            try requireConsistent(
                childRange.contains(node.left) && childRange.contains(node.right) && node.left != node.right,
                "node \(index) refers to invalid children"
            )
        }
        self.init(nodes: nodes, featureCount: featureCount)
    }
}

/// The settings that limit how far a tree grows.
struct TreeSettings: Sendable {
    var maxDepth: Int?
    var minSamplesSplit: Int
    var minSamplesLeaf: Int
    /// The number of features tried at each split; all of them when `nil`.
    var maxFeatures: Int?

    func validate(featureCount: Int) throws {
        if let maxDepth {
            guard maxDepth >= 0 else {
                throw SwiftAIError.invalidParameter(name: "maxDepth", reason: "must be at least 0, got \(maxDepth)")
            }
        }
        guard minSamplesSplit >= 2 else {
            throw SwiftAIError.invalidParameter(name: "minSamplesSplit", reason: "must be at least 2, got \(minSamplesSplit)")
        }
        try requirePositive(minSamplesLeaf, "minSamplesLeaf")
        if let maxFeatures {
            guard (1...featureCount).contains(maxFeatures) else {
                throw SwiftAIError.invalidParameter(
                    name: "maxFeatures", reason: "must be between 1 and the feature count \(featureCount), got \(maxFeatures)"
                )
            }
        }
    }
}
