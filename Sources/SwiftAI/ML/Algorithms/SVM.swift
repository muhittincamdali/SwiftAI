// SVM.swift
// SwiftAI - Pure Swift Machine Learning Framework
// Copyright © 2024 Muhittin Camdali. All rights reserved.

import Foundation
import Accelerate

// MARK: - Support Vector Machine Classifier
public final class SVC: @unchecked Sendable {
    
    // MARK: - Properties
    public private(set) var supportVectors: [[Float]]?
    public private(set) var supportVectorLabels: [Float]?
    public private(set) var alphas: [Float]?
    public private(set) var bias: Float = 0
    public private(set) var classes: [Int] = []
    
    public let C: Float  // Regularization parameter
    public let kernel: Kernel
    public let tolerance: Float
    public let maxIterations: Int
    
    // MARK: - Kernel Types
    public enum Kernel: Sendable {
        case linear
        case rbf(gamma: Float)
        case polynomial(degree: Int, gamma: Float, coef0: Float)
        case sigmoid(gamma: Float, coef0: Float)
    }
    
    // MARK: - Initialization
    public init(
        C: Float = 1.0,
        kernel: Kernel = .rbf(gamma: 0.1),
        tolerance: Float = 1e-3,
        maxIterations: Int = 1000
    ) {
        self.C = C
        self.kernel = kernel
        self.tolerance = tolerance
        self.maxIterations = maxIterations
    }
    
    // MARK: - Kernel Computation
    private func computeKernel(_ a: [Float], _ b: [Float]) -> Float {
        switch kernel {
        case .linear:
            return dotProduct(a, b)
            
        case .rbf(let gamma):
            let diff = zip(a, b).map { $0 - $1 }
            let sqNorm = diff.reduce(0) { $0 + $1 * $1 }
            return exp(-gamma * sqNorm)
            
        case .polynomial(let degree, let gamma, let coef0):
            let dot = dotProduct(a, b)
            return pow(gamma * dot + coef0, Float(degree))
            
        case .sigmoid(let gamma, let coef0):
            let dot = dotProduct(a, b)
            return tanh(gamma * dot + coef0)
        }
    }
    
    private func dotProduct(_ a: [Float], _ b: [Float]) -> Float {
        var result: Float = 0
        vDSP_dotpr(a, 1, b, 1, &result, vDSP_Length(a.count))
        return result
    }
    
    // MARK: - Fitting (SMO Algorithm)
    public func fit(x: [[Float]], y: [Int]) {
        precondition(x.count == y.count, "X and Y must have same number of samples")
        precondition(!x.isEmpty, "Data cannot be empty")
        
        classes = Array(Set(y)).sorted()
        precondition(classes.count == 2, "SVC requires exactly 2 classes for binary classification")
        
        // Convert labels to -1, +1
        let yConverted = y.map { Float($0 == classes[1] ? 1 : -1) }
        
        trainSMO(x: x, y: yConverted)
    }
    
    private func trainSMO(x: [[Float]], y: [Float]) {
        let n = x.count
        
        // Initialize alphas
        var alpha = [Float](repeating: 0, count: n)
        var b: Float = 0
        
        // Precompute kernel matrix
        var K = [[Float]](repeating: [Float](repeating: 0, count: n), count: n)
        for i in 0..<n {
            for j in i..<n {
                K[i][j] = computeKernel(x[i], x[j])
                K[j][i] = K[i][j]
            }
        }
        
        // SMO main loop
        var passes = 0
        while passes < maxIterations {
            var numChanged = 0
            
            for i in 0..<n {
                // Compute E_i = f(x_i) - y_i
                var f_i: Float = -b
                for j in 0..<n {
                    f_i += alpha[j] * y[j] * K[i][j]
                }
                let E_i = f_i - y[i]
                
                // Check KKT conditions
                let r_i = E_i * y[i]
                if (r_i < -tolerance && alpha[i] < C) || (r_i > tolerance && alpha[i] > 0) {
                    // Select j randomly (simplified)
                    var j = Int.random(in: 0..<n)
                    while j == i { j = Int.random(in: 0..<n) }
                    
                    // Compute E_j
                    var f_j: Float = -b
                    for k in 0..<n {
                        f_j += alpha[k] * y[k] * K[j][k]
                    }
                    let E_j = f_j - y[j]
                    
                    // Save old alphas
                    let alpha_i_old = alpha[i]
                    let alpha_j_old = alpha[j]
                    
                    // Compute bounds
                    let L: Float
                    let H: Float
                    if y[i] != y[j] {
                        L = max(0, alpha[j] - alpha[i])
                        H = min(C, C + alpha[j] - alpha[i])
                    } else {
                        L = max(0, alpha[i] + alpha[j] - C)
                        H = min(C, alpha[i] + alpha[j])
                    }
                    
                    if L == H { continue }
                    
                    // Compute eta
                    let eta = 2 * K[i][j] - K[i][i] - K[j][j]
                    if eta >= 0 { continue }
                    
                    // Compute new alpha_j
                    alpha[j] = alpha[j] - y[j] * (E_i - E_j) / eta
                    alpha[j] = min(H, max(L, alpha[j]))
                    
                    if abs(alpha[j] - alpha_j_old) < 1e-5 { continue }
                    
                    // Compute new alpha_i
                    alpha[i] = alpha[i] + y[i] * y[j] * (alpha_j_old - alpha[j])
                    
                    // Compute new b
                    let b1 = b - E_i - y[i] * (alpha[i] - alpha_i_old) * K[i][i] -
                             y[j] * (alpha[j] - alpha_j_old) * K[i][j]
                    let b2 = b - E_j - y[i] * (alpha[i] - alpha_i_old) * K[i][j] -
                             y[j] * (alpha[j] - alpha_j_old) * K[j][j]
                    
                    if alpha[i] > 0 && alpha[i] < C {
                        b = b1
                    } else if alpha[j] > 0 && alpha[j] < C {
                        b = b2
                    } else {
                        b = (b1 + b2) / 2
                    }
                    
                    numChanged += 1
                }
            }
            
            if numChanged == 0 {
                passes += 1
            } else {
                passes = 0
            }
        }
        
        // Extract support vectors
        var svIndices = [Int]()
        for i in 0..<n {
            if alpha[i] > 1e-5 {
                svIndices.append(i)
            }
        }
        
        supportVectors = svIndices.map { x[$0] }
        supportVectorLabels = svIndices.map { y[$0] }
        alphas = svIndices.map { alpha[$0] }
        bias = b
    }
    
    // MARK: - Prediction
    public func predict(_ x: [[Float]]) -> [Int] {
        x.map { predictSingle($0) }
    }
    
    public func predictSingle(_ x: [Float]) -> Int {
        let score = decisionFunction(x)
        return score >= 0 ? classes[1] : classes[0]
    }
    
    public func decisionFunction(_ x: [Float]) -> Float {
        guard let svs = supportVectors,
              let svLabels = supportVectorLabels,
              let alpha = alphas else { return 0 }
        
        var result: Float = -bias
        for i in 0..<svs.count {
            result += alpha[i] * svLabels[i] * computeKernel(x, svs[i])
        }
        return result
    }
    
    public func decisionFunctionBatch(_ x: [[Float]]) -> [Float] {
        x.map { decisionFunction($0) }
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
}

// MARK: - Support Vector Regression
public final class SVR: @unchecked Sendable {
    
    // MARK: - Properties
    public private(set) var supportVectors: [[Float]]?
    public private(set) var supportVectorTargets: [Float]?
    public private(set) var alphas: [Float]?  // alpha - alpha*
    public private(set) var bias: Float = 0
    
    public let C: Float
    public let epsilon: Float
    public let kernel: SVC.Kernel
    public let maxIterations: Int
    
    // MARK: - Initialization
    public init(
        C: Float = 1.0,
        epsilon: Float = 0.1,
        kernel: SVC.Kernel = .rbf(gamma: 0.1),
        maxIterations: Int = 1000
    ) {
        self.C = C
        self.epsilon = epsilon
        self.kernel = kernel
        self.maxIterations = maxIterations
    }
    
    // MARK: - Kernel
    private func computeKernel(_ a: [Float], _ b: [Float]) -> Float {
        switch kernel {
        case .linear:
            var result: Float = 0
            vDSP_dotpr(a, 1, b, 1, &result, vDSP_Length(a.count))
            return result
            
        case .rbf(let gamma):
            let diff = zip(a, b).map { $0 - $1 }
            let sqNorm = diff.reduce(0) { $0 + $1 * $1 }
            return exp(-gamma * sqNorm)
            
        case .polynomial(let degree, let gamma, let coef0):
            var dot: Float = 0
            vDSP_dotpr(a, 1, b, 1, &dot, vDSP_Length(a.count))
            return pow(gamma * dot + coef0, Float(degree))
            
        case .sigmoid(let gamma, let coef0):
            var dot: Float = 0
            vDSP_dotpr(a, 1, b, 1, &dot, vDSP_Length(a.count))
            return tanh(gamma * dot + coef0)
        }
    }
    
    // MARK: - Fitting
    public func fit(x: [[Float]], y: [Float]) {
        precondition(x.count == y.count, "X and Y must have same number of samples")
        
        let n = x.count
        
        // Simple gradient descent approach for SVR
        var alpha = [Float](repeating: 0, count: n)
        var alphaStar = [Float](repeating: 0, count: n)
        var b: Float = 0
        
        let learningRate: Float = 0.01
        
        for _ in 0..<maxIterations {
            for i in 0..<n {
                // Compute prediction
                var pred = b
                for j in 0..<n {
                    pred += (alpha[j] - alphaStar[j]) * computeKernel(x[i], x[j])
                }
                
                let error = pred - y[i]
                
                // Update alpha based on epsilon-insensitive loss
                if error > epsilon {
                    alphaStar[i] = min(C, alphaStar[i] + learningRate)
                } else if error < -epsilon {
                    alpha[i] = min(C, alpha[i] + learningRate)
                }
                
                // Update bias
                b -= learningRate * error * 0.1
            }
        }
        
        // Extract support vectors
        var svIndices = [Int]()
        for i in 0..<n {
            if alpha[i] > 1e-5 || alphaStar[i] > 1e-5 {
                svIndices.append(i)
            }
        }
        
        supportVectors = svIndices.map { x[$0] }
        supportVectorTargets = svIndices.map { y[$0] }
        alphas = svIndices.map { alpha[$0] - alphaStar[$0] }
        bias = b
    }
    
    // MARK: - Prediction
    public func predict(_ x: [[Float]]) -> [Float] {
        x.map { predictSingle($0) }
    }
    
    public func predictSingle(_ x: [Float]) -> Float {
        guard let svs = supportVectors,
              let alpha = alphas else { return 0 }
        
        var result = bias
        for i in 0..<svs.count {
            result += alpha[i] * computeKernel(x, svs[i])
        }
        return result
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

// MARK: - One-vs-Rest Multi-class SVM
public final class OneVsRestSVC: @unchecked Sendable {
    
    public private(set) var classifiers: [SVC] = []
    public private(set) var classes: [Int] = []
    
    public let C: Float
    public let kernel: SVC.Kernel
    
    public init(C: Float = 1.0, kernel: SVC.Kernel = .rbf(gamma: 0.1)) {
        self.C = C
        self.kernel = kernel
    }
    
    public func fit(x: [[Float]], y: [Int]) {
        classes = Array(Set(y)).sorted()
        classifiers = []
        
        for cls in classes {
            // Create binary labels
            let binaryY = y.map { $0 == cls ? 1 : 0 }
            
            let svc = SVC(C: C, kernel: kernel)
            svc.fit(x: x, y: binaryY)
            classifiers.append(svc)
        }
    }
    
    public func predict(_ x: [[Float]]) -> [Int] {
        x.map { predictSingle($0) }
    }
    
    public func predictSingle(_ x: [Float]) -> Int {
        var maxScore: Float = -.infinity
        var bestClass = classes[0]
        
        for (i, classifier) in classifiers.enumerated() {
            let score = classifier.decisionFunction(x)
            if score > maxScore {
                maxScore = score
                bestClass = classes[i]
            }
        }
        
        return bestClass
    }
    
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
}
