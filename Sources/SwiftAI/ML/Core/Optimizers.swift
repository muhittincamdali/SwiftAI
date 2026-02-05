// Optimizers.swift
// SwiftAI - Pure Swift Machine Learning Framework
// Copyright © 2024 Muhittin Camdali. All rights reserved.

import Foundation
import Accelerate

// MARK: - Optimizer Protocol
public protocol Optimizer: AnyObject, Sendable {
    var learningRate: Float { get set }
    func step(parameters: inout [Tensor<Float>], gradients: [Tensor<Float>])
    func reset()
    var name: String { get }
}

// MARK: - SGD (Stochastic Gradient Descent)
public final class SGD: Optimizer, @unchecked Sendable {
    public let name = "SGD"
    public var learningRate: Float
    public let momentum: Float
    public let nesterov: Bool
    public let weightDecay: Float
    
    private var velocities: [Tensor<Float>]?
    
    public init(
        learningRate: Float = 0.01,
        momentum: Float = 0.0,
        nesterov: Bool = false,
        weightDecay: Float = 0.0
    ) {
        self.learningRate = learningRate
        self.momentum = momentum
        self.nesterov = nesterov
        self.weightDecay = weightDecay
    }
    
    public func step(parameters: inout [Tensor<Float>], gradients: [Tensor<Float>]) {
        precondition(parameters.count == gradients.count)
        
        if velocities == nil {
            velocities = parameters.map { Tensor.zeros($0.shape) }
        }
        
        for i in 0..<parameters.count {
            var grad = gradients[i].data
            
            // Weight decay
            if weightDecay > 0 {
                for j in 0..<grad.count {
                    grad[j] += weightDecay * parameters[i].data[j]
                }
            }
            
            if momentum > 0 {
                // v = momentum * v + grad
                for j in 0..<velocities![i].data.count {
                    velocities![i].data[j] = momentum * velocities![i].data[j] + grad[j]
                }
                
                if nesterov {
                    // param -= lr * (grad + momentum * v)
                    for j in 0..<parameters[i].data.count {
                        parameters[i].data[j] -= learningRate * (grad[j] + momentum * velocities![i].data[j])
                    }
                } else {
                    // param -= lr * v
                    for j in 0..<parameters[i].data.count {
                        parameters[i].data[j] -= learningRate * velocities![i].data[j]
                    }
                }
            } else {
                // Simple SGD: param -= lr * grad
                for j in 0..<parameters[i].data.count {
                    parameters[i].data[j] -= learningRate * grad[j]
                }
            }
        }
    }
    
    public func reset() {
        velocities = nil
    }
}

// MARK: - Adam Optimizer
public final class Adam: Optimizer, @unchecked Sendable {
    public let name = "Adam"
    public var learningRate: Float
    public let beta1: Float
    public let beta2: Float
    public let epsilon: Float
    public let weightDecay: Float
    public let amsgrad: Bool
    
    private var m: [Tensor<Float>]?  // First moment
    private var v: [Tensor<Float>]?  // Second moment
    private var vMax: [Tensor<Float>]?  // For AMSGrad
    private var t: Int = 0
    
    public init(
        learningRate: Float = 0.001,
        beta1: Float = 0.9,
        beta2: Float = 0.999,
        epsilon: Float = 1e-8,
        weightDecay: Float = 0.0,
        amsgrad: Bool = false
    ) {
        self.learningRate = learningRate
        self.beta1 = beta1
        self.beta2 = beta2
        self.epsilon = epsilon
        self.weightDecay = weightDecay
        self.amsgrad = amsgrad
    }
    
    public func step(parameters: inout [Tensor<Float>], gradients: [Tensor<Float>]) {
        precondition(parameters.count == gradients.count)
        
        if m == nil {
            m = parameters.map { Tensor.zeros($0.shape) }
            v = parameters.map { Tensor.zeros($0.shape) }
            if amsgrad {
                vMax = parameters.map { Tensor.zeros($0.shape) }
            }
        }
        
        t += 1
        let biasCorrection1 = 1 - pow(beta1, Float(t))
        let biasCorrection2 = 1 - pow(beta2, Float(t))
        
        for i in 0..<parameters.count {
            var grad = gradients[i].data
            
            // Weight decay (L2 regularization)
            if weightDecay > 0 {
                for j in 0..<grad.count {
                    grad[j] += weightDecay * parameters[i].data[j]
                }
            }
            
            // Update biased first moment estimate
            for j in 0..<m![i].data.count {
                m![i].data[j] = beta1 * m![i].data[j] + (1 - beta1) * grad[j]
            }
            
            // Update biased second raw moment estimate
            for j in 0..<v![i].data.count {
                v![i].data[j] = beta2 * v![i].data[j] + (1 - beta2) * grad[j] * grad[j]
            }
            
            // Compute bias-corrected estimates
            let mHat = m![i].data.map { $0 / biasCorrection1 }
            var vHat = v![i].data.map { $0 / biasCorrection2 }
            
            // AMSGrad: use max of past squared gradients
            if amsgrad {
                for j in 0..<vHat.count {
                    vMax![i].data[j] = Swift.max(vMax![i].data[j], vHat[j])
                    vHat[j] = vMax![i].data[j]
                }
            }
            
            // Update parameters
            for j in 0..<parameters[i].data.count {
                parameters[i].data[j] -= learningRate * mHat[j] / (sqrt(vHat[j]) + epsilon)
            }
        }
    }
    
    public func reset() {
        m = nil
        v = nil
        vMax = nil
        t = 0
    }
}

// MARK: - AdamW Optimizer
public final class AdamW: Optimizer, @unchecked Sendable {
    public let name = "AdamW"
    public var learningRate: Float
    public let beta1: Float
    public let beta2: Float
    public let epsilon: Float
    public let weightDecay: Float
    
    private var m: [Tensor<Float>]?
    private var v: [Tensor<Float>]?
    private var t: Int = 0
    
    public init(
        learningRate: Float = 0.001,
        beta1: Float = 0.9,
        beta2: Float = 0.999,
        epsilon: Float = 1e-8,
        weightDecay: Float = 0.01
    ) {
        self.learningRate = learningRate
        self.beta1 = beta1
        self.beta2 = beta2
        self.epsilon = epsilon
        self.weightDecay = weightDecay
    }
    
    public func step(parameters: inout [Tensor<Float>], gradients: [Tensor<Float>]) {
        precondition(parameters.count == gradients.count)
        
        if m == nil {
            m = parameters.map { Tensor.zeros($0.shape) }
            v = parameters.map { Tensor.zeros($0.shape) }
        }
        
        t += 1
        let biasCorrection1 = 1 - pow(beta1, Float(t))
        let biasCorrection2 = 1 - pow(beta2, Float(t))
        
        for i in 0..<parameters.count {
            let grad = gradients[i].data
            
            // Decoupled weight decay
            for j in 0..<parameters[i].data.count {
                parameters[i].data[j] *= (1 - learningRate * weightDecay)
            }
            
            // Update moments
            for j in 0..<m![i].data.count {
                m![i].data[j] = beta1 * m![i].data[j] + (1 - beta1) * grad[j]
                v![i].data[j] = beta2 * v![i].data[j] + (1 - beta2) * grad[j] * grad[j]
            }
            
            // Bias correction and update
            for j in 0..<parameters[i].data.count {
                let mHat = m![i].data[j] / biasCorrection1
                let vHat = v![i].data[j] / biasCorrection2
                parameters[i].data[j] -= learningRate * mHat / (sqrt(vHat) + epsilon)
            }
        }
    }
    
    public func reset() {
        m = nil
        v = nil
        t = 0
    }
}

// MARK: - RMSprop Optimizer
public final class RMSprop: Optimizer, @unchecked Sendable {
    public let name = "RMSprop"
    public var learningRate: Float
    public let alpha: Float
    public let epsilon: Float
    public let momentum: Float
    public let centered: Bool
    
    private var v: [Tensor<Float>]?
    private var g: [Tensor<Float>]?  // For centered version
    private var buffer: [Tensor<Float>]?  // For momentum
    
    public init(
        learningRate: Float = 0.01,
        alpha: Float = 0.99,
        epsilon: Float = 1e-8,
        momentum: Float = 0.0,
        centered: Bool = false
    ) {
        self.learningRate = learningRate
        self.alpha = alpha
        self.epsilon = epsilon
        self.momentum = momentum
        self.centered = centered
    }
    
    public func step(parameters: inout [Tensor<Float>], gradients: [Tensor<Float>]) {
        precondition(parameters.count == gradients.count)
        
        if v == nil {
            v = parameters.map { Tensor.zeros($0.shape) }
            if centered {
                g = parameters.map { Tensor.zeros($0.shape) }
            }
            if momentum > 0 {
                buffer = parameters.map { Tensor.zeros($0.shape) }
            }
        }
        
        for i in 0..<parameters.count {
            let grad = gradients[i].data
            
            // Update running average of squared gradients
            for j in 0..<v![i].data.count {
                v![i].data[j] = alpha * v![i].data[j] + (1 - alpha) * grad[j] * grad[j]
            }
            
            var avg = v![i].data
            
            if centered {
                // Update running average of gradients
                for j in 0..<g![i].data.count {
                    g![i].data[j] = alpha * g![i].data[j] + (1 - alpha) * grad[j]
                }
                // Centered: avg = v - g^2
                for j in 0..<avg.count {
                    avg[j] -= g![i].data[j] * g![i].data[j]
                }
            }
            
            if momentum > 0 {
                for j in 0..<buffer![i].data.count {
                    buffer![i].data[j] = momentum * buffer![i].data[j] + grad[j] / (sqrt(avg[j]) + epsilon)
                    parameters[i].data[j] -= learningRate * buffer![i].data[j]
                }
            } else {
                for j in 0..<parameters[i].data.count {
                    parameters[i].data[j] -= learningRate * grad[j] / (sqrt(avg[j]) + epsilon)
                }
            }
        }
    }
    
    public func reset() {
        v = nil
        g = nil
        buffer = nil
    }
}

// MARK: - Adagrad Optimizer
public final class Adagrad: Optimizer, @unchecked Sendable {
    public let name = "Adagrad"
    public var learningRate: Float
    public let epsilon: Float
    public let weightDecay: Float
    
    private var sumSq: [Tensor<Float>]?
    
    public init(
        learningRate: Float = 0.01,
        epsilon: Float = 1e-10,
        weightDecay: Float = 0.0
    ) {
        self.learningRate = learningRate
        self.epsilon = epsilon
        self.weightDecay = weightDecay
    }
    
    public func step(parameters: inout [Tensor<Float>], gradients: [Tensor<Float>]) {
        precondition(parameters.count == gradients.count)
        
        if sumSq == nil {
            sumSq = parameters.map { Tensor.zeros($0.shape) }
        }
        
        for i in 0..<parameters.count {
            var grad = gradients[i].data
            
            // Weight decay
            if weightDecay > 0 {
                for j in 0..<grad.count {
                    grad[j] += weightDecay * parameters[i].data[j]
                }
            }
            
            // Accumulate squared gradients
            for j in 0..<sumSq![i].data.count {
                sumSq![i].data[j] += grad[j] * grad[j]
            }
            
            // Update parameters
            for j in 0..<parameters[i].data.count {
                parameters[i].data[j] -= learningRate * grad[j] / (sqrt(sumSq![i].data[j]) + epsilon)
            }
        }
    }
    
    public func reset() {
        sumSq = nil
    }
}

// MARK: - Learning Rate Scheduler Protocol
public protocol LRScheduler: Sendable {
    func getRate(epoch: Int, baseLR: Float) -> Float
}

// MARK: - Step Decay Scheduler
public struct StepLRScheduler: LRScheduler {
    public let stepSize: Int
    public let gamma: Float
    
    public init(stepSize: Int, gamma: Float = 0.1) {
        self.stepSize = stepSize
        self.gamma = gamma
    }
    
    public func getRate(epoch: Int, baseLR: Float) -> Float {
        baseLR * pow(gamma, Float(epoch / stepSize))
    }
}

// MARK: - Exponential Decay Scheduler
public struct ExponentialLRScheduler: LRScheduler {
    public let gamma: Float
    
    public init(gamma: Float) {
        self.gamma = gamma
    }
    
    public func getRate(epoch: Int, baseLR: Float) -> Float {
        baseLR * pow(gamma, Float(epoch))
    }
}

// MARK: - Cosine Annealing Scheduler
public struct CosineAnnealingLRScheduler: LRScheduler {
    public let maxEpochs: Int
    public let minLR: Float
    
    public init(maxEpochs: Int, minLR: Float = 0.0) {
        self.maxEpochs = maxEpochs
        self.minLR = minLR
    }
    
    public func getRate(epoch: Int, baseLR: Float) -> Float {
        minLR + (baseLR - minLR) * (1 + cos(Float.pi * Float(epoch) / Float(maxEpochs))) / 2
    }
}

// MARK: - Warmup Scheduler
public struct WarmupLRScheduler: LRScheduler {
    public let warmupEpochs: Int
    public let baseScheduler: LRScheduler?
    
    public init(warmupEpochs: Int, baseScheduler: LRScheduler? = nil) {
        self.warmupEpochs = warmupEpochs
        self.baseScheduler = baseScheduler
    }
    
    public func getRate(epoch: Int, baseLR: Float) -> Float {
        if epoch < warmupEpochs {
            return baseLR * Float(epoch + 1) / Float(warmupEpochs)
        }
        if let scheduler = baseScheduler {
            return scheduler.getRate(epoch: epoch - warmupEpochs, baseLR: baseLR)
        }
        return baseLR
    }
}
