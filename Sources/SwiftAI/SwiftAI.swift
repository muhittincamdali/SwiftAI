// SwiftAI.swift
// SwiftAI - Pure Swift Machine Learning Framework
// Copyright © 2024 Muhittin Camdali. All rights reserved.

import Foundation

/// SwiftAI - A pure Swift machine learning framework for on-device training and inference.
///
/// SwiftAI provides neural networks, classic ML algorithms, preprocessing tools,
/// and evaluation metrics — all written in pure Swift with Accelerate optimization.
///
/// ## Quick Start
///
/// ```swift
/// import SwiftAI
///
/// // Neural Network
/// let network = NeuralNetwork()
///     .dense(784, 128, activation: .relu)
///     .dropout(0.3)
///     .dense(128, 10, activation: .softmax)
///
/// network.compile(optimizer: .adam, loss: .crossEntropy)
/// let history = network.train(x: trainX, y: trainY, epochs: 50)
///
/// // Linear Regression
/// let model = LinearRegression()
/// model.fit(x: features, y: targets)
/// let r2 = model.score(x: testX, y: testY)
///
/// // K-Means Clustering
/// let kmeans = KMeans(nClusters: 5)
/// kmeans.fit(data)
/// let labels = kmeans.predict(newData)
/// ```
public enum SwiftAIFramework {
    
    /// Framework version
    public static let version = "2.0.0"
    
    /// Framework build
    public static let build = "200"
    
    /// Framework description
    public static let description = "Pure Swift Machine Learning Framework"
}

// MARK: - Convenience Aliases

/// Type alias for standard precision tensor
public typealias FloatTensor = Tensor<Float>

/// Type alias for double precision tensor
public typealias DoubleTensor = Tensor<Double>

/// Standard deviation utility
public func standardDeviation(_ values: [Float]) -> Float {
    let n = Float(values.count)
    guard n > 1 else { return 0 }
    let mean = values.reduce(0, +) / n
    let sumSquaredDiff = values.reduce(0) { $0 + ($1 - mean) * ($1 - mean) }
    return sqrt(sumSquaredDiff / (n - 1))
}
