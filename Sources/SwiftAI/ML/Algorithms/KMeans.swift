// KMeans.swift
// SwiftAI - Pure Swift Machine Learning Framework
// Copyright © 2024 Muhittin Camdali. All rights reserved.

import Foundation
import Accelerate

// MARK: - K-Means Clustering
public final class KMeans: @unchecked Sendable {
    
    // MARK: - Properties
    public private(set) var centroids: [[Float]]?
    public private(set) var labels: [Int]?
    public private(set) var inertia: Float = 0
    public private(set) var nIterations: Int = 0
    
    public let nClusters: Int
    public let maxIterations: Int
    public let tolerance: Float
    public let initMethod: InitMethod
    public let nInit: Int
    
    // MARK: - Types
    public enum InitMethod: Sendable {
        case random
        case kmeanspp  // K-Means++
        case fixed([[Float]])
    }
    
    // MARK: - Initialization
    public init(
        nClusters: Int = 8,
        maxIterations: Int = 300,
        tolerance: Float = 1e-4,
        initMethod: InitMethod = .kmeanspp,
        nInit: Int = 10
    ) {
        precondition(nClusters > 0, "Number of clusters must be positive")
        self.nClusters = nClusters
        self.maxIterations = maxIterations
        self.tolerance = tolerance
        self.initMethod = initMethod
        self.nInit = nInit
    }
    
    // MARK: - Fitting
    public func fit(_ x: [[Float]]) {
        precondition(x.count >= nClusters, "Number of samples must be >= number of clusters")
        
        var bestCentroids: [[Float]]?
        var bestLabels: [Int]?
        var bestInertia: Float = .infinity
        var bestIterations = 0
        
        let runs = (initMethod == .fixed([])) ? 1 : nInit
        
        for _ in 0..<runs {
            let (cents, labs, inert, iters) = fitOnce(x)
            if inert < bestInertia {
                bestCentroids = cents
                bestLabels = labs
                bestInertia = inert
                bestIterations = iters
            }
        }
        
        centroids = bestCentroids
        labels = bestLabels
        inertia = bestInertia
        nIterations = bestIterations
    }
    
    private func fitOnce(_ x: [[Float]]) -> ([[Float]], [Int], Float, Int) {
        let nSamples = x.count
        let nFeatures = x[0].count
        
        // Initialize centroids
        var cents = initializeCentroids(x)
        var labs = [Int](repeating: 0, count: nSamples)
        var iterations = 0
        
        for iter in 0..<maxIterations {
            iterations = iter + 1
            
            // Assign labels
            for i in 0..<nSamples {
                var minDist: Float = .infinity
                for k in 0..<nClusters {
                    let dist = squaredDistance(x[i], cents[k])
                    if dist < minDist {
                        minDist = dist
                        labs[i] = k
                    }
                }
            }
            
            // Update centroids
            var newCentroids = [[Float]](repeating: [Float](repeating: 0, count: nFeatures), count: nClusters)
            var counts = [Int](repeating: 0, count: nClusters)
            
            for i in 0..<nSamples {
                let k = labs[i]
                counts[k] += 1
                for j in 0..<nFeatures {
                    newCentroids[k][j] += x[i][j]
                }
            }
            
            // Average centroids
            for k in 0..<nClusters {
                if counts[k] > 0 {
                    for j in 0..<nFeatures {
                        newCentroids[k][j] /= Float(counts[k])
                    }
                } else {
                    // Handle empty cluster: keep old centroid or reinitialize
                    newCentroids[k] = cents[k]
                }
            }
            
            // Check convergence
            var maxShift: Float = 0
            for k in 0..<nClusters {
                let shift = squaredDistance(cents[k], newCentroids[k])
                maxShift = max(maxShift, shift)
            }
            
            cents = newCentroids
            
            if maxShift < tolerance * tolerance {
                break
            }
        }
        
        // Compute inertia
        var inert: Float = 0
        for i in 0..<nSamples {
            inert += squaredDistance(x[i], cents[labs[i]])
        }
        
        return (cents, labs, inert, iterations)
    }
    
    private func initializeCentroids(_ x: [[Float]]) -> [[Float]] {
        let nSamples = x.count
        
        switch initMethod {
        case .random:
            var indices = Array(0..<nSamples)
            indices.shuffle()
            return Array(indices.prefix(nClusters)).map { x[$0] }
            
        case .kmeanspp:
            return kmeansppInit(x)
            
        case .fixed(let centroids):
            precondition(centroids.count == nClusters, "Fixed centroids count must match nClusters")
            return centroids
        }
    }
    
    private func kmeansppInit(_ x: [[Float]]) -> [[Float]] {
        var centroids = [[Float]]()
        let nSamples = x.count
        
        // First centroid: random
        centroids.append(x[Int.random(in: 0..<nSamples)])
        
        // Remaining centroids: proportional to squared distance
        for _ in 1..<nClusters {
            var distances = [Float](repeating: 0, count: nSamples)
            var totalDist: Float = 0
            
            for i in 0..<nSamples {
                var minDist: Float = .infinity
                for centroid in centroids {
                    let dist = squaredDistance(x[i], centroid)
                    minDist = min(minDist, dist)
                }
                distances[i] = minDist
                totalDist += minDist
            }
            
            // Sample proportionally
            let threshold = Float.random(in: 0..<totalDist)
            var cumulative: Float = 0
            var selectedIdx = 0
            
            for i in 0..<nSamples {
                cumulative += distances[i]
                if cumulative >= threshold {
                    selectedIdx = i
                    break
                }
            }
            
            centroids.append(x[selectedIdx])
        }
        
        return centroids
    }
    
    private func squaredDistance(_ a: [Float], _ b: [Float]) -> Float {
        var sum: Float = 0
        for i in 0..<a.count {
            let diff = a[i] - b[i]
            sum += diff * diff
        }
        return sum
    }
    
    // MARK: - Prediction
    public func predict(_ x: [[Float]]) -> [Int] {
        x.map { predictSingle($0) }
    }
    
    public func predictSingle(_ x: [Float]) -> Int {
        guard let cents = centroids else { return 0 }
        
        var minDist: Float = .infinity
        var bestCluster = 0
        
        for (k, centroid) in cents.enumerated() {
            let dist = squaredDistance(x, centroid)
            if dist < minDist {
                minDist = dist
                bestCluster = k
            }
        }
        
        return bestCluster
    }
    
    public func fitPredict(_ x: [[Float]]) -> [Int] {
        fit(x)
        return labels ?? []
    }
    
    public func transform(_ x: [[Float]]) -> [[Float]] {
        guard let cents = centroids else { return [] }
        
        return x.map { sample in
            cents.map { centroid in
                sqrt(squaredDistance(sample, centroid))
            }
        }
    }
    
    // MARK: - Evaluation
    public func silhouetteScore(_ x: [[Float]]) -> Float {
        guard let labs = labels, x.count > nClusters else { return 0 }
        
        var scores = [Float]()
        
        for i in 0..<x.count {
            let clusterI = labs[i]
            
            // Compute a(i): mean distance to other points in same cluster
            var aSum: Float = 0
            var aCount = 0
            
            for j in 0..<x.count {
                if i != j && labs[j] == clusterI {
                    aSum += sqrt(squaredDistance(x[i], x[j]))
                    aCount += 1
                }
            }
            
            let a = aCount > 0 ? aSum / Float(aCount) : 0
            
            // Compute b(i): minimum mean distance to points in other clusters
            var b: Float = .infinity
            
            for k in 0..<nClusters {
                if k != clusterI {
                    var bSum: Float = 0
                    var bCount = 0
                    
                    for j in 0..<x.count {
                        if labs[j] == k {
                            bSum += sqrt(squaredDistance(x[i], x[j]))
                            bCount += 1
                        }
                    }
                    
                    if bCount > 0 {
                        b = min(b, bSum / Float(bCount))
                    }
                }
            }
            
            // Silhouette coefficient
            let s = (b - a) / max(a, b)
            scores.append(s)
        }
        
        return scores.reduce(0, +) / Float(scores.count)
    }
}

// MARK: - Mini-Batch K-Means
public final class MiniBatchKMeans: @unchecked Sendable {
    
    public private(set) var centroids: [[Float]]?
    public private(set) var labels: [Int]?
    public private(set) var inertia: Float = 0
    
    public let nClusters: Int
    public let maxIterations: Int
    public let batchSize: Int
    
    public init(nClusters: Int = 8, maxIterations: Int = 100, batchSize: Int = 100) {
        self.nClusters = nClusters
        self.maxIterations = maxIterations
        self.batchSize = batchSize
    }
    
    public func fit(_ x: [[Float]]) {
        let nSamples = x.count
        let nFeatures = x[0].count
        
        // Initialize with random samples
        var indices = Array(0..<nSamples)
        indices.shuffle()
        centroids = Array(indices.prefix(nClusters)).map { x[$0] }
        
        var counts = [Int](repeating: 0, count: nClusters)
        
        for _ in 0..<maxIterations {
            // Sample a mini-batch
            indices.shuffle()
            let batchIndices = Array(indices.prefix(batchSize))
            
            // Assign to nearest centroids
            var assignments = [Int](repeating: 0, count: batchIndices.count)
            for (i, idx) in batchIndices.enumerated() {
                var minDist: Float = .infinity
                for k in 0..<nClusters {
                    var dist: Float = 0
                    for j in 0..<nFeatures {
                        let diff = x[idx][j] - centroids![k][j]
                        dist += diff * diff
                    }
                    if dist < minDist {
                        minDist = dist
                        assignments[i] = k
                    }
                }
            }
            
            // Update centroids with streaming average
            for (i, idx) in batchIndices.enumerated() {
                let k = assignments[i]
                counts[k] += 1
                let eta = 1.0 / Float(counts[k])
                
                for j in 0..<nFeatures {
                    centroids![k][j] = (1 - eta) * centroids![k][j] + eta * x[idx][j]
                }
            }
        }
        
        // Final assignment
        labels = predict(x)
        
        // Compute inertia
        inertia = 0
        for i in 0..<nSamples {
            var dist: Float = 0
            for j in 0..<nFeatures {
                let diff = x[i][j] - centroids![labels![i]][j]
                dist += diff * diff
            }
            inertia += dist
        }
    }
    
    public func predict(_ x: [[Float]]) -> [Int] {
        guard let cents = centroids else { return [] }
        
        return x.map { sample in
            var minDist: Float = .infinity
            var bestCluster = 0
            
            for (k, centroid) in cents.enumerated() {
                var dist: Float = 0
                for j in 0..<sample.count {
                    let diff = sample[j] - centroid[j]
                    dist += diff * diff
                }
                if dist < minDist {
                    minDist = dist
                    bestCluster = k
                }
            }
            
            return bestCluster
        }
    }
}

// MARK: - DBSCAN
public final class DBSCAN: @unchecked Sendable {
    
    public private(set) var labels: [Int]?
    public private(set) var coreIndices: [Int]?
    
    public let eps: Float
    public let minSamples: Int
    
    private let NOISE = -1
    
    public init(eps: Float = 0.5, minSamples: Int = 5) {
        self.eps = eps
        self.minSamples = minSamples
    }
    
    public func fit(_ x: [[Float]]) {
        let nSamples = x.count
        labels = [Int](repeating: NOISE, count: nSamples)
        var clusterId = 0
        var cores = [Int]()
        
        for i in 0..<nSamples {
            if labels![i] != NOISE { continue }
            
            let neighbors = regionQuery(x, i)
            
            if neighbors.count < minSamples {
                // Mark as noise (can later become border point)
                continue
            }
            
            cores.append(i)
            labels![i] = clusterId
            
            // Expand cluster
            var seeds = neighbors
            var j = 0
            while j < seeds.count {
                let q = seeds[j]
                
                if labels![q] == NOISE {
                    labels![q] = clusterId
                }
                
                if labels![q] != NOISE && labels![q] != clusterId {
                    j += 1
                    continue
                }
                
                labels![q] = clusterId
                
                let qNeighbors = regionQuery(x, q)
                if qNeighbors.count >= minSamples {
                    cores.append(q)
                    for neighbor in qNeighbors {
                        if !seeds.contains(neighbor) {
                            seeds.append(neighbor)
                        }
                    }
                }
                
                j += 1
            }
            
            clusterId += 1
        }
        
        coreIndices = Array(Set(cores)).sorted()
    }
    
    private func regionQuery(_ x: [[Float]], _ idx: Int) -> [Int] {
        var neighbors = [Int]()
        let point = x[idx]
        
        for (i, other) in x.enumerated() {
            if distance(point, other) <= eps {
                neighbors.append(i)
            }
        }
        
        return neighbors
    }
    
    private func distance(_ a: [Float], _ b: [Float]) -> Float {
        var sum: Float = 0
        for i in 0..<a.count {
            let diff = a[i] - b[i]
            sum += diff * diff
        }
        return sqrt(sum)
    }
    
    public func fitPredict(_ x: [[Float]]) -> [Int] {
        fit(x)
        return labels ?? []
    }
}
