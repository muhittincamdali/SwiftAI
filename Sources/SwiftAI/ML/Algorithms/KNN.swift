// KNN.swift
// SwiftAI - Pure Swift Machine Learning Framework
// Copyright © 2024 Muhittin Camdali. All rights reserved.

import Foundation
import Accelerate

// MARK: - K-Nearest Neighbors Classifier
public final class KNeighborsClassifier: @unchecked Sendable {
    
    // MARK: - Properties
    public private(set) var trainX: [[Float]]?
    public private(set) var trainY: [Int]?
    public private(set) var classes: [Int] = []
    
    public let k: Int
    public let weights: WeightType
    public let metric: DistanceMetric
    public let algorithm: Algorithm
    
    private var kdTree: KDTree?
    
    // MARK: - Types
    public enum WeightType: Sendable {
        case uniform
        case distance
    }
    
    public enum DistanceMetric: Sendable {
        case euclidean
        case manhattan
        case minkowski(p: Float)
        case cosine
    }
    
    public enum Algorithm: Sendable {
        case brute
        case kdTree
        case auto
    }
    
    // MARK: - Initialization
    public init(
        k: Int = 5,
        weights: WeightType = .uniform,
        metric: DistanceMetric = .euclidean,
        algorithm: Algorithm = .auto
    ) {
        precondition(k > 0, "k must be positive")
        self.k = k
        self.weights = weights
        self.metric = metric
        self.algorithm = algorithm
    }
    
    // MARK: - Fitting
    public func fit(x: [[Float]], y: [Int]) {
        precondition(x.count == y.count, "X and Y must have same number of samples")
        precondition(x.count >= k, "Number of samples must be >= k")
        
        trainX = x
        trainY = y
        classes = Array(Set(y)).sorted()
        
        // Build KD-tree if appropriate
        let useKDTree: Bool
        switch algorithm {
        case .brute:
            useKDTree = false
        case .kdTree:
            useKDTree = true
        case .auto:
            // Use KD-tree for low-dimensional data with many samples
            useKDTree = x[0].count <= 20 && x.count > 30
        }
        
        if useKDTree && metric == .euclidean {
            kdTree = KDTree(points: x, labels: y)
        }
    }
    
    // MARK: - Distance Computation
    private func computeDistance(_ a: [Float], _ b: [Float]) -> Float {
        switch metric {
        case .euclidean:
            var sum: Float = 0
            for i in 0..<a.count {
                let diff = a[i] - b[i]
                sum += diff * diff
            }
            return sqrt(sum)
            
        case .manhattan:
            var sum: Float = 0
            for i in 0..<a.count {
                sum += abs(a[i] - b[i])
            }
            return sum
            
        case .minkowski(let p):
            var sum: Float = 0
            for i in 0..<a.count {
                sum += pow(abs(a[i] - b[i]), p)
            }
            return pow(sum, 1/p)
            
        case .cosine:
            var dot: Float = 0
            var normA: Float = 0
            var normB: Float = 0
            for i in 0..<a.count {
                dot += a[i] * b[i]
                normA += a[i] * a[i]
                normB += b[i] * b[i]
            }
            let similarity = dot / (sqrt(normA) * sqrt(normB) + 1e-10)
            return 1 - similarity  // Distance = 1 - similarity
        }
    }
    
    // MARK: - Prediction
    public func predict(_ x: [[Float]]) -> [Int] {
        x.map { predictSingle($0) }
    }
    
    public func predictSingle(_ x: [Float]) -> Int {
        let proba = predictProbaSingle(x)
        let maxIdx = proba.enumerated().max(by: { $0.element < $1.element })?.offset ?? 0
        return classes[maxIdx]
    }
    
    public func predictProba(_ x: [[Float]]) -> [[Float]] {
        x.map { predictProbaSingle($0) }
    }
    
    public func predictProbaSingle(_ x: [Float]) -> [Float] {
        guard let trainX = trainX, let trainY = trainY else { return [] }
        
        let neighbors = findKNearest(x)
        
        var classWeights = [Float](repeating: 0, count: classes.count)
        
        for (idx, dist) in neighbors {
            let label = trainY[idx]
            guard let classIdx = classes.firstIndex(of: label) else { continue }
            
            let weight: Float
            switch weights {
            case .uniform:
                weight = 1.0
            case .distance:
                weight = dist > 0 ? 1.0 / dist : 1.0
            }
            
            classWeights[classIdx] += weight
        }
        
        // Normalize to probabilities
        let total = classWeights.reduce(0, +)
        return total > 0 ? classWeights.map { $0 / total } : classWeights
    }
    
    private func findKNearest(_ x: [Float]) -> [(index: Int, distance: Float)] {
        guard let trainX = trainX else { return [] }
        
        if let tree = kdTree {
            return tree.kNearest(x, k: k)
        }
        
        // Brute force
        var distances = [(index: Int, distance: Float)]()
        
        for (i, point) in trainX.enumerated() {
            let dist = computeDistance(x, point)
            distances.append((i, dist))
        }
        
        distances.sort { $0.distance < $1.distance }
        return Array(distances.prefix(k))
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
    
    public func kneighbors(_ x: [[Float]], returnDistance: Bool = true) -> (indices: [[Int]], distances: [[Float]]?) {
        var allIndices = [[Int]]()
        var allDistances = [[Float]]()
        
        for point in x {
            let neighbors = findKNearest(point)
            allIndices.append(neighbors.map { $0.index })
            allDistances.append(neighbors.map { $0.distance })
        }
        
        return (allIndices, returnDistance ? allDistances : nil)
    }
}

// MARK: - K-Nearest Neighbors Regressor
public final class KNeighborsRegressor: @unchecked Sendable {
    
    // MARK: - Properties
    public private(set) var trainX: [[Float]]?
    public private(set) var trainY: [Float]?
    
    public let k: Int
    public let weights: KNeighborsClassifier.WeightType
    public let metric: KNeighborsClassifier.DistanceMetric
    
    // MARK: - Initialization
    public init(
        k: Int = 5,
        weights: KNeighborsClassifier.WeightType = .uniform,
        metric: KNeighborsClassifier.DistanceMetric = .euclidean
    ) {
        precondition(k > 0, "k must be positive")
        self.k = k
        self.weights = weights
        self.metric = metric
    }
    
    // MARK: - Fitting
    public func fit(x: [[Float]], y: [Float]) {
        precondition(x.count == y.count, "X and Y must have same number of samples")
        precondition(x.count >= k, "Number of samples must be >= k")
        
        trainX = x
        trainY = y
    }
    
    // MARK: - Distance
    private func computeDistance(_ a: [Float], _ b: [Float]) -> Float {
        switch metric {
        case .euclidean:
            var sum: Float = 0
            for i in 0..<a.count {
                let diff = a[i] - b[i]
                sum += diff * diff
            }
            return sqrt(sum)
            
        case .manhattan:
            var sum: Float = 0
            for i in 0..<a.count {
                sum += abs(a[i] - b[i])
            }
            return sum
            
        case .minkowski(let p):
            var sum: Float = 0
            for i in 0..<a.count {
                sum += pow(abs(a[i] - b[i]), p)
            }
            return pow(sum, 1/p)
            
        case .cosine:
            var dot: Float = 0
            var normA: Float = 0
            var normB: Float = 0
            for i in 0..<a.count {
                dot += a[i] * b[i]
                normA += a[i] * a[i]
                normB += b[i] * b[i]
            }
            return 1 - dot / (sqrt(normA) * sqrt(normB) + 1e-10)
        }
    }
    
    // MARK: - Prediction
    public func predict(_ x: [[Float]]) -> [Float] {
        x.map { predictSingle($0) }
    }
    
    public func predictSingle(_ x: [Float]) -> Float {
        guard let trainX = trainX, let trainY = trainY else { return 0 }
        
        // Find k nearest neighbors
        var distances = [(index: Int, distance: Float)]()
        
        for (i, point) in trainX.enumerated() {
            let dist = computeDistance(x, point)
            distances.append((i, dist))
        }
        
        distances.sort { $0.distance < $1.distance }
        let neighbors = Array(distances.prefix(k))
        
        // Compute weighted average
        var weightedSum: Float = 0
        var totalWeight: Float = 0
        
        for (idx, dist) in neighbors {
            let weight: Float
            switch weights {
            case .uniform:
                weight = 1.0
            case .distance:
                weight = dist > 0 ? 1.0 / dist : 1.0
            }
            
            weightedSum += weight * trainY[idx]
            totalWeight += weight
        }
        
        return totalWeight > 0 ? weightedSum / totalWeight : 0
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

// MARK: - KD-Tree
public final class KDTree: @unchecked Sendable {
    
    private final class Node {
        let point: [Float]
        let label: Int
        let splitDim: Int
        var left: Node?
        var right: Node?
        
        init(point: [Float], label: Int, splitDim: Int) {
            self.point = point
            self.label = label
            self.splitDim = splitDim
        }
    }
    
    private var root: Node?
    private let points: [[Float]]
    private let labels: [Int]
    
    public init(points: [[Float]], labels: [Int]) {
        self.points = points
        self.labels = labels
        
        let indices = Array(0..<points.count)
        root = buildTree(indices: indices, depth: 0)
    }
    
    private func buildTree(indices: [Int], depth: Int) -> Node? {
        guard !indices.isEmpty else { return nil }
        
        let dims = points[0].count
        let splitDim = depth % dims
        
        // Sort by split dimension
        let sorted = indices.sorted { points[$0][splitDim] < points[$1][splitDim] }
        let medianIdx = sorted.count / 2
        let medianPointIdx = sorted[medianIdx]
        
        let node = Node(
            point: points[medianPointIdx],
            label: labels[medianPointIdx],
            splitDim: splitDim
        )
        
        node.left = buildTree(indices: Array(sorted[0..<medianIdx]), depth: depth + 1)
        node.right = buildTree(indices: Array(sorted[(medianIdx + 1)...]), depth: depth + 1)
        
        return node
    }
    
    public func kNearest(_ query: [Float], k: Int) -> [(index: Int, distance: Float)] {
        var heap = BinaryHeap<(Int, Float)> { $0.1 > $1.1 }  // Max heap by distance
        searchNearest(node: root, query: query, k: k, heap: &heap)
        
        // Find actual indices
        var results = [(index: Int, distance: Float)]()
        while let (_, dist) = heap.pop() {
            // Need to find index - simplified here
            for (i, point) in points.enumerated() {
                let d = euclideanDistance(query, point)
                if abs(d - dist) < 1e-6 {
                    results.append((i, dist))
                    break
                }
            }
        }
        return results.reversed()
    }
    
    private func searchNearest(node: Node?, query: [Float], k: Int, heap: inout BinaryHeap<(Int, Float)>) {
        guard let node = node else { return }
        
        let dist = euclideanDistance(query, node.point)
        
        // Add to heap
        if heap.count < k {
            heap.push((node.label, dist))
        } else if dist < heap.peek()!.1 {
            heap.pop()
            heap.push((node.label, dist))
        }
        
        // Determine which subtree to search first
        let diff = query[node.splitDim] - node.point[node.splitDim]
        let (first, second) = diff < 0 ? (node.left, node.right) : (node.right, node.left)
        
        searchNearest(node: first, query: query, k: k, heap: &heap)
        
        // Check if we need to search the other subtree
        if heap.count < k || abs(diff) < heap.peek()!.1 {
            searchNearest(node: second, query: query, k: k, heap: &heap)
        }
    }
    
    private func euclideanDistance(_ a: [Float], _ b: [Float]) -> Float {
        var sum: Float = 0
        for i in 0..<a.count {
            let diff = a[i] - b[i]
            sum += diff * diff
        }
        return sqrt(sum)
    }
}

// MARK: - Binary Heap
public struct BinaryHeap<T> {
    private var elements: [T]
    private let comparator: (T, T) -> Bool
    
    public var count: Int { elements.count }
    public var isEmpty: Bool { elements.isEmpty }
    
    public init(comparator: @escaping (T, T) -> Bool) {
        self.elements = []
        self.comparator = comparator
    }
    
    public mutating func push(_ element: T) {
        elements.append(element)
        siftUp(from: elements.count - 1)
    }
    
    public mutating func pop() -> T? {
        guard !elements.isEmpty else { return nil }
        if elements.count == 1 { return elements.removeLast() }
        
        let first = elements[0]
        elements[0] = elements.removeLast()
        siftDown(from: 0)
        return first
    }
    
    public func peek() -> T? {
        elements.first
    }
    
    private mutating func siftUp(from index: Int) {
        var idx = index
        while idx > 0 {
            let parent = (idx - 1) / 2
            if comparator(elements[idx], elements[parent]) {
                elements.swapAt(idx, parent)
                idx = parent
            } else {
                break
            }
        }
    }
    
    private mutating func siftDown(from index: Int) {
        var idx = index
        let count = elements.count
        
        while true {
            let left = 2 * idx + 1
            let right = 2 * idx + 2
            var largest = idx
            
            if left < count && comparator(elements[left], elements[largest]) {
                largest = left
            }
            if right < count && comparator(elements[right], elements[largest]) {
                largest = right
            }
            
            if largest == idx { break }
            
            elements.swapAt(idx, largest)
            idx = largest
        }
    }
}
