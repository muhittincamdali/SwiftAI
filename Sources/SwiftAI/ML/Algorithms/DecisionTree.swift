// DecisionTree.swift
// SwiftAI - Pure Swift Machine Learning Framework
// Copyright © 2024 Muhittin Camdali. All rights reserved.

import Foundation

// MARK: - Decision Tree Node
public final class TreeNode: @unchecked Sendable {
    public var featureIndex: Int?
    public var threshold: Float?
    public var left: TreeNode?
    public var right: TreeNode?
    public var value: Float?         // For regression
    public var classLabel: Int?      // For classification
    public var classCounts: [Int: Int]?  // Class distribution
    public var isLeaf: Bool { value != nil || classLabel != nil }
    
    public init() {}
}

// MARK: - Split Criterion
public enum SplitCriterion: Sendable {
    case gini           // Classification
    case entropy        // Classification
    case mse            // Regression
    case mae            // Regression
}

// MARK: - Decision Tree Classifier
public final class DecisionTreeClassifier: @unchecked Sendable {
    
    // MARK: - Properties
    public private(set) var root: TreeNode?
    public private(set) var classes: [Int] = []
    public private(set) var featureImportances: [Float]?
    
    public let maxDepth: Int
    public let minSamplesSplit: Int
    public let minSamplesLeaf: Int
    public let criterion: SplitCriterion
    public let maxFeatures: Int?
    
    private var nFeatures: Int = 0
    private var importanceAccumulator: [Float] = []
    
    // MARK: - Initialization
    public init(
        maxDepth: Int = 10,
        minSamplesSplit: Int = 2,
        minSamplesLeaf: Int = 1,
        criterion: SplitCriterion = .gini,
        maxFeatures: Int? = nil
    ) {
        self.maxDepth = maxDepth
        self.minSamplesSplit = minSamplesSplit
        self.minSamplesLeaf = minSamplesLeaf
        self.criterion = criterion
        self.maxFeatures = maxFeatures
    }
    
    // MARK: - Fitting
    public func fit(x: [[Float]], y: [Int]) {
        precondition(x.count == y.count, "X and Y must have same number of samples")
        precondition(!x.isEmpty, "Data cannot be empty")
        
        classes = Array(Set(y)).sorted()
        nFeatures = x[0].count
        importanceAccumulator = [Float](repeating: 0, count: nFeatures)
        
        let indices = Array(0..<x.count)
        root = buildTree(x: x, y: y, indices: indices, depth: 0)
        
        // Normalize feature importances
        let total = importanceAccumulator.reduce(0, +)
        if total > 0 {
            featureImportances = importanceAccumulator.map { $0 / total }
        }
    }
    
    private func buildTree(x: [[Float]], y: [Int], indices: [Int], depth: Int) -> TreeNode {
        let node = TreeNode()
        
        // Get labels for current indices
        let labels = indices.map { y[$0] }
        
        // Count classes
        var classCounts = [Int: Int]()
        for label in labels {
            classCounts[label, default: 0] += 1
        }
        node.classCounts = classCounts
        
        // Check stopping conditions
        if depth >= maxDepth ||
           indices.count < minSamplesSplit ||
           Set(labels).count == 1 {
            // Make leaf node
            node.classLabel = classCounts.max(by: { $0.value < $1.value })?.key
            return node
        }
        
        // Find best split
        let (bestFeature, bestThreshold, bestGain) = findBestSplit(x: x, y: y, indices: indices)
        
        if bestFeature == nil || bestGain <= 0 {
            node.classLabel = classCounts.max(by: { $0.value < $1.value })?.key
            return node
        }
        
        // Record feature importance
        importanceAccumulator[bestFeature!] += bestGain * Float(indices.count)
        
        // Split data
        var leftIndices = [Int]()
        var rightIndices = [Int]()
        
        for idx in indices {
            if x[idx][bestFeature!] <= bestThreshold! {
                leftIndices.append(idx)
            } else {
                rightIndices.append(idx)
            }
        }
        
        // Check minimum samples in leaf
        if leftIndices.count < minSamplesLeaf || rightIndices.count < minSamplesLeaf {
            node.classLabel = classCounts.max(by: { $0.value < $1.value })?.key
            return node
        }
        
        node.featureIndex = bestFeature
        node.threshold = bestThreshold
        node.left = buildTree(x: x, y: y, indices: leftIndices, depth: depth + 1)
        node.right = buildTree(x: x, y: y, indices: rightIndices, depth: depth + 1)
        
        return node
    }
    
    private func findBestSplit(x: [[Float]], y: [Int], indices: [Int]) -> (Int?, Float?, Float) {
        var bestFeature: Int?
        var bestThreshold: Float?
        var bestGain: Float = 0
        
        let currentImpurity = computeImpurity(indices.map { y[$0] })
        
        // Select features to consider
        var featuresToCheck = Array(0..<nFeatures)
        if let max = maxFeatures, max < nFeatures {
            featuresToCheck.shuffle()
            featuresToCheck = Array(featuresToCheck.prefix(max))
        }
        
        for feature in featuresToCheck {
            // Get unique values for this feature
            let values = Set(indices.map { x[$0][feature] }).sorted()
            
            // Try each threshold
            for i in 0..<(values.count - 1) {
                let threshold = (values[i] + values[i + 1]) / 2
                
                var leftLabels = [Int]()
                var rightLabels = [Int]()
                
                for idx in indices {
                    if x[idx][feature] <= threshold {
                        leftLabels.append(y[idx])
                    } else {
                        rightLabels.append(y[idx])
                    }
                }
                
                if leftLabels.isEmpty || rightLabels.isEmpty {
                    continue
                }
                
                // Compute information gain
                let leftImpurity = computeImpurity(leftLabels)
                let rightImpurity = computeImpurity(rightLabels)
                let n = Float(indices.count)
                let nLeft = Float(leftLabels.count)
                let nRight = Float(rightLabels.count)
                
                let gain = currentImpurity - (nLeft / n * leftImpurity + nRight / n * rightImpurity)
                
                if gain > bestGain {
                    bestGain = gain
                    bestFeature = feature
                    bestThreshold = threshold
                }
            }
        }
        
        return (bestFeature, bestThreshold, bestGain)
    }
    
    private func computeImpurity(_ labels: [Int]) -> Float {
        if labels.isEmpty { return 0 }
        
        var counts = [Int: Int]()
        for label in labels {
            counts[label, default: 0] += 1
        }
        
        let n = Float(labels.count)
        
        switch criterion {
        case .gini:
            var gini: Float = 1
            for (_, count) in counts {
                let p = Float(count) / n
                gini -= p * p
            }
            return gini
            
        case .entropy:
            var entropy: Float = 0
            for (_, count) in counts {
                let p = Float(count) / n
                if p > 0 {
                    entropy -= p * log2(p)
                }
            }
            return entropy
            
        default:
            return 0
        }
    }
    
    // MARK: - Prediction
    public func predict(_ x: [[Float]]) -> [Int] {
        x.map { predictSingle($0) }
    }
    
    public func predictSingle(_ x: [Float]) -> Int {
        guard let root = root else { return 0 }
        return traverse(node: root, x: x)
    }
    
    private func traverse(node: TreeNode, x: [Float]) -> Int {
        if node.isLeaf {
            return node.classLabel ?? 0
        }
        
        guard let feature = node.featureIndex,
              let threshold = node.threshold else {
            return node.classLabel ?? 0
        }
        
        if x[feature] <= threshold {
            return traverse(node: node.left!, x: x)
        } else {
            return traverse(node: node.right!, x: x)
        }
    }
    
    public func predictProba(_ x: [[Float]]) -> [[Float]] {
        x.map { predictProbaSingle($0) }
    }
    
    public func predictProbaSingle(_ x: [Float]) -> [Float] {
        guard let root = root else { return [] }
        let node = traverseToLeaf(node: root, x: x)
        
        var proba = [Float](repeating: 0, count: classes.count)
        if let counts = node.classCounts {
            let total = Float(counts.values.reduce(0, +))
            for (cls, count) in counts {
                if let idx = classes.firstIndex(of: cls) {
                    proba[idx] = Float(count) / total
                }
            }
        }
        return proba
    }
    
    private func traverseToLeaf(node: TreeNode, x: [Float]) -> TreeNode {
        if node.isLeaf {
            return node
        }
        
        guard let feature = node.featureIndex,
              let threshold = node.threshold else {
            return node
        }
        
        if x[feature] <= threshold {
            return traverseToLeaf(node: node.left!, x: x)
        } else {
            return traverseToLeaf(node: node.right!, x: x)
        }
    }
    
    // MARK: - Evaluation
    public func score(x: [[Float]], y: [Int]) -> Float {
        let predictions = predict(x)
        var correct = 0
        for i in 0..<y.count {
            if predictions[i] == y[i] {
                correct += 1
            }
        }
        return Float(correct) / Float(y.count)
    }
    
    // MARK: - Visualization
    public func exportText(featureNames: [String]? = nil) -> String {
        guard let root = root else { return "Empty tree" }
        return exportNode(root, featureNames: featureNames, prefix: "", isLast: true)
    }
    
    private func exportNode(_ node: TreeNode, featureNames: [String]?, prefix: String, isLast: Bool) -> String {
        var result = prefix + (isLast ? "└── " : "├── ")
        
        if node.isLeaf {
            result += "class: \(node.classLabel ?? 0)"
            if let counts = node.classCounts {
                result += " [\(counts.map { "\($0.key): \($0.value)" }.joined(separator: ", "))]"
            }
        } else {
            let featureName = featureNames?[node.featureIndex!] ?? "feature_\(node.featureIndex!)"
            result += "\(featureName) <= \(String(format: "%.4f", node.threshold!))"
        }
        result += "\n"
        
        let childPrefix = prefix + (isLast ? "    " : "│   ")
        
        if let left = node.left {
            result += exportNode(left, featureNames: featureNames, prefix: childPrefix, isLast: node.right == nil)
        }
        if let right = node.right {
            result += exportNode(right, featureNames: featureNames, prefix: childPrefix, isLast: true)
        }
        
        return result
    }
}

// MARK: - Decision Tree Regressor
public final class DecisionTreeRegressor: @unchecked Sendable {
    
    // MARK: - Properties
    public private(set) var root: TreeNode?
    public private(set) var featureImportances: [Float]?
    
    public let maxDepth: Int
    public let minSamplesSplit: Int
    public let minSamplesLeaf: Int
    public let criterion: SplitCriterion
    
    private var nFeatures: Int = 0
    private var importanceAccumulator: [Float] = []
    
    // MARK: - Initialization
    public init(
        maxDepth: Int = 10,
        minSamplesSplit: Int = 2,
        minSamplesLeaf: Int = 1,
        criterion: SplitCriterion = .mse
    ) {
        self.maxDepth = maxDepth
        self.minSamplesSplit = minSamplesSplit
        self.minSamplesLeaf = minSamplesLeaf
        self.criterion = criterion
    }
    
    // MARK: - Fitting
    public func fit(x: [[Float]], y: [Float]) {
        precondition(x.count == y.count, "X and Y must have same number of samples")
        precondition(!x.isEmpty, "Data cannot be empty")
        
        nFeatures = x[0].count
        importanceAccumulator = [Float](repeating: 0, count: nFeatures)
        
        let indices = Array(0..<x.count)
        root = buildTree(x: x, y: y, indices: indices, depth: 0)
        
        let total = importanceAccumulator.reduce(0, +)
        if total > 0 {
            featureImportances = importanceAccumulator.map { $0 / total }
        }
    }
    
    private func buildTree(x: [[Float]], y: [Float], indices: [Int], depth: Int) -> TreeNode {
        let node = TreeNode()
        
        let values = indices.map { y[$0] }
        let mean = values.reduce(0, +) / Float(values.count)
        
        // Check stopping conditions
        if depth >= maxDepth ||
           indices.count < minSamplesSplit ||
           Set(values).count == 1 {
            node.value = mean
            return node
        }
        
        // Find best split
        let (bestFeature, bestThreshold, bestReduction) = findBestSplit(x: x, y: y, indices: indices)
        
        if bestFeature == nil || bestReduction <= 0 {
            node.value = mean
            return node
        }
        
        importanceAccumulator[bestFeature!] += bestReduction * Float(indices.count)
        
        var leftIndices = [Int]()
        var rightIndices = [Int]()
        
        for idx in indices {
            if x[idx][bestFeature!] <= bestThreshold! {
                leftIndices.append(idx)
            } else {
                rightIndices.append(idx)
            }
        }
        
        if leftIndices.count < minSamplesLeaf || rightIndices.count < minSamplesLeaf {
            node.value = mean
            return node
        }
        
        node.featureIndex = bestFeature
        node.threshold = bestThreshold
        node.left = buildTree(x: x, y: y, indices: leftIndices, depth: depth + 1)
        node.right = buildTree(x: x, y: y, indices: rightIndices, depth: depth + 1)
        
        return node
    }
    
    private func findBestSplit(x: [[Float]], y: [Float], indices: [Int]) -> (Int?, Float?, Float) {
        var bestFeature: Int?
        var bestThreshold: Float?
        var bestReduction: Float = 0
        
        let currentImpurity = computeImpurity(indices.map { y[$0] })
        
        for feature in 0..<nFeatures {
            let values = Set(indices.map { x[$0][feature] }).sorted()
            
            for i in 0..<(values.count - 1) {
                let threshold = (values[i] + values[i + 1]) / 2
                
                var leftValues = [Float]()
                var rightValues = [Float]()
                
                for idx in indices {
                    if x[idx][feature] <= threshold {
                        leftValues.append(y[idx])
                    } else {
                        rightValues.append(y[idx])
                    }
                }
                
                if leftValues.isEmpty || rightValues.isEmpty {
                    continue
                }
                
                let leftImpurity = computeImpurity(leftValues)
                let rightImpurity = computeImpurity(rightValues)
                let n = Float(indices.count)
                let nLeft = Float(leftValues.count)
                let nRight = Float(rightValues.count)
                
                let reduction = currentImpurity - (nLeft / n * leftImpurity + nRight / n * rightImpurity)
                
                if reduction > bestReduction {
                    bestReduction = reduction
                    bestFeature = feature
                    bestThreshold = threshold
                }
            }
        }
        
        return (bestFeature, bestThreshold, bestReduction)
    }
    
    private func computeImpurity(_ values: [Float]) -> Float {
        if values.isEmpty { return 0 }
        
        let mean = values.reduce(0, +) / Float(values.count)
        
        switch criterion {
        case .mse:
            return values.map { ($0 - mean) * ($0 - mean) }.reduce(0, +) / Float(values.count)
        case .mae:
            return values.map { abs($0 - mean) }.reduce(0, +) / Float(values.count)
        default:
            return 0
        }
    }
    
    // MARK: - Prediction
    public func predict(_ x: [[Float]]) -> [Float] {
        x.map { predictSingle($0) }
    }
    
    public func predictSingle(_ x: [Float]) -> Float {
        guard let root = root else { return 0 }
        return traverse(node: root, x: x)
    }
    
    private func traverse(node: TreeNode, x: [Float]) -> Float {
        if node.isLeaf {
            return node.value ?? 0
        }
        
        guard let feature = node.featureIndex,
              let threshold = node.threshold else {
            return node.value ?? 0
        }
        
        if x[feature] <= threshold {
            return traverse(node: node.left!, x: x)
        } else {
            return traverse(node: node.right!, x: x)
        }
    }
    
    // MARK: - Evaluation
    public func score(x: [[Float]], y: [Float]) -> Float {
        let predictions = predict(x)
        let mean = y.reduce(0, +) / Float(y.count)
        
        var ssRes: Float = 0
        var ssTot: Float = 0
        
        for i in 0..<y.count {
            ssRes += (y[i] - predictions[i]) * (y[i] - predictions[i])
            ssTot += (y[i] - mean) * (y[i] - mean)
        }
        
        return 1 - (ssRes / ssTot)
    }
}
