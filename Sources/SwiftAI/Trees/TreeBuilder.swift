/// What a tree predicts and how it measures the impurity of a group of samples.
enum TreeTargets: Sendable {
    /// Class indices in `0..<classCount`; impurity is the Gini index.
    case classes([Int], classCount: Int)
    /// Numeric targets; impurity is the mean squared error.
    case values([Double])
}

/// Running statistics of a group of samples, updated one sample at a time during a split search.
private struct GroupStatistics {
    var count = 0
    var classCounts: [Double]
    var sum = 0.0
    var sumOfSquares = 0.0

    init(classCount: Int) {
        classCounts = [Double](repeating: 0, count: classCount)
    }

    mutating func add(_ index: Int, _ targets: TreeTargets, center: Double, sign: Double = 1) {
        count += sign > 0 ? 1 : -1
        switch targets {
        case let .classes(labels, _):
            classCounts[labels[index]] += sign
        case let .values(values):
            let centered = values[index] - center
            sum += sign * centered
            sumOfSquares += sign * centered * centered
        }
    }

    func impurity(_ targets: TreeTargets) -> Double {
        guard count > 0 else { return 0 }
        let total = Double(count)
        switch targets {
        case .classes:
            return 1 - classCounts.reduce(0) { $0 + ($1 / total) * ($1 / total) }
        case .values:
            let mean = sum / total
            return max(sumOfSquares / total - mean * mean, 0)
        }
    }

    func value(_ targets: TreeTargets, center: Double) -> [Double] {
        switch targets {
        case .classes:
            classCounts.map { $0 / Double(count) }
        case .values:
            [center + sum / Double(count)]
        }
    }
}

private struct Split {
    let feature: Int
    let threshold: Double
    let impurity: Double
}

/// Grows a decision tree with the CART algorithm.
///
/// The tree is built with an explicit stack instead of recursion, so a deep tree cannot overflow
/// the call stack. Children are appended after their parent, which keeps the invariant that
/// ``TreeModel`` relies on.
func buildTree(
    features: Matrix, targets: TreeTargets, samples: [Int], settings: TreeSettings, generator: inout SeededGenerator
) -> TreeModel {
    var nodes: [TreeNode] = []
    var pending: [(node: Int, samples: [Int], depth: Int)] = [(0, samples, 0)]
    nodes.append(TreeNode(feature: TreeNode.leafFeature, threshold: 0, left: -1, right: -1, value: [], impurity: 0, sampleCount: 0))

    while let (nodeIndex, members, depth) = pending.popLast() {
        let center = mean(of: members, targets)
        var statistics = GroupStatistics(classCount: classCount(targets))
        for member in members {
            statistics.add(member, targets, center: center)
        }
        let impurity = statistics.impurity(targets)
        nodes[nodeIndex].value = statistics.value(targets, center: center)
        nodes[nodeIndex].impurity = impurity
        nodes[nodeIndex].sampleCount = members.count

        let depthAllowsSplit = settings.maxDepth.map { depth < $0 } ?? true
        guard depthAllowsSplit, members.count >= settings.minSamplesSplit, members.count >= 2 * settings.minSamplesLeaf,
              impurity > 1e-12,
              let split = bestSplit(features, targets, members, settings, center: center, generator: &generator)
        else { continue }

        let left = members.filter { features[$0, split.feature] <= split.threshold }
        let right = members.filter { features[$0, split.feature] > split.threshold }
        nodes[nodeIndex].feature = split.feature
        nodes[nodeIndex].threshold = split.threshold
        nodes[nodeIndex].left = nodes.count
        nodes[nodeIndex].right = nodes.count + 1
        let placeholder = TreeNode(feature: TreeNode.leafFeature, threshold: 0, left: -1, right: -1, value: [], impurity: 0, sampleCount: 0)
        nodes.append(placeholder)
        nodes.append(placeholder)
        pending.append((nodes.count - 1, right, depth + 1))
        pending.append((nodes.count - 2, left, depth + 1))
    }
    return TreeModel(nodes: nodes, featureCount: features.columns)
}

/// The split with the lowest weighted child impurity among the features tried, or `nil` when
/// no feature can be split under the leaf size limit.
///
/// With `maxFeatures`, features are tried in random order; like scikit-learn, the search goes on
/// past `maxFeatures` only while no valid split has been found.
private func bestSplit(
    _ features: Matrix, _ targets: TreeTargets, _ members: [Int], _ settings: TreeSettings,
    center: Double, generator: inout SeededGenerator
) -> Split? {
    let order = settings.maxFeatures == nil ? Array(0..<features.columns) : generator.permutation(of: features.columns)
    let quota = settings.maxFeatures ?? features.columns
    var best: Split?
    for (tried, feature) in order.enumerated() {
        if tried >= quota, best != nil { break }
        let sorted = members.sorted { features[$0, feature] < features[$1, feature] }
        var left = GroupStatistics(classCount: classCount(targets))
        var right = GroupStatistics(classCount: classCount(targets))
        for member in sorted {
            right.add(member, targets, center: center)
        }
        let total = Double(members.count)
        for position in 0..<(sorted.count - 1) {
            left.add(sorted[position], targets, center: center)
            right.add(sorted[position], targets, center: center, sign: -1)
            let value = features[sorted[position], feature]
            let next = features[sorted[position + 1], feature]
            guard value < next, left.count >= settings.minSamplesLeaf, right.count >= settings.minSamplesLeaf else { continue }
            let impurity = (Double(left.count) * left.impurity(targets) + Double(right.count) * right.impurity(targets)) / total
            if best == nil || impurity < best!.impurity - 1e-12 {
                best = Split(feature: feature, threshold: midpoint(value, next), impurity: impurity)
            }
        }
    }
    return best
}

/// A threshold between two increasing values. Halving first keeps the sum of two large values
/// from overflowing; rounding can land on `upper`, which would send it left, so `lower` is used then.
func midpoint(_ lower: Double, _ upper: Double) -> Double {
    let middle = lower / 2 + upper / 2
    return middle >= lower && middle < upper ? middle : lower
}

private func classCount(_ targets: TreeTargets) -> Int {
    if case let .classes(_, count) = targets { return count }
    return 0
}

/// The mean target of a group, subtracted before summing squares to keep precision.
private func mean(of members: [Int], _ targets: TreeTargets) -> Double {
    guard case let .values(values) = targets else { return 0 }
    var mean = 0.0
    for (offset, member) in members.enumerated() {
        mean += (values[member] - mean) / Double(offset + 1)
    }
    return mean
}
