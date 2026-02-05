// DataPreprocessing.swift
// SwiftAI - Pure Swift Machine Learning Framework
// Copyright © 2024 Muhittin Camdali. All rights reserved.

import Foundation
import Accelerate

// MARK: - Standard Scaler
/// Standardize features by removing the mean and scaling to unit variance
public final class StandardScaler: @unchecked Sendable {
    
    public private(set) var mean: [Float]?
    public private(set) var std: [Float]?
    public private(set) var isFitted: Bool = false
    
    public init() {}
    
    public func fit(_ x: [[Float]]) {
        let nSamples = x.count
        let nFeatures = x[0].count
        
        var means = [Float](repeating: 0, count: nFeatures)
        var stds = [Float](repeating: 0, count: nFeatures)
        
        // Compute means
        for sample in x {
            for (j, val) in sample.enumerated() {
                means[j] += val
            }
        }
        means = means.map { $0 / Float(nSamples) }
        
        // Compute standard deviations
        for sample in x {
            for (j, val) in sample.enumerated() {
                let diff = val - means[j]
                stds[j] += diff * diff
            }
        }
        stds = stds.map { sqrt($0 / Float(nSamples)) }
        
        // Avoid division by zero
        stds = stds.map { $0 > 0 ? $0 : 1.0 }
        
        self.mean = means
        self.std = stds
        self.isFitted = true
    }
    
    public func transform(_ x: [[Float]]) -> [[Float]] {
        guard let mean = mean, let std = std else {
            fatalError("Scaler must be fitted before transform")
        }
        
        return x.map { sample in
            zip(zip(sample, mean), std).map { (pair, s) in
                (pair.0 - pair.1) / s
            }
        }
    }
    
    public func fitTransform(_ x: [[Float]]) -> [[Float]] {
        fit(x)
        return transform(x)
    }
    
    public func inverseTransform(_ x: [[Float]]) -> [[Float]] {
        guard let mean = mean, let std = std else {
            fatalError("Scaler must be fitted before inverse transform")
        }
        
        return x.map { sample in
            zip(zip(sample, mean), std).map { (pair, s) in
                pair.0 * s + pair.1
            }
        }
    }
}

// MARK: - Min-Max Scaler
/// Transform features by scaling each feature to a given range
public final class MinMaxScaler: @unchecked Sendable {
    
    public private(set) var min: [Float]?
    public private(set) var max: [Float]?
    public private(set) var scale: [Float]?
    
    public let featureRange: (min: Float, max: Float)
    
    public init(featureRange: (min: Float, max: Float) = (0, 1)) {
        self.featureRange = featureRange
    }
    
    public func fit(_ x: [[Float]]) {
        let nFeatures = x[0].count
        
        var mins = [Float](repeating: .infinity, count: nFeatures)
        var maxs = [Float](repeating: -.infinity, count: nFeatures)
        
        for sample in x {
            for (j, val) in sample.enumerated() {
                mins[j] = Swift.min(mins[j], val)
                maxs[j] = Swift.max(maxs[j], val)
            }
        }
        
        // Compute scale
        let rangeSize = featureRange.max - featureRange.min
        scale = zip(mins, maxs).map { minVal, maxVal in
            let dataRange = maxVal - minVal
            return dataRange > 0 ? rangeSize / dataRange : 1.0
        }
        
        self.min = mins
        self.max = maxs
    }
    
    public func transform(_ x: [[Float]]) -> [[Float]] {
        guard let minVals = min, let scaleVals = scale else {
            fatalError("Scaler must be fitted before transform")
        }
        
        return x.map { sample in
            zip(zip(sample, minVals), scaleVals).map { (pair, s) in
                (pair.0 - pair.1) * s + featureRange.min
            }
        }
    }
    
    public func fitTransform(_ x: [[Float]]) -> [[Float]] {
        fit(x)
        return transform(x)
    }
    
    public func inverseTransform(_ x: [[Float]]) -> [[Float]] {
        guard let minVals = min, let scaleVals = scale else {
            fatalError("Scaler must be fitted before inverse transform")
        }
        
        return x.map { sample in
            zip(zip(sample, minVals), scaleVals).map { (pair, s) in
                (pair.0 - featureRange.min) / s + pair.1
            }
        }
    }
}

// MARK: - Normalizer
/// Normalize samples individually to unit norm
public final class Normalizer: @unchecked Sendable {
    
    public enum Norm: Sendable {
        case l1
        case l2
        case max
    }
    
    public let norm: Norm
    
    public init(norm: Norm = .l2) {
        self.norm = norm
    }
    
    public func transform(_ x: [[Float]]) -> [[Float]] {
        x.map { sample in
            let normValue = computeNorm(sample)
            return normValue > 0 ? sample.map { $0 / normValue } : sample
        }
    }
    
    private func computeNorm(_ x: [Float]) -> Float {
        switch norm {
        case .l1:
            return x.map { abs($0) }.reduce(0, +)
        case .l2:
            return sqrt(x.map { $0 * $0 }.reduce(0, +))
        case .max:
            return x.map { abs($0) }.max() ?? 0
        }
    }
}

// MARK: - Label Encoder
/// Encode target labels with value between 0 and n_classes-1
public final class LabelEncoder: @unchecked Sendable {
    
    public private(set) var classes: [Int]?
    private var classToIndex: [Int: Int] = [:]
    
    public init() {}
    
    public func fit(_ y: [Int]) {
        classes = Array(Set(y)).sorted()
        for (i, cls) in classes!.enumerated() {
            classToIndex[cls] = i
        }
    }
    
    public func transform(_ y: [Int]) -> [Int] {
        y.map { classToIndex[$0] ?? 0 }
    }
    
    public func fitTransform(_ y: [Int]) -> [Int] {
        fit(y)
        return transform(y)
    }
    
    public func inverseTransform(_ y: [Int]) -> [Int] {
        guard let classes = classes else { return y }
        return y.map { classes[$0] }
    }
}

// MARK: - One-Hot Encoder
/// Encode categorical features as a one-hot numeric array
public final class OneHotEncoder: @unchecked Sendable {
    
    public private(set) var categories: [[Int]]?
    
    public init() {}
    
    public func fit(_ x: [[Int]]) {
        let nFeatures = x[0].count
        categories = (0..<nFeatures).map { j in
            Array(Set(x.map { $0[j] })).sorted()
        }
    }
    
    public func transform(_ x: [[Int]]) -> [[Float]] {
        guard let cats = categories else {
            fatalError("Encoder must be fitted before transform")
        }
        
        return x.map { sample in
            var encoded = [Float]()
            for (j, val) in sample.enumerated() {
                var oneHot = [Float](repeating: 0, count: cats[j].count)
                if let idx = cats[j].firstIndex(of: val) {
                    oneHot[idx] = 1
                }
                encoded.append(contentsOf: oneHot)
            }
            return encoded
        }
    }
    
    public func fitTransform(_ x: [[Int]]) -> [[Float]] {
        fit(x)
        return transform(x)
    }
}

// MARK: - Imputer
/// Fill missing values
public final class SimpleImputer: @unchecked Sendable {
    
    public enum Strategy: Sendable {
        case mean
        case median
        case mostFrequent
        case constant(Float)
    }
    
    public let strategy: Strategy
    public let missingValue: Float
    
    public private(set) var statistics: [Float]?
    
    public init(strategy: Strategy = .mean, missingValue: Float = .nan) {
        self.strategy = strategy
        self.missingValue = missingValue
    }
    
    public func fit(_ x: [[Float]]) {
        let nFeatures = x[0].count
        var stats = [Float](repeating: 0, count: nFeatures)
        
        for j in 0..<nFeatures {
            let columnValues = x.compactMap { sample -> Float? in
                let val = sample[j]
                return val.isNaN == missingValue.isNaN || val == missingValue ? nil : val
            }
            
            switch strategy {
            case .mean:
                stats[j] = columnValues.isEmpty ? 0 : columnValues.reduce(0, +) / Float(columnValues.count)
            case .median:
                let sorted = columnValues.sorted()
                stats[j] = sorted.isEmpty ? 0 : sorted[sorted.count / 2]
            case .mostFrequent:
                var counts = [Float: Int]()
                for val in columnValues {
                    counts[val, default: 0] += 1
                }
                stats[j] = counts.max(by: { $0.value < $1.value })?.key ?? 0
            case .constant(let val):
                stats[j] = val
            }
        }
        
        statistics = stats
    }
    
    public func transform(_ x: [[Float]]) -> [[Float]] {
        guard let stats = statistics else {
            fatalError("Imputer must be fitted before transform")
        }
        
        return x.map { sample in
            sample.enumerated().map { (j, val) in
                (val.isNaN == missingValue.isNaN || val == missingValue) ? stats[j] : val
            }
        }
    }
    
    public func fitTransform(_ x: [[Float]]) -> [[Float]] {
        fit(x)
        return transform(x)
    }
}

// MARK: - Robust Scaler
/// Scale features using statistics that are robust to outliers
public final class RobustScaler: @unchecked Sendable {
    
    public private(set) var median: [Float]?
    public private(set) var iqr: [Float]?  // Interquartile range
    
    public init() {}
    
    public func fit(_ x: [[Float]]) {
        let nFeatures = x[0].count
        var medians = [Float](repeating: 0, count: nFeatures)
        var iqrs = [Float](repeating: 0, count: nFeatures)
        
        for j in 0..<nFeatures {
            let column = x.map { $0[j] }.sorted()
            let n = column.count
            
            // Median
            medians[j] = column[n / 2]
            
            // IQR = Q3 - Q1
            let q1 = column[n / 4]
            let q3 = column[3 * n / 4]
            iqrs[j] = q3 - q1
            if iqrs[j] == 0 { iqrs[j] = 1 }
        }
        
        median = medians
        iqr = iqrs
    }
    
    public func transform(_ x: [[Float]]) -> [[Float]] {
        guard let med = median, let iqr = iqr else {
            fatalError("Scaler must be fitted before transform")
        }
        
        return x.map { sample in
            zip(zip(sample, med), iqr).map { (pair, i) in
                (pair.0 - pair.1) / i
            }
        }
    }
    
    public func fitTransform(_ x: [[Float]]) -> [[Float]] {
        fit(x)
        return transform(x)
    }
}

// MARK: - Power Transformer
/// Apply a power transform to make data more Gaussian-like
public final class PowerTransformer: @unchecked Sendable {
    
    public enum Method: Sendable {
        case yeojohnson
        case boxcox  // Requires positive data
    }
    
    public let method: Method
    public private(set) var lambdas: [Float]?
    
    public init(method: Method = .yeojohnson) {
        self.method = method
    }
    
    public func fit(_ x: [[Float]]) {
        let nFeatures = x[0].count
        lambdas = [Float](repeating: 0, count: nFeatures)
        
        // Simplified: use lambda = 0 (log transform) for box-cox
        // Full implementation would optimize lambda
        for j in 0..<nFeatures {
            lambdas![j] = 0  // Log transform
        }
    }
    
    public func transform(_ x: [[Float]]) -> [[Float]] {
        guard let lambdas = lambdas else {
            fatalError("Transformer must be fitted before transform")
        }
        
        return x.map { sample in
            sample.enumerated().map { (j, val) in
                powerTransform(val, lambda: lambdas[j])
            }
        }
    }
    
    private func powerTransform(_ x: Float, lambda: Float) -> Float {
        switch method {
        case .yeojohnson:
            if x >= 0 {
                if abs(lambda) < 1e-10 {
                    return log(x + 1)
                } else {
                    return (pow(x + 1, lambda) - 1) / lambda
                }
            } else {
                if abs(lambda - 2) < 1e-10 {
                    return -log(-x + 1)
                } else {
                    return -(pow(-x + 1, 2 - lambda) - 1) / (2 - lambda)
                }
            }
        case .boxcox:
            if abs(lambda) < 1e-10 {
                return log(x)
            } else {
                return (pow(x, lambda) - 1) / lambda
            }
        }
    }
    
    public func fitTransform(_ x: [[Float]]) -> [[Float]] {
        fit(x)
        return transform(x)
    }
}

// MARK: - Train/Test Split
public func trainTestSplit<T, U>(
    x: [T],
    y: [U],
    testSize: Float = 0.2,
    shuffle: Bool = true,
    randomState: Int? = nil
) -> (trainX: [T], testX: [T], trainY: [U], testY: [U]) {
    precondition(x.count == y.count, "X and Y must have same length")
    
    var indices = Array(0..<x.count)
    
    if shuffle {
        if let seed = randomState {
            srand48(seed)
        }
        indices.shuffle()
    }
    
    let splitIdx = Int(Float(x.count) * (1 - testSize))
    
    let trainIndices = Array(indices[0..<splitIdx])
    let testIndices = Array(indices[splitIdx...])
    
    let trainX = trainIndices.map { x[$0] }
    let testX = testIndices.map { x[$0] }
    let trainY = trainIndices.map { y[$0] }
    let testY = testIndices.map { y[$0] }
    
    return (trainX, testX, trainY, testY)
}

// MARK: - K-Fold Cross Validation
public struct KFold: Sendable {
    public let nSplits: Int
    public let shuffle: Bool
    
    public init(nSplits: Int = 5, shuffle: Bool = false) {
        precondition(nSplits >= 2, "Number of splits must be >= 2")
        self.nSplits = nSplits
        self.shuffle = shuffle
    }
    
    public func split(nSamples: Int) -> [(train: [Int], test: [Int])] {
        var indices = Array(0..<nSamples)
        if shuffle {
            indices.shuffle()
        }
        
        let foldSize = nSamples / nSplits
        var splits = [(train: [Int], test: [Int])]()
        
        for i in 0..<nSplits {
            let start = i * foldSize
            let end = i == nSplits - 1 ? nSamples : (i + 1) * foldSize
            
            let testIndices = Array(indices[start..<end])
            let trainIndices = Array(indices[0..<start]) + Array(indices[end...])
            
            splits.append((trainIndices, testIndices))
        }
        
        return splits
    }
}
