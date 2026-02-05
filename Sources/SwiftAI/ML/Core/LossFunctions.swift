// LossFunctions.swift
// SwiftAI - Pure Swift Machine Learning Framework
// Copyright © 2024 Muhittin Camdali. All rights reserved.

import Foundation
import Accelerate

// MARK: - Loss Function Protocol
public protocol LossFunction: Sendable {
    func forward(predictions: Tensor<Float>, targets: Tensor<Float>) -> Float
    func backward(predictions: Tensor<Float>, targets: Tensor<Float>) -> Tensor<Float>
    var name: String { get }
}

// MARK: - Mean Squared Error (MSE)
public struct MSELoss: LossFunction {
    public let name = "MSE"
    
    public init() {}
    
    public func forward(predictions: Tensor<Float>, targets: Tensor<Float>) -> Float {
        precondition(predictions.shape == targets.shape, "Shapes must match")
        var diff = [Float](repeating: 0, count: predictions.count)
        vDSP_vsub(targets.data, 1, predictions.data, 1, &diff, 1, vDSP_Length(predictions.count))
        var sumSq: Float = 0
        vDSP_svesq(diff, 1, &sumSq, vDSP_Length(predictions.count))
        return sumSq / Float(predictions.count)
    }
    
    public func backward(predictions: Tensor<Float>, targets: Tensor<Float>) -> Tensor<Float> {
        var diff = [Float](repeating: 0, count: predictions.count)
        vDSP_vsub(targets.data, 1, predictions.data, 1, &diff, 1, vDSP_Length(predictions.count))
        var scale = 2.0 / Float(predictions.count)
        var result = [Float](repeating: 0, count: predictions.count)
        vDSP_vsmul(diff, 1, &scale, &result, 1, vDSP_Length(predictions.count))
        return Tensor(shape: predictions.shape, data: result)
    }
}

// MARK: - Mean Absolute Error (MAE)
public struct MAELoss: LossFunction {
    public let name = "MAE"
    
    public init() {}
    
    public func forward(predictions: Tensor<Float>, targets: Tensor<Float>) -> Float {
        precondition(predictions.shape == targets.shape, "Shapes must match")
        var diff = [Float](repeating: 0, count: predictions.count)
        vDSP_vsub(targets.data, 1, predictions.data, 1, &diff, 1, vDSP_Length(predictions.count))
        var absSum: Float = 0
        vDSP_svemg(diff, 1, &absSum, vDSP_Length(predictions.count))
        return absSum / Float(predictions.count)
    }
    
    public func backward(predictions: Tensor<Float>, targets: Tensor<Float>) -> Tensor<Float> {
        let scale = 1.0 / Float(predictions.count)
        let result = zip(predictions.data, targets.data).map { p, t -> Float in
            if p > t { return scale }
            else if p < t { return -scale }
            else { return 0 }
        }
        return Tensor(shape: predictions.shape, data: result)
    }
}

// MARK: - Huber Loss (Smooth L1)
public struct HuberLoss: LossFunction {
    public let name = "Huber"
    public let delta: Float
    
    public init(delta: Float = 1.0) {
        self.delta = delta
    }
    
    public func forward(predictions: Tensor<Float>, targets: Tensor<Float>) -> Float {
        precondition(predictions.shape == targets.shape, "Shapes must match")
        let loss = zip(predictions.data, targets.data).map { p, t -> Float in
            let diff = abs(p - t)
            if diff <= delta {
                return 0.5 * diff * diff
            } else {
                return delta * (diff - 0.5 * delta)
            }
        }
        return loss.reduce(0, +) / Float(predictions.count)
    }
    
    public func backward(predictions: Tensor<Float>, targets: Tensor<Float>) -> Tensor<Float> {
        let scale = 1.0 / Float(predictions.count)
        let result = zip(predictions.data, targets.data).map { p, t -> Float in
            let diff = p - t
            if abs(diff) <= delta {
                return diff * scale
            } else {
                return (diff > 0 ? delta : -delta) * scale
            }
        }
        return Tensor(shape: predictions.shape, data: result)
    }
}

// MARK: - Binary Cross Entropy
public struct BCELoss: LossFunction {
    public let name = "BCE"
    private let eps: Float = 1e-7
    
    public init() {}
    
    public func forward(predictions: Tensor<Float>, targets: Tensor<Float>) -> Float {
        precondition(predictions.shape == targets.shape, "Shapes must match")
        let loss = zip(predictions.data, targets.data).map { p, t -> Float in
            let clipped = Swift.min(Swift.max(p, eps), 1 - eps)
            return -(t * log(clipped) + (1 - t) * log(1 - clipped))
        }
        return loss.reduce(0, +) / Float(predictions.count)
    }
    
    public func backward(predictions: Tensor<Float>, targets: Tensor<Float>) -> Tensor<Float> {
        let scale = 1.0 / Float(predictions.count)
        let result = zip(predictions.data, targets.data).map { p, t -> Float in
            let clipped = Swift.min(Swift.max(p, eps), 1 - eps)
            return scale * (-t / clipped + (1 - t) / (1 - clipped))
        }
        return Tensor(shape: predictions.shape, data: result)
    }
}

// MARK: - Binary Cross Entropy with Logits
public struct BCEWithLogitsLoss: LossFunction {
    public let name = "BCEWithLogits"
    
    public init() {}
    
    public func forward(predictions: Tensor<Float>, targets: Tensor<Float>) -> Float {
        precondition(predictions.shape == targets.shape, "Shapes must match")
        let loss = zip(predictions.data, targets.data).map { logit, t -> Float in
            let maxVal = Swift.max(0, -logit)
            return maxVal + logit * (1 - t) + log(exp(-maxVal) + exp(-logit - maxVal))
        }
        return loss.reduce(0, +) / Float(predictions.count)
    }
    
    public func backward(predictions: Tensor<Float>, targets: Tensor<Float>) -> Tensor<Float> {
        let scale = 1.0 / Float(predictions.count)
        let result = zip(predictions.data, targets.data).map { logit, t -> Float in
            let sigmoid = 1.0 / (1.0 + exp(-logit))
            return scale * (sigmoid - t)
        }
        return Tensor(shape: predictions.shape, data: result)
    }
}

// MARK: - Cross Entropy Loss
public struct CrossEntropyLoss: LossFunction {
    public let name = "CrossEntropy"
    private let eps: Float = 1e-7
    
    public init() {}
    
    public func forward(predictions: Tensor<Float>, targets: Tensor<Float>) -> Float {
        precondition(predictions.shape == targets.shape, "Shapes must match")
        // Apply softmax then compute cross entropy
        let softmax = computeSoftmax(predictions)
        let loss = zip(softmax.data, targets.data).map { p, t -> Float in
            if t > 0 {
                return -t * log(Swift.max(p, eps))
            }
            return 0
        }
        return loss.reduce(0, +) / Float(predictions.shape[0])
    }
    
    public func backward(predictions: Tensor<Float>, targets: Tensor<Float>) -> Tensor<Float> {
        let softmax = computeSoftmax(predictions)
        let scale = 1.0 / Float(predictions.shape[0])
        var result = [Float](repeating: 0, count: predictions.count)
        vDSP_vsub(targets.data, 1, softmax.data, 1, &result, 1, vDSP_Length(predictions.count))
        vDSP_vsmul(result, 1, [scale], &result, 1, vDSP_Length(predictions.count))
        return Tensor(shape: predictions.shape, data: result)
    }
    
    private func computeSoftmax(_ x: Tensor<Float>) -> Tensor<Float> {
        if x.rank == 1 {
            let maxVal = x.max()
            let shifted = x.data.map { $0 - maxVal }
            let exps = shifted.map { exp($0) }
            let sum = exps.reduce(0, +)
            return Tensor(shape: x.shape, data: exps.map { $0 / sum })
        }
        // 2D: softmax per row
        var result = [Float](repeating: 0, count: x.count)
        let cols = x.shape[1]
        for row in 0..<x.shape[0] {
            let start = row * cols
            let rowData = Array(x.data[start..<(start + cols)])
            let maxVal = rowData.max() ?? 0
            let shifted = rowData.map { $0 - maxVal }
            let exps = shifted.map { exp($0) }
            let sum = exps.reduce(0, +)
            for col in 0..<cols {
                result[start + col] = exps[col] / sum
            }
        }
        return Tensor(shape: x.shape, data: result)
    }
}

// MARK: - Negative Log Likelihood Loss
public struct NLLLoss: LossFunction {
    public let name = "NLL"
    
    public init() {}
    
    public func forward(predictions: Tensor<Float>, targets: Tensor<Float>) -> Float {
        // predictions: log probabilities, targets: class indices as one-hot
        precondition(predictions.shape == targets.shape, "Shapes must match")
        var loss: Float = 0
        for i in 0..<predictions.count {
            if targets.data[i] > 0 {
                loss -= predictions.data[i] * targets.data[i]
            }
        }
        return loss / Float(predictions.shape[0])
    }
    
    public func backward(predictions: Tensor<Float>, targets: Tensor<Float>) -> Tensor<Float> {
        let scale = -1.0 / Float(predictions.shape[0])
        let result = targets.data.map { $0 * scale }
        return Tensor(shape: predictions.shape, data: result)
    }
}

// MARK: - Hinge Loss (SVM)
public struct HingeLoss: LossFunction {
    public let name = "Hinge"
    
    public init() {}
    
    public func forward(predictions: Tensor<Float>, targets: Tensor<Float>) -> Float {
        // targets should be -1 or 1
        precondition(predictions.shape == targets.shape, "Shapes must match")
        let loss = zip(predictions.data, targets.data).map { p, t -> Float in
            Swift.max(0, 1 - t * p)
        }
        return loss.reduce(0, +) / Float(predictions.count)
    }
    
    public func backward(predictions: Tensor<Float>, targets: Tensor<Float>) -> Tensor<Float> {
        let scale = 1.0 / Float(predictions.count)
        let result = zip(predictions.data, targets.data).map { p, t -> Float in
            if t * p < 1 {
                return -t * scale
            }
            return 0
        }
        return Tensor(shape: predictions.shape, data: result)
    }
}

// MARK: - Cosine Embedding Loss
public struct CosineEmbeddingLoss: LossFunction {
    public let name = "CosineEmbedding"
    public let margin: Float
    
    public init(margin: Float = 0.0) {
        self.margin = margin
    }
    
    public func forward(predictions: Tensor<Float>, targets: Tensor<Float>) -> Float {
        // For simplicity, treating as cosine similarity loss
        let dot = zip(predictions.data, targets.data).map { $0 * $1 }.reduce(0, +)
        let normP = sqrt(predictions.data.map { $0 * $0 }.reduce(0, +))
        let normT = sqrt(targets.data.map { $0 * $0 }.reduce(0, +))
        let cosine = dot / (normP * normT + 1e-8)
        return 1 - cosine
    }
    
    public func backward(predictions: Tensor<Float>, targets: Tensor<Float>) -> Tensor<Float> {
        let dot = zip(predictions.data, targets.data).map { $0 * $1 }.reduce(0, +)
        let normP = sqrt(predictions.data.map { $0 * $0 }.reduce(0, +))
        let normT = sqrt(targets.data.map { $0 * $0 }.reduce(0, +))
        let denom = normP * normT + 1e-8
        
        let result = zip(predictions.data, targets.data).map { p, t -> Float in
            (dot * p / (normP * normP) - t) / denom
        }
        return Tensor(shape: predictions.shape, data: result)
    }
}

// MARK: - Loss Factory
public enum LossType: String, CaseIterable, Sendable {
    case mse
    case mae
    case huber
    case bce
    case bceWithLogits
    case crossEntropy
    case nll
    case hinge
    case cosineEmbedding
    
    public func create() -> any LossFunction {
        switch self {
        case .mse: return MSELoss()
        case .mae: return MAELoss()
        case .huber: return HuberLoss()
        case .bce: return BCELoss()
        case .bceWithLogits: return BCEWithLogitsLoss()
        case .crossEntropy: return CrossEntropyLoss()
        case .nll: return NLLLoss()
        case .hinge: return HingeLoss()
        case .cosineEmbedding: return CosineEmbeddingLoss()
        }
    }
}
