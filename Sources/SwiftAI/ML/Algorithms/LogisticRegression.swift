// LogisticRegression.swift
// SwiftAI - Pure Swift Machine Learning Framework
// Copyright © 2024 Muhittin Camdali. All rights reserved.

import Foundation
import Accelerate

// MARK: - Logistic Regression
/// Binary and Multinomial Logistic Regression Classifier
public final class LogisticRegression: @unchecked Sendable {
    
    // MARK: - Properties
    public private(set) var weights: Tensor<Float>?
    public private(set) var bias: Tensor<Float>?
    public private(set) var classes: [Int] = []
    
    public let regularization: RegularizationType
    public let solver: Solver
    public let maxIterations: Int
    public let tolerance: Float
    
    // MARK: - Types
    public enum RegularizationType: Sendable {
        case none
        case l1(strength: Float)
        case l2(strength: Float)
    }
    
    public enum Solver: Sendable {
        case gradientDescent
        case newton
        case lbfgs
    }
    
    public enum MultiClass: Sendable {
        case ovr  // One-vs-Rest
        case multinomial
    }
    
    private var multiClass: MultiClass = .multinomial
    
    // MARK: - Initialization
    public init(
        regularization: RegularizationType = .l2(strength: 1.0),
        solver: Solver = .gradientDescent,
        maxIterations: Int = 100,
        tolerance: Float = 1e-4
    ) {
        self.regularization = regularization
        self.solver = solver
        self.maxIterations = maxIterations
        self.tolerance = tolerance
    }
    
    // MARK: - Sigmoid
    private func sigmoid(_ x: Float) -> Float {
        1.0 / (1.0 + exp(-x))
    }
    
    private func sigmoid(_ x: [Float]) -> [Float] {
        x.map { 1.0 / (1.0 + exp(-$0)) }
    }
    
    // MARK: - Softmax
    private func softmax(_ x: [Float]) -> [Float] {
        let maxVal = x.max() ?? 0
        let exps = x.map { exp($0 - maxVal) }
        let sum = exps.reduce(0, +)
        return exps.map { $0 / sum }
    }
    
    // MARK: - Fitting
    public func fit(x: [[Float]], y: [Int], learningRate: Float = 0.01) {
        precondition(x.count == y.count, "X and Y must have same number of samples")
        precondition(!x.isEmpty, "Data cannot be empty")
        
        classes = Array(Set(y)).sorted()
        let nSamples = x.count
        let nFeatures = x[0].count
        let nClasses = classes.count
        
        if nClasses == 2 {
            // Binary classification
            fitBinary(x: x, y: y, learningRate: learningRate, nFeatures: nFeatures)
        } else {
            // Multinomial classification
            fitMultinomial(x: x, y: y, learningRate: learningRate, nFeatures: nFeatures, nClasses: nClasses)
        }
    }
    
    private func fitBinary(x: [[Float]], y: [Int], learningRate: Float, nFeatures: Int) {
        // Initialize weights
        weights = Tensor.randn([nFeatures], mean: 0, std: 0.01)
        bias = Tensor.zeros([1])
        
        let nSamples = x.count
        
        // Convert labels to 0/1
        let yBinary = y.map { Float($0 == classes[1] ? 1 : 0) }
        
        var prevLoss: Float = .infinity
        
        for iteration in 0..<maxIterations {
            // Forward pass
            var predictions = [Float](repeating: 0, count: nSamples)
            for i in 0..<nSamples {
                var logit = bias!.data[0]
                for j in 0..<nFeatures {
                    logit += weights!.data[j] * x[i][j]
                }
                predictions[i] = sigmoid(logit)
            }
            
            // Compute loss
            var loss: Float = 0
            for i in 0..<nSamples {
                let p = max(min(predictions[i], 1 - 1e-7), 1e-7)
                loss -= yBinary[i] * log(p) + (1 - yBinary[i]) * log(1 - p)
            }
            loss /= Float(nSamples)
            
            // Add regularization
            switch regularization {
            case .l2(let strength):
                var regTerm: Float = 0
                for w in weights!.data {
                    regTerm += w * w
                }
                loss += strength * regTerm / (2 * Float(nSamples))
            default:
                break
            }
            
            // Check convergence
            if abs(prevLoss - loss) < tolerance {
                print("Converged at iteration \(iteration)")
                break
            }
            prevLoss = loss
            
            // Compute gradients
            var gradW = [Float](repeating: 0, count: nFeatures)
            var gradB: Float = 0
            
            for i in 0..<nSamples {
                let error = predictions[i] - yBinary[i]
                gradB += error
                for j in 0..<nFeatures {
                    gradW[j] += error * x[i][j]
                }
            }
            
            // Average gradients
            gradB /= Float(nSamples)
            for j in 0..<nFeatures {
                gradW[j] /= Float(nSamples)
            }
            
            // Add regularization gradient
            switch regularization {
            case .l2(let strength):
                for j in 0..<nFeatures {
                    gradW[j] += strength * weights!.data[j] / Float(nSamples)
                }
            case .l1(let strength):
                for j in 0..<nFeatures {
                    gradW[j] += strength * (weights!.data[j] > 0 ? 1 : -1) / Float(nSamples)
                }
            default:
                break
            }
            
            // Update weights
            bias!.data[0] -= learningRate * gradB
            for j in 0..<nFeatures {
                weights!.data[j] -= learningRate * gradW[j]
            }
            
            if iteration % 100 == 0 {
                print("Iteration \(iteration): Loss = \(loss)")
            }
        }
    }
    
    private func fitMultinomial(x: [[Float]], y: [Int], learningRate: Float, nFeatures: Int, nClasses: Int) {
        // Initialize weights [nFeatures x nClasses]
        weights = Tensor.randn([nFeatures, nClasses], mean: 0, std: 0.01)
        bias = Tensor.zeros([nClasses])
        
        let nSamples = x.count
        
        // Create one-hot encoded targets
        var yOneHot = [[Float]]()
        for label in y {
            var oneHot = [Float](repeating: 0, count: nClasses)
            if let idx = classes.firstIndex(of: label) {
                oneHot[idx] = 1
            }
            yOneHot.append(oneHot)
        }
        
        var prevLoss: Float = .infinity
        
        for iteration in 0..<maxIterations {
            // Forward pass - compute softmax probabilities
            var predictions = [[Float]]()
            for i in 0..<nSamples {
                var logits = [Float](repeating: 0, count: nClasses)
                for c in 0..<nClasses {
                    logits[c] = bias!.data[c]
                    for j in 0..<nFeatures {
                        logits[c] += weights!.data[j * nClasses + c] * x[i][j]
                    }
                }
                predictions.append(softmax(logits))
            }
            
            // Compute cross-entropy loss
            var loss: Float = 0
            for i in 0..<nSamples {
                for c in 0..<nClasses {
                    if yOneHot[i][c] > 0 {
                        loss -= log(max(predictions[i][c], 1e-7))
                    }
                }
            }
            loss /= Float(nSamples)
            
            // Check convergence
            if abs(prevLoss - loss) < tolerance {
                print("Converged at iteration \(iteration)")
                break
            }
            prevLoss = loss
            
            // Compute gradients
            var gradW = [Float](repeating: 0, count: nFeatures * nClasses)
            var gradB = [Float](repeating: 0, count: nClasses)
            
            for i in 0..<nSamples {
                for c in 0..<nClasses {
                    let error = predictions[i][c] - yOneHot[i][c]
                    gradB[c] += error
                    for j in 0..<nFeatures {
                        gradW[j * nClasses + c] += error * x[i][j]
                    }
                }
            }
            
            // Average and update
            for c in 0..<nClasses {
                bias!.data[c] -= learningRate * gradB[c] / Float(nSamples)
            }
            for idx in 0..<gradW.count {
                weights!.data[idx] -= learningRate * gradW[idx] / Float(nSamples)
            }
            
            if iteration % 100 == 0 {
                print("Iteration \(iteration): Loss = \(loss)")
            }
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
        guard let w = weights, let b = bias else { return [] }
        
        if classes.count == 2 {
            // Binary
            var logit = b.data[0]
            for j in 0..<x.count {
                logit += w.data[j] * x[j]
            }
            let p = sigmoid(logit)
            return [1 - p, p]
        } else {
            // Multinomial
            let nClasses = classes.count
            var logits = [Float](repeating: 0, count: nClasses)
            for c in 0..<nClasses {
                logits[c] = b.data[c]
                for j in 0..<x.count {
                    logits[c] += w.data[j * nClasses + c] * x[j]
                }
            }
            return softmax(logits)
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
    
    public func confusionMatrix(x: [[Float]], y: [Int]) -> [[Int]] {
        let predictions = predict(x)
        let nClasses = classes.count
        var matrix = [[Int]](repeating: [Int](repeating: 0, count: nClasses), count: nClasses)
        
        for i in 0..<y.count {
            if let trueIdx = classes.firstIndex(of: y[i]),
               let predIdx = classes.firstIndex(of: predictions[i]) {
                matrix[trueIdx][predIdx] += 1
            }
        }
        
        return matrix
    }
    
    public func classificationReport(x: [[Float]], y: [Int]) -> String {
        let predictions = predict(x)
        let nClasses = classes.count
        
        var report = "              precision    recall  f1-score   support\n\n"
        
        var totalPrecision: Float = 0
        var totalRecall: Float = 0
        var totalF1: Float = 0
        var totalSupport = 0
        
        for (i, cls) in classes.enumerated() {
            var tp = 0, fp = 0, fn = 0
            var support = 0
            
            for j in 0..<y.count {
                let actual = y[j]
                let predicted = predictions[j]
                
                if actual == cls {
                    support += 1
                    if predicted == cls {
                        tp += 1
                    } else {
                        fn += 1
                    }
                } else if predicted == cls {
                    fp += 1
                }
            }
            
            let precision = tp + fp > 0 ? Float(tp) / Float(tp + fp) : 0
            let recall = tp + fn > 0 ? Float(tp) / Float(tp + fn) : 0
            let f1 = precision + recall > 0 ? 2 * precision * recall / (precision + recall) : 0
            
            report += String(format: "%12d    %7.2f    %6.2f    %7.2f    %7d\n",
                           cls, precision, recall, f1, support)
            
            totalPrecision += precision * Float(support)
            totalRecall += recall * Float(support)
            totalF1 += f1 * Float(support)
            totalSupport += support
        }
        
        let accuracy = Float(zip(y, predictions).filter { $0 == $1 }.count) / Float(y.count)
        
        report += String(format: "\n    accuracy                        %7.2f    %7d\n",
                        accuracy, totalSupport)
        report += String(format: "   macro avg    %7.2f    %6.2f    %7.2f    %7d\n",
                        totalPrecision / Float(nClasses),
                        totalRecall / Float(nClasses),
                        totalF1 / Float(nClasses),
                        totalSupport)
        report += String(format: "weighted avg    %7.2f    %6.2f    %7.2f    %7d\n",
                        totalPrecision / Float(totalSupport),
                        totalRecall / Float(totalSupport),
                        totalF1 / Float(totalSupport),
                        totalSupport)
        
        return report
    }
}
