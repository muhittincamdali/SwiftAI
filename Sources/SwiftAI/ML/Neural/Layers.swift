// Layers.swift
// SwiftAI - Pure Swift Machine Learning Framework
// Copyright © 2024 Muhittin Camdali. All rights reserved.

import Foundation
import Accelerate

// MARK: - Layer Protocol
public protocol Layer: AnyObject, Sendable {
    var parameters: [Tensor<Float>] { get }
    var gradients: [Tensor<Float>] { get }
    var isTraining: Bool { get set }
    
    func forward(_ input: Tensor<Float>) -> Tensor<Float>
    func backward(_ gradient: Tensor<Float>) -> Tensor<Float>
    
    var name: String { get }
    var inputShape: [Int]? { get }
    var outputShape: [Int]? { get }
}

// MARK: - Dense (Fully Connected) Layer
public final class Dense: Layer, @unchecked Sendable {
    public let name: String
    public var inputShape: [Int]? { [inputSize] }
    public var outputShape: [Int]? { [outputSize] }
    
    public let inputSize: Int
    public let outputSize: Int
    public let useBias: Bool
    
    public var weights: Tensor<Float>
    public var bias: Tensor<Float>?
    
    public var parameters: [Tensor<Float>] {
        if let b = bias {
            return [weights, b]
        }
        return [weights]
    }
    
    public var gradients: [Tensor<Float>] {
        if let bg = biasGrad {
            return [weightsGrad, bg]
        }
        return [weightsGrad]
    }
    
    private var weightsGrad: Tensor<Float>
    private var biasGrad: Tensor<Float>?
    private var lastInput: Tensor<Float>?
    
    public var isTraining: Bool = true
    
    public init(inputSize: Int, outputSize: Int, useBias: Bool = true, name: String = "Dense") {
        self.inputSize = inputSize
        self.outputSize = outputSize
        self.useBias = useBias
        self.name = name
        
        // Xavier/Glorot initialization
        let stddev = sqrt(2.0 / Float(inputSize + outputSize))
        self.weights = Tensor.randn([inputSize, outputSize], mean: 0, std: stddev)
        self.weightsGrad = Tensor.zeros([inputSize, outputSize])
        
        if useBias {
            self.bias = Tensor.zeros([outputSize])
            self.biasGrad = Tensor.zeros([outputSize])
        }
    }
    
    public func forward(_ input: Tensor<Float>) -> Tensor<Float> {
        lastInput = input
        
        let batchSize = input.rank == 1 ? 1 : input.shape[0]
        let reshapedInput: Tensor<Float>
        
        if input.rank == 1 {
            reshapedInput = input.reshape([1, inputSize])
        } else {
            reshapedInput = input
        }
        
        // output = input @ weights
        var output = reshapedInput.matmul(weights)
        
        // Add bias
        if let b = bias {
            for i in 0..<batchSize {
                for j in 0..<outputSize {
                    output.data[i * outputSize + j] += b.data[j]
                }
            }
        }
        
        return input.rank == 1 ? output.reshape([outputSize]) : output
    }
    
    public func backward(_ gradient: Tensor<Float>) -> Tensor<Float> {
        guard let input = lastInput else {
            fatalError("Forward must be called before backward")
        }
        
        let batchSize = input.rank == 1 ? 1 : input.shape[0]
        let reshapedInput = input.rank == 1 ? input.reshape([1, inputSize]) : input
        let reshapedGrad = gradient.rank == 1 ? gradient.reshape([1, outputSize]) : gradient
        
        // weightsGrad = input.T @ gradient
        weightsGrad = reshapedInput.T.matmul(reshapedGrad)
        
        // biasGrad = sum(gradient, axis=0)
        if useBias {
            var bg = [Float](repeating: 0, count: outputSize)
            for i in 0..<batchSize {
                for j in 0..<outputSize {
                    bg[j] += reshapedGrad.data[i * outputSize + j]
                }
            }
            biasGrad = Tensor(shape: [outputSize], data: bg)
        }
        
        // inputGrad = gradient @ weights.T
        let inputGrad = reshapedGrad.matmul(weights.T)
        
        return input.rank == 1 ? inputGrad.reshape([inputSize]) : inputGrad
    }
}

// MARK: - Activation Layer
public final class ActivationLayer: Layer, @unchecked Sendable {
    public let name: String
    public var inputShape: [Int]?
    public var outputShape: [Int]? { inputShape }
    
    public let activation: any Activation
    
    public var parameters: [Tensor<Float>] { [] }
    public var gradients: [Tensor<Float>] { [] }
    
    private var lastInput: Tensor<Float>?
    public var isTraining: Bool = true
    
    public init(activation: any Activation, name: String? = nil) {
        self.activation = activation
        self.name = name ?? activation.name
    }
    
    public func forward(_ input: Tensor<Float>) -> Tensor<Float> {
        lastInput = input
        inputShape = input.shape
        return activation.forward(input)
    }
    
    public func backward(_ gradient: Tensor<Float>) -> Tensor<Float> {
        guard let input = lastInput else {
            fatalError("Forward must be called before backward")
        }
        return activation.backward(input, gradient: gradient)
    }
}

// MARK: - Dropout Layer
public final class Dropout: Layer, @unchecked Sendable {
    public let name: String
    public var inputShape: [Int]?
    public var outputShape: [Int]? { inputShape }
    
    public let rate: Float
    
    public var parameters: [Tensor<Float>] { [] }
    public var gradients: [Tensor<Float>] { [] }
    
    private var mask: Tensor<Float>?
    public var isTraining: Bool = true
    
    public init(rate: Float = 0.5, name: String = "Dropout") {
        precondition(rate >= 0 && rate < 1, "Dropout rate must be in [0, 1)")
        self.rate = rate
        self.name = name
    }
    
    public func forward(_ input: Tensor<Float>) -> Tensor<Float> {
        inputShape = input.shape
        
        guard isTraining else {
            return input.copy()
        }
        
        // Generate mask
        let maskData = (0..<input.count).map { _ -> Float in
            Float.random(in: 0...1) >= rate ? 1.0 / (1.0 - rate) : 0.0
        }
        mask = Tensor(shape: input.shape, data: maskData)
        
        // Apply mask
        return input * mask!
    }
    
    public func backward(_ gradient: Tensor<Float>) -> Tensor<Float> {
        guard isTraining, let m = mask else {
            return gradient.copy()
        }
        return gradient * m
    }
}

// MARK: - Batch Normalization Layer
public final class BatchNorm: Layer, @unchecked Sendable {
    public let name: String
    public var inputShape: [Int]?
    public var outputShape: [Int]? { inputShape }
    
    public let numFeatures: Int
    public let epsilon: Float
    public let momentum: Float
    
    public var gamma: Tensor<Float>  // Scale
    public var beta: Tensor<Float>   // Shift
    
    private var runningMean: Tensor<Float>
    private var runningVar: Tensor<Float>
    
    public var parameters: [Tensor<Float>] { [gamma, beta] }
    public var gradients: [Tensor<Float>] { [gammaGrad, betaGrad] }
    
    private var gammaGrad: Tensor<Float>
    private var betaGrad: Tensor<Float>
    
    private var lastInput: Tensor<Float>?
    private var normalizedInput: Tensor<Float>?
    private var batchMean: Float = 0
    private var batchVar: Float = 0
    
    public var isTraining: Bool = true
    
    public init(numFeatures: Int, epsilon: Float = 1e-5, momentum: Float = 0.1, name: String = "BatchNorm") {
        self.numFeatures = numFeatures
        self.epsilon = epsilon
        self.momentum = momentum
        self.name = name
        
        self.gamma = Tensor.ones([numFeatures])
        self.beta = Tensor.zeros([numFeatures])
        self.gammaGrad = Tensor.zeros([numFeatures])
        self.betaGrad = Tensor.zeros([numFeatures])
        
        self.runningMean = Tensor.zeros([numFeatures])
        self.runningVar = Tensor.ones([numFeatures])
    }
    
    public func forward(_ input: Tensor<Float>) -> Tensor<Float> {
        lastInput = input
        inputShape = input.shape
        
        if isTraining {
            // Compute batch statistics
            batchMean = input.mean()
            batchVar = input.variance()
            
            // Update running statistics
            for i in 0..<numFeatures {
                runningMean.data[i] = (1 - momentum) * runningMean.data[i] + momentum * batchMean
                runningVar.data[i] = (1 - momentum) * runningVar.data[i] + momentum * batchVar
            }
        } else {
            batchMean = runningMean.data[0]
            batchVar = runningVar.data[0]
        }
        
        // Normalize
        let std = sqrt(batchVar + epsilon)
        let normalized = input.data.map { ($0 - batchMean) / std }
        normalizedInput = Tensor(shape: input.shape, data: normalized)
        
        // Scale and shift
        let output = normalized.enumerated().map { i, x in
            gamma.data[i % numFeatures] * x + beta.data[i % numFeatures]
        }
        
        return Tensor(shape: input.shape, data: output)
    }
    
    public func backward(_ gradient: Tensor<Float>) -> Tensor<Float> {
        guard let input = lastInput, let normalized = normalizedInput else {
            fatalError("Forward must be called before backward")
        }
        
        let n = Float(input.count)
        let std = sqrt(batchVar + epsilon)
        
        // Compute gradients for gamma and beta
        for i in 0..<numFeatures {
            gammaGrad.data[i] = 0
            betaGrad.data[i] = 0
        }
        
        for i in 0..<input.count {
            let featureIdx = i % numFeatures
            gammaGrad.data[featureIdx] += gradient.data[i] * normalized.data[i]
            betaGrad.data[featureIdx] += gradient.data[i]
        }
        
        // Compute input gradient
        var inputGrad = [Float](repeating: 0, count: input.count)
        
        let dxNorm = gradient.data.enumerated().map { i, g in
            g * gamma.data[i % numFeatures]
        }
        
        let sumDxNorm = dxNorm.reduce(0, +)
        let sumDxNormXNorm = zip(dxNorm, normalized.data).map { $0 * $1 }.reduce(0, +)
        
        for i in 0..<input.count {
            inputGrad[i] = (dxNorm[i] - sumDxNorm / n - normalized.data[i] * sumDxNormXNorm / n) / std
        }
        
        return Tensor(shape: input.shape, data: inputGrad)
    }
}

// MARK: - Layer Normalization
public final class LayerNorm: Layer, @unchecked Sendable {
    public let name: String
    public var inputShape: [Int]?
    public var outputShape: [Int]? { inputShape }
    
    public let normalizedShape: [Int]
    public let epsilon: Float
    
    public var gamma: Tensor<Float>
    public var beta: Tensor<Float>
    
    public var parameters: [Tensor<Float>] { [gamma, beta] }
    public var gradients: [Tensor<Float>] { [gammaGrad, betaGrad] }
    
    private var gammaGrad: Tensor<Float>
    private var betaGrad: Tensor<Float>
    
    private var lastInput: Tensor<Float>?
    private var normalizedInput: Tensor<Float>?
    private var mean: Float = 0
    private var std: Float = 0
    
    public var isTraining: Bool = true
    
    public init(normalizedShape: [Int], epsilon: Float = 1e-5, name: String = "LayerNorm") {
        self.normalizedShape = normalizedShape
        self.epsilon = epsilon
        self.name = name
        
        let size = normalizedShape.reduce(1, *)
        self.gamma = Tensor.ones([size])
        self.beta = Tensor.zeros([size])
        self.gammaGrad = Tensor.zeros([size])
        self.betaGrad = Tensor.zeros([size])
    }
    
    public func forward(_ input: Tensor<Float>) -> Tensor<Float> {
        lastInput = input
        inputShape = input.shape
        
        mean = input.mean()
        let variance = input.variance()
        std = sqrt(variance + epsilon)
        
        let normalized = input.data.map { ($0 - mean) / std }
        normalizedInput = Tensor(shape: input.shape, data: normalized)
        
        let output = normalized.enumerated().map { i, x in
            gamma.data[i % gamma.count] * x + beta.data[i % beta.count]
        }
        
        return Tensor(shape: input.shape, data: output)
    }
    
    public func backward(_ gradient: Tensor<Float>) -> Tensor<Float> {
        guard let input = lastInput, let normalized = normalizedInput else {
            fatalError("Forward must be called before backward")
        }
        
        let n = Float(input.count)
        
        // Compute gradients for gamma and beta
        for i in 0..<gamma.count {
            gammaGrad.data[i] = 0
            betaGrad.data[i] = 0
        }
        
        for i in 0..<input.count {
            let idx = i % gamma.count
            gammaGrad.data[idx] += gradient.data[i] * normalized.data[i]
            betaGrad.data[idx] += gradient.data[i]
        }
        
        // Compute input gradient
        let dxNorm = gradient.data.enumerated().map { i, g in
            g * gamma.data[i % gamma.count]
        }
        
        let sumDxNorm = dxNorm.reduce(0, +)
        let sumDxNormXNorm = zip(dxNorm, normalized.data).map { $0 * $1 }.reduce(0, +)
        
        var inputGrad = [Float](repeating: 0, count: input.count)
        for i in 0..<input.count {
            inputGrad[i] = (dxNorm[i] - sumDxNorm / n - normalized.data[i] * sumDxNormXNorm / n) / std
        }
        
        return Tensor(shape: input.shape, data: inputGrad)
    }
}

// MARK: - Flatten Layer
public final class Flatten: Layer, @unchecked Sendable {
    public let name: String
    public var inputShape: [Int]?
    public var outputShape: [Int]? {
        guard let shape = inputShape else { return nil }
        return [shape.reduce(1, *)]
    }
    
    public var parameters: [Tensor<Float>] { [] }
    public var gradients: [Tensor<Float>] { [] }
    
    public var isTraining: Bool = true
    
    public init(name: String = "Flatten") {
        self.name = name
    }
    
    public func forward(_ input: Tensor<Float>) -> Tensor<Float> {
        inputShape = input.shape
        return input.flatten()
    }
    
    public func backward(_ gradient: Tensor<Float>) -> Tensor<Float> {
        guard let shape = inputShape else {
            return gradient
        }
        return gradient.reshape(shape)
    }
}

// MARK: - Embedding Layer
public final class Embedding: Layer, @unchecked Sendable {
    public let name: String
    public var inputShape: [Int]? { [1] }
    public var outputShape: [Int]? { [embeddingDim] }
    
    public let numEmbeddings: Int
    public let embeddingDim: Int
    
    public var weights: Tensor<Float>
    
    public var parameters: [Tensor<Float>] { [weights] }
    public var gradients: [Tensor<Float>] { [weightsGrad] }
    
    private var weightsGrad: Tensor<Float>
    private var lastIndices: [Int]?
    
    public var isTraining: Bool = true
    
    public init(numEmbeddings: Int, embeddingDim: Int, name: String = "Embedding") {
        self.numEmbeddings = numEmbeddings
        self.embeddingDim = embeddingDim
        self.name = name
        
        // Initialize with normal distribution
        self.weights = Tensor.randn([numEmbeddings, embeddingDim], mean: 0, std: 0.01)
        self.weightsGrad = Tensor.zeros([numEmbeddings, embeddingDim])
    }
    
    public func forward(_ input: Tensor<Float>) -> Tensor<Float> {
        // Input contains indices as floats
        lastIndices = input.data.map { Int($0) }
        
        var output = [Float]()
        for idx in lastIndices! {
            precondition(idx >= 0 && idx < numEmbeddings, "Index out of bounds")
            let start = idx * embeddingDim
            output.append(contentsOf: weights.data[start..<(start + embeddingDim)])
        }
        
        return Tensor(shape: [lastIndices!.count, embeddingDim], data: output)
    }
    
    public func backward(_ gradient: Tensor<Float>) -> Tensor<Float> {
        guard let indices = lastIndices else {
            fatalError("Forward must be called before backward")
        }
        
        // Zero out gradients
        weightsGrad = Tensor.zeros([numEmbeddings, embeddingDim])
        
        // Accumulate gradients for each index
        for (i, idx) in indices.enumerated() {
            let start = idx * embeddingDim
            let gradStart = i * embeddingDim
            for j in 0..<embeddingDim {
                weightsGrad.data[start + j] += gradient.data[gradStart + j]
            }
        }
        
        // Return dummy gradient (indices don't have gradients)
        return Tensor.zeros([indices.count])
    }
}
