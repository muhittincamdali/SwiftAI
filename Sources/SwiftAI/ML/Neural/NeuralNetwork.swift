// NeuralNetwork.swift
// SwiftAI - Pure Swift Machine Learning Framework
// Copyright © 2024 Muhittin Camdali. All rights reserved.

import Foundation

// MARK: - Neural Network
/// A flexible, modular neural network implementation
public final class NeuralNetwork: @unchecked Sendable {
    
    // MARK: - Properties
    public private(set) var layers: [any Layer]
    public var optimizer: (any Optimizer)?
    public var lossFunction: (any LossFunction)?
    
    private var trainingHistory: TrainingHistory
    
    // MARK: - Initialization
    public init() {
        self.layers = []
        self.trainingHistory = TrainingHistory()
    }
    
    public init(layers: [any Layer]) {
        self.layers = layers
        self.trainingHistory = TrainingHistory()
    }
    
    // MARK: - Model Building
    @discardableResult
    public func add(_ layer: any Layer) -> Self {
        layers.append(layer)
        return self
    }
    
    @discardableResult
    public func dense(_ inputSize: Int, _ outputSize: Int, activation: ActivationType? = nil) -> Self {
        add(Dense(inputSize: inputSize, outputSize: outputSize))
        if let act = activation {
            add(ActivationLayer(activation: act.create()))
        }
        return self
    }
    
    @discardableResult
    public func dropout(_ rate: Float = 0.5) -> Self {
        add(Dropout(rate: rate))
        return self
    }
    
    @discardableResult
    public func batchNorm(_ features: Int) -> Self {
        add(BatchNorm(numFeatures: features))
        return self
    }
    
    // MARK: - Compilation
    public func compile(
        optimizer: any Optimizer,
        loss: any LossFunction
    ) {
        self.optimizer = optimizer
        self.lossFunction = loss
    }
    
    public func compile(
        optimizer: OptimizerType = .adam,
        loss: LossType = .mse,
        learningRate: Float = 0.001
    ) {
        self.optimizer = optimizer.create(learningRate: learningRate)
        self.lossFunction = loss.create()
    }
    
    // MARK: - Forward Pass
    public func forward(_ input: Tensor<Float>, training: Bool = false) -> Tensor<Float> {
        var output = input
        for layer in layers {
            layer.isTraining = training
            output = layer.forward(output)
        }
        return output
    }
    
    public func predict(_ input: Tensor<Float>) -> Tensor<Float> {
        forward(input, training: false)
    }
    
    public func predictBatch(_ inputs: [Tensor<Float>]) -> [Tensor<Float>] {
        inputs.map { predict($0) }
    }
    
    // MARK: - Backward Pass
    public func backward(_ gradient: Tensor<Float>) {
        var grad = gradient
        for layer in layers.reversed() {
            grad = layer.backward(grad)
        }
    }
    
    // MARK: - Training
    public func train(
        x: [[Float]],
        y: [[Float]],
        epochs: Int,
        batchSize: Int = 32,
        validationSplit: Float = 0.0,
        shuffle: Bool = true,
        verbose: Bool = true,
        callbacks: [TrainingCallback] = []
    ) -> TrainingHistory {
        guard let optimizer = optimizer, let loss = lossFunction else {
            fatalError("Model must be compiled before training")
        }
        
        trainingHistory = TrainingHistory()
        
        // Prepare data
        let (trainX, trainY, valX, valY) = splitData(x: x, y: y, validationSplit: validationSplit)
        
        let numSamples = trainX.count
        let numBatches = (numSamples + batchSize - 1) / batchSize
        
        for epoch in 0..<epochs {
            var epochLoss: Float = 0
            var indices = Array(0..<numSamples)
            
            if shuffle {
                indices.shuffle()
            }
            
            // Notify callbacks
            callbacks.forEach { $0.onEpochBegin(epoch: epoch) }
            
            for batch in 0..<numBatches {
                let startIdx = batch * batchSize
                let endIdx = min(startIdx + batchSize, numSamples)
                let batchIndices = Array(indices[startIdx..<endIdx])
                
                var batchLoss: Float = 0
                var allParameters = collectParameters()
                var allGradients = collectZeroGradients()
                
                // Process each sample in batch
                for idx in batchIndices {
                    let inputTensor = Tensor(shape: [trainX[idx].count], data: trainX[idx])
                    let targetTensor = Tensor(shape: [trainY[idx].count], data: trainY[idx])
                    
                    // Forward
                    let output = forward(inputTensor, training: true)
                    
                    // Compute loss
                    let sampleLoss = loss.forward(predictions: output, targets: targetTensor)
                    batchLoss += sampleLoss
                    
                    // Backward
                    let lossGrad = loss.backward(predictions: output, targets: targetTensor)
                    backward(lossGrad)
                    
                    // Accumulate gradients
                    let layerGrads = collectGradients()
                    for i in 0..<allGradients.count {
                        for j in 0..<allGradients[i].count {
                            allGradients[i].data[j] += layerGrads[i].data[j]
                        }
                    }
                }
                
                // Average gradients
                let batchSizeFloat = Float(batchIndices.count)
                for i in 0..<allGradients.count {
                    for j in 0..<allGradients[i].count {
                        allGradients[i].data[j] /= batchSizeFloat
                    }
                }
                
                // Update parameters
                optimizer.step(parameters: &allParameters, gradients: allGradients)
                
                // Copy back parameters
                applyParameters(allParameters)
                
                epochLoss += batchLoss / Float(batchIndices.count)
            }
            
            epochLoss /= Float(numBatches)
            trainingHistory.loss.append(epochLoss)
            
            // Validation
            var valLoss: Float = 0
            if !valX.isEmpty {
                for i in 0..<valX.count {
                    let input = Tensor(shape: [valX[i].count], data: valX[i])
                    let target = Tensor(shape: [valY[i].count], data: valY[i])
                    let output = predict(input)
                    valLoss += loss.forward(predictions: output, targets: target)
                }
                valLoss /= Float(valX.count)
                trainingHistory.valLoss.append(valLoss)
            }
            
            // Notify callbacks
            callbacks.forEach { $0.onEpochEnd(epoch: epoch, loss: epochLoss, valLoss: valLoss) }
            
            if verbose {
                var message = "Epoch \(epoch + 1)/\(epochs) - loss: \(String(format: "%.4f", epochLoss))"
                if !valX.isEmpty {
                    message += " - val_loss: \(String(format: "%.4f", valLoss))"
                }
                print(message)
            }
        }
        
        return trainingHistory
    }
    
    // MARK: - Evaluation
    public func evaluate(x: [[Float]], y: [[Float]]) -> (loss: Float, accuracy: Float) {
        guard let loss = lossFunction else {
            fatalError("Model must be compiled before evaluation")
        }
        
        var totalLoss: Float = 0
        var correct = 0
        
        for i in 0..<x.count {
            let input = Tensor(shape: [x[i].count], data: x[i])
            let target = Tensor(shape: [y[i].count], data: y[i])
            let output = predict(input)
            
            totalLoss += loss.forward(predictions: output, targets: target)
            
            // Accuracy for classification
            if output.count > 1 {
                if output.argmax() == target.argmax() {
                    correct += 1
                }
            } else {
                // Binary classification
                let pred = output.data[0] > 0.5 ? 1 : 0
                let actual = target.data[0] > 0.5 ? 1 : 0
                if pred == actual {
                    correct += 1
                }
            }
        }
        
        return (totalLoss / Float(x.count), Float(correct) / Float(x.count))
    }
    
    // MARK: - Parameter Management
    public func collectParameters() -> [Tensor<Float>] {
        layers.flatMap { $0.parameters }
    }
    
    public func collectGradients() -> [Tensor<Float>] {
        layers.flatMap { $0.gradients }
    }
    
    private func collectZeroGradients() -> [Tensor<Float>] {
        layers.flatMap { layer in
            layer.parameters.map { Tensor<Float>.zeros($0.shape) }
        }
    }
    
    private func applyParameters(_ params: [Tensor<Float>]) {
        var idx = 0
        for layer in layers {
            for param in layer.parameters {
                if idx < params.count {
                    for i in 0..<param.data.count {
                        param.data[i] = params[idx].data[i]
                    }
                }
                idx += 1
            }
        }
    }
    
    // MARK: - Data Helpers
    private func splitData(
        x: [[Float]],
        y: [[Float]],
        validationSplit: Float
    ) -> (trainX: [[Float]], trainY: [[Float]], valX: [[Float]], valY: [[Float]]) {
        guard validationSplit > 0 else {
            return (x, y, [], [])
        }
        
        let splitIdx = Int(Float(x.count) * (1 - validationSplit))
        var indices = Array(0..<x.count)
        indices.shuffle()
        
        let trainIndices = Array(indices[0..<splitIdx])
        let valIndices = Array(indices[splitIdx...])
        
        let trainX = trainIndices.map { x[$0] }
        let trainY = trainIndices.map { y[$0] }
        let valX = valIndices.map { x[$0] }
        let valY = valIndices.map { y[$0] }
        
        return (trainX, trainY, valX, valY)
    }
    
    // MARK: - Model Summary
    public func summary() -> String {
        var output = """
        ═══════════════════════════════════════════════════════════════
        Model Summary
        ═══════════════════════════════════════════════════════════════
        
        """
        
        var totalParams = 0
        
        for (i, layer) in layers.enumerated() {
            let paramCount = layer.parameters.reduce(0) { $0 + $1.count }
            totalParams += paramCount
            
            let inputStr = layer.inputShape?.map(String.init).joined(separator: "×") ?? "?"
            let outputStr = layer.outputShape?.map(String.init).joined(separator: "×") ?? "?"
            
            output += String(format: "%-3d %-20s %-15s %-15s %d\n",
                           i + 1, layer.name, inputStr, outputStr, paramCount)
        }
        
        output += """
        
        ═══════════════════════════════════════════════════════════════
        Total Parameters: \(totalParams)
        ═══════════════════════════════════════════════════════════════
        """
        
        return output
    }
    
    // MARK: - Serialization
    public func save(to url: URL) throws {
        var state: [String: [[Float]]] = [:]
        for (i, layer) in layers.enumerated() {
            for (j, param) in layer.parameters.enumerated() {
                state["layer_\(i)_param_\(j)"] = [param.data]
            }
        }
        let data = try JSONEncoder().encode(state)
        try data.write(to: url)
    }
    
    public func load(from url: URL) throws {
        let data = try Data(contentsOf: url)
        let state = try JSONDecoder().decode([String: [[Float]]].self, from: data)
        
        for (i, layer) in layers.enumerated() {
            for (j, param) in layer.parameters.enumerated() {
                if let savedData = state["layer_\(i)_param_\(j)"]?.first {
                    precondition(savedData.count == param.count, "Parameter size mismatch")
                    for k in 0..<param.count {
                        param.data[k] = savedData[k]
                    }
                }
            }
        }
    }
}

// MARK: - Training History
public struct TrainingHistory: Sendable {
    public var loss: [Float] = []
    public var valLoss: [Float] = []
    public var metrics: [String: [Float]] = [:]
    
    public init() {}
}

// MARK: - Training Callback
public protocol TrainingCallback: Sendable {
    func onEpochBegin(epoch: Int)
    func onEpochEnd(epoch: Int, loss: Float, valLoss: Float)
    func onTrainBegin()
    func onTrainEnd()
}

public extension TrainingCallback {
    func onEpochBegin(epoch: Int) {}
    func onEpochEnd(epoch: Int, loss: Float, valLoss: Float) {}
    func onTrainBegin() {}
    func onTrainEnd() {}
}

// MARK: - Early Stopping Callback
public final class EarlyStopping: TrainingCallback, @unchecked Sendable {
    public let patience: Int
    public let minDelta: Float
    public let monitor: String
    
    private var bestValue: Float = .infinity
    private var counter: Int = 0
    public private(set) var shouldStop: Bool = false
    
    public init(patience: Int = 5, minDelta: Float = 0.0001, monitor: String = "val_loss") {
        self.patience = patience
        self.minDelta = minDelta
        self.monitor = monitor
    }
    
    public func onEpochEnd(epoch: Int, loss: Float, valLoss: Float) {
        let current = monitor == "val_loss" ? valLoss : loss
        
        if current < bestValue - minDelta {
            bestValue = current
            counter = 0
        } else {
            counter += 1
            if counter >= patience {
                shouldStop = true
                print("Early stopping triggered at epoch \(epoch + 1)")
            }
        }
    }
}

// MARK: - Optimizer Factory
public enum OptimizerType: String, CaseIterable, Sendable {
    case sgd
    case adam
    case adamw
    case rmsprop
    case adagrad
    
    public func create(learningRate: Float = 0.001) -> any Optimizer {
        switch self {
        case .sgd: return SGD(learningRate: learningRate)
        case .adam: return Adam(learningRate: learningRate)
        case .adamw: return AdamW(learningRate: learningRate)
        case .rmsprop: return RMSprop(learningRate: learningRate)
        case .adagrad: return Adagrad(learningRate: learningRate)
        }
    }
}
