// LinearRegression.swift
// SwiftAI - Pure Swift Machine Learning Framework
// Copyright © 2024 Muhittin Camdali. All rights reserved.

import Foundation
import Accelerate

// MARK: - Linear Regression
/// Ordinary Least Squares Linear Regression
/// Supports multiple features, regularization, and gradient descent optimization
public final class LinearRegression: @unchecked Sendable {
    
    // MARK: - Properties
    public private(set) var weights: Tensor<Float>?
    public private(set) var bias: Float = 0
    public private(set) var isTraining = false
    
    public let regularization: RegularizationType
    public let alpha: Float  // Regularization strength
    
    // MARK: - Types
    public enum RegularizationType: Sendable {
        case none
        case l1(strength: Float)  // Lasso
        case l2(strength: Float)  // Ridge
        case elasticNet(l1Ratio: Float, strength: Float)
    }
    
    public enum FitMethod: Sendable {
        case ols          // Ordinary Least Squares (closed-form)
        case gradientDescent(learningRate: Float, epochs: Int)
        case stochastic(learningRate: Float, epochs: Int, batchSize: Int)
    }
    
    // MARK: - Initialization
    public init(regularization: RegularizationType = .none, alpha: Float = 0.01) {
        self.regularization = regularization
        self.alpha = alpha
    }
    
    // MARK: - Fitting
    public func fit(x: [[Float]], y: [Float], method: FitMethod = .ols) {
        precondition(x.count == y.count, "X and Y must have same number of samples")
        precondition(!x.isEmpty, "Data cannot be empty")
        
        let nSamples = x.count
        let nFeatures = x[0].count
        
        switch method {
        case .ols:
            fitOLS(x: x, y: y, nSamples: nSamples, nFeatures: nFeatures)
        case .gradientDescent(let lr, let epochs):
            fitGradientDescent(x: x, y: y, learningRate: lr, epochs: epochs)
        case .stochastic(let lr, let epochs, let batchSize):
            fitSGD(x: x, y: y, learningRate: lr, epochs: epochs, batchSize: batchSize)
        }
    }
    
    private func fitOLS(x: [[Float]], y: [Float], nSamples: Int, nFeatures: Int) {
        // Add bias column (column of 1s)
        var xAugmented = [[Float]]()
        for row in x {
            xAugmented.append([1.0] + row)
        }
        
        // Convert to tensors
        let X = Tensor(shape: [nSamples, nFeatures + 1], data: xAugmented.flatMap { $0 })
        let Y = Tensor(shape: [nSamples, 1], data: y)
        
        // w = (X^T X)^(-1) X^T y
        let XtX = X.T.matmul(X)
        let XtY = X.T.matmul(Y)
        
        // Add regularization to XtX diagonal if needed
        var XtXData = XtX.data
        switch regularization {
        case .l2(let strength):
            for i in 1..<(nFeatures + 1) {  // Don't regularize bias
                XtXData[i * (nFeatures + 1) + i] += strength
            }
        default:
            break
        }
        
        // Solve using LU decomposition
        let solution = solveLU(
            Tensor(shape: XtX.shape, data: XtXData),
            XtY
        )
        
        bias = solution.data[0]
        weights = Tensor(shape: [nFeatures], data: Array(solution.data[1...]))
    }
    
    private func fitGradientDescent(x: [[Float]], y: [Float], learningRate: Float, epochs: Int) {
        let nSamples = x.count
        let nFeatures = x[0].count
        
        // Initialize weights
        weights = Tensor.randn([nFeatures], mean: 0, std: 0.01)
        bias = 0
        
        for epoch in 0..<epochs {
            var totalLoss: Float = 0
            var gradW = [Float](repeating: 0, count: nFeatures)
            var gradB: Float = 0
            
            for i in 0..<nSamples {
                let prediction = predictSingle(x[i])
                let error = prediction - y[i]
                totalLoss += error * error
                
                // Accumulate gradients
                gradB += error
                for j in 0..<nFeatures {
                    gradW[j] += error * x[i][j]
                }
            }
            
            // Average gradients
            let scale = 2.0 / Float(nSamples)
            gradB *= scale
            for j in 0..<nFeatures {
                gradW[j] *= scale
            }
            
            // Add regularization gradients
            switch regularization {
            case .l1(let strength):
                for j in 0..<nFeatures {
                    gradW[j] += strength * (weights!.data[j] > 0 ? 1 : -1)
                }
            case .l2(let strength):
                for j in 0..<nFeatures {
                    gradW[j] += 2 * strength * weights!.data[j]
                }
            case .elasticNet(let l1Ratio, let strength):
                for j in 0..<nFeatures {
                    gradW[j] += strength * (l1Ratio * (weights!.data[j] > 0 ? 1 : -1) +
                                           (1 - l1Ratio) * 2 * weights!.data[j])
                }
            default:
                break
            }
            
            // Update
            bias -= learningRate * gradB
            for j in 0..<nFeatures {
                weights!.data[j] -= learningRate * gradW[j]
            }
            
            if epoch % 100 == 0 {
                let mse = totalLoss / Float(nSamples)
                print("Epoch \(epoch): MSE = \(mse)")
            }
        }
    }
    
    private func fitSGD(x: [[Float]], y: [Float], learningRate: Float, epochs: Int, batchSize: Int) {
        let nSamples = x.count
        let nFeatures = x[0].count
        let nBatches = (nSamples + batchSize - 1) / batchSize
        
        // Initialize weights
        weights = Tensor.randn([nFeatures], mean: 0, std: 0.01)
        bias = 0
        
        for epoch in 0..<epochs {
            var indices = Array(0..<nSamples)
            indices.shuffle()
            
            for batch in 0..<nBatches {
                let start = batch * batchSize
                let end = min(start + batchSize, nSamples)
                let batchIndices = Array(indices[start..<end])
                
                var gradW = [Float](repeating: 0, count: nFeatures)
                var gradB: Float = 0
                
                for idx in batchIndices {
                    let prediction = predictSingle(x[idx])
                    let error = prediction - y[idx]
                    
                    gradB += error
                    for j in 0..<nFeatures {
                        gradW[j] += error * x[idx][j]
                    }
                }
                
                // Average and update
                let scale = 2.0 / Float(batchIndices.count)
                bias -= learningRate * gradB * scale
                for j in 0..<nFeatures {
                    weights!.data[j] -= learningRate * gradW[j] * scale
                }
            }
        }
    }
    
    // MARK: - Prediction
    public func predict(_ x: [[Float]]) -> [Float] {
        x.map { predictSingle($0) }
    }
    
    public func predictSingle(_ x: [Float]) -> Float {
        guard let w = weights else { return 0 }
        var result = bias
        vDSP_dotpr(w.data, 1, x, 1, &result, vDSP_Length(x.count))
        return result + bias
    }
    
    // MARK: - Evaluation
    public func score(x: [[Float]], y: [Float]) -> Float {
        let predictions = predict(x)
        let yMean = y.reduce(0, +) / Float(y.count)
        
        var ssRes: Float = 0
        var ssTot: Float = 0
        
        for i in 0..<y.count {
            let residual = y[i] - predictions[i]
            let deviation = y[i] - yMean
            ssRes += residual * residual
            ssTot += deviation * deviation
        }
        
        return 1 - (ssRes / ssTot)  // R² score
    }
    
    public func mse(x: [[Float]], y: [Float]) -> Float {
        let predictions = predict(x)
        var totalError: Float = 0
        for i in 0..<y.count {
            let error = y[i] - predictions[i]
            totalError += error * error
        }
        return totalError / Float(y.count)
    }
    
    // MARK: - Helpers
    private func solveLU(_ A: Tensor<Float>, _ b: Tensor<Float>) -> Tensor<Float> {
        // Simple Gaussian elimination with partial pivoting
        let n = A.shape[0]
        var augmented = [[Float]](repeating: [Float](repeating: 0, count: n + 1), count: n)
        
        for i in 0..<n {
            for j in 0..<n {
                augmented[i][j] = A.data[i * n + j]
            }
            augmented[i][n] = b.data[i]
        }
        
        // Forward elimination
        for k in 0..<n {
            // Find pivot
            var maxVal = abs(augmented[k][k])
            var maxRow = k
            for i in (k+1)..<n {
                if abs(augmented[i][k]) > maxVal {
                    maxVal = abs(augmented[i][k])
                    maxRow = i
                }
            }
            
            // Swap rows
            if maxRow != k {
                swap(&augmented[k], &augmented[maxRow])
            }
            
            // Eliminate
            for i in (k+1)..<n {
                if abs(augmented[k][k]) > 1e-10 {
                    let factor = augmented[i][k] / augmented[k][k]
                    for j in k..<(n+1) {
                        augmented[i][j] -= factor * augmented[k][j]
                    }
                }
            }
        }
        
        // Back substitution
        var x = [Float](repeating: 0, count: n)
        for i in stride(from: n - 1, through: 0, by: -1) {
            x[i] = augmented[i][n]
            for j in (i+1)..<n {
                x[i] -= augmented[i][j] * x[j]
            }
            if abs(augmented[i][i]) > 1e-10 {
                x[i] /= augmented[i][i]
            }
        }
        
        return Tensor(shape: [n, 1], data: x)
    }
}

// MARK: - Ridge Regression
public final class RidgeRegression: @unchecked Sendable {
    private let model: LinearRegression
    
    public var weights: Tensor<Float>? { model.weights }
    public var bias: Float { model.bias }
    
    public init(alpha: Float = 1.0) {
        model = LinearRegression(regularization: .l2(strength: alpha))
    }
    
    public func fit(x: [[Float]], y: [Float]) {
        model.fit(x: x, y: y)
    }
    
    public func predict(_ x: [[Float]]) -> [Float] {
        model.predict(x)
    }
    
    public func score(x: [[Float]], y: [Float]) -> Float {
        model.score(x: x, y: y)
    }
}

// MARK: - Lasso Regression
public final class LassoRegression: @unchecked Sendable {
    private let model: LinearRegression
    private let maxIterations: Int
    private let tolerance: Float
    
    public var weights: Tensor<Float>? { model.weights }
    public var bias: Float { model.bias }
    
    public init(alpha: Float = 1.0, maxIterations: Int = 1000, tolerance: Float = 1e-4) {
        self.model = LinearRegression(regularization: .l1(strength: alpha))
        self.maxIterations = maxIterations
        self.tolerance = tolerance
    }
    
    public func fit(x: [[Float]], y: [Float]) {
        model.fit(x: x, y: y, method: .gradientDescent(learningRate: 0.01, epochs: maxIterations))
    }
    
    public func predict(_ x: [[Float]]) -> [Float] {
        model.predict(x)
    }
    
    public func score(x: [[Float]], y: [Float]) -> Float {
        model.score(x: x, y: y)
    }
}

// MARK: - Elastic Net
public final class ElasticNet: @unchecked Sendable {
    private let model: LinearRegression
    private let maxIterations: Int
    
    public var weights: Tensor<Float>? { model.weights }
    public var bias: Float { model.bias }
    
    public init(alpha: Float = 1.0, l1Ratio: Float = 0.5, maxIterations: Int = 1000) {
        self.model = LinearRegression(regularization: .elasticNet(l1Ratio: l1Ratio, strength: alpha))
        self.maxIterations = maxIterations
    }
    
    public func fit(x: [[Float]], y: [Float]) {
        model.fit(x: x, y: y, method: .gradientDescent(learningRate: 0.01, epochs: maxIterations))
    }
    
    public func predict(_ x: [[Float]]) -> [Float] {
        model.predict(x)
    }
    
    public func score(x: [[Float]], y: [Float]) -> Float {
        model.score(x: x, y: y)
    }
}

// MARK: - Polynomial Features
public struct PolynomialFeatures: Sendable {
    public let degree: Int
    public let includeBias: Bool
    
    public init(degree: Int = 2, includeBias: Bool = true) {
        self.degree = degree
        self.includeBias = includeBias
    }
    
    public func transform(_ x: [[Float]]) -> [[Float]] {
        x.map { transformSingle($0) }
    }
    
    private func transformSingle(_ x: [Float]) -> [Float] {
        var result = [Float]()
        
        if includeBias {
            result.append(1.0)
        }
        
        // Generate all polynomial combinations up to degree
        for d in 1...degree {
            result.append(contentsOf: combinations(x, degree: d))
        }
        
        return result
    }
    
    private func combinations(_ x: [Float], degree: Int) -> [Float] {
        if degree == 1 {
            return x
        }
        
        var result = [Float]()
        
        // Simple power terms
        for val in x {
            result.append(pow(val, Float(degree)))
        }
        
        // Cross terms (simplified for degree 2)
        if degree == 2 && x.count > 1 {
            for i in 0..<x.count {
                for j in (i+1)..<x.count {
                    result.append(x[i] * x[j])
                }
            }
        }
        
        return result
    }
}
