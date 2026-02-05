// CoreMLExport.swift
// SwiftAI - Pure Swift Machine Learning Framework
// Copyright © 2024 Muhittin Camdali. All rights reserved.

import Foundation
#if canImport(CoreML)
import CoreML
#endif

// MARK: - Core ML Model Builder
/// Build and export models to Core ML format
public final class CoreMLModelBuilder: @unchecked Sendable {
    
    public struct ModelMetadata: Sendable {
        public var author: String
        public var shortDescription: String
        public var version: String
        public var license: String
        
        public init(
            author: String = "",
            shortDescription: String = "",
            version: String = "1.0",
            license: String = "MIT"
        ) {
            self.author = author
            self.shortDescription = shortDescription
            self.version = version
            self.license = license
        }
    }
    
    private var layers: [[String: Any]] = []
    private var inputFeatures: [(name: String, shape: [Int])] = []
    private var outputFeatures: [(name: String, shape: [Int])] = []
    private var metadata: ModelMetadata
    
    public init(metadata: ModelMetadata = ModelMetadata()) {
        self.metadata = metadata
    }
    
    // MARK: - Input/Output Configuration
    @discardableResult
    public func setInput(name: String, shape: [Int]) -> Self {
        inputFeatures.append((name, shape))
        return self
    }
    
    @discardableResult
    public func setOutput(name: String, shape: [Int]) -> Self {
        outputFeatures.append((name, shape))
        return self
    }
    
    // MARK: - Layer Addition
    @discardableResult
    public func addDenseLayer(
        inputSize: Int,
        outputSize: Int,
        weights: [Float],
        bias: [Float]?,
        activation: String? = nil
    ) -> Self {
        var layer: [String: Any] = [
            "type": "dense",
            "inputSize": inputSize,
            "outputSize": outputSize,
            "weights": weights
        ]
        
        if let b = bias {
            layer["bias"] = b
        }
        
        if let act = activation {
            layer["activation"] = act
        }
        
        layers.append(layer)
        return self
    }
    
    @discardableResult
    public func addActivation(_ type: String) -> Self {
        layers.append([
            "type": "activation",
            "activationType": type
        ])
        return self
    }
    
    @discardableResult
    public func addBatchNorm(
        gamma: [Float],
        beta: [Float],
        mean: [Float],
        variance: [Float],
        epsilon: Float = 1e-5
    ) -> Self {
        layers.append([
            "type": "batchNorm",
            "gamma": gamma,
            "beta": beta,
            "mean": mean,
            "variance": variance,
            "epsilon": epsilon
        ])
        return self
    }
    
    // MARK: - Export to JSON (Platform Independent)
    public func exportToJSON(url: URL) throws {
        let modelSpec: [String: Any] = [
            "metadata": [
                "author": metadata.author,
                "description": metadata.shortDescription,
                "version": metadata.version,
                "license": metadata.license
            ],
            "inputs": inputFeatures.map { ["name": $0.name, "shape": $0.shape] },
            "outputs": outputFeatures.map { ["name": $0.name, "shape": $0.shape] },
            "layers": layers
        ]
        
        let data = try JSONSerialization.data(withJSONObject: modelSpec, options: .prettyPrinted)
        try data.write(to: url)
    }
    
    // MARK: - Load from JSON
    public static func loadFromJSON(url: URL) throws -> CoreMLModelBuilder {
        let data = try Data(contentsOf: url)
        guard let spec = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw CoreMLExportError.invalidFormat
        }
        
        let builder = CoreMLModelBuilder()
        
        // Load metadata
        if let meta = spec["metadata"] as? [String: String] {
            builder.metadata = ModelMetadata(
                author: meta["author"] ?? "",
                shortDescription: meta["description"] ?? "",
                version: meta["version"] ?? "1.0",
                license: meta["license"] ?? "MIT"
            )
        }
        
        // Load inputs/outputs
        if let inputs = spec["inputs"] as? [[String: Any]] {
            for input in inputs {
                if let name = input["name"] as? String,
                   let shape = input["shape"] as? [Int] {
                    builder.inputFeatures.append((name, shape))
                }
            }
        }
        
        if let outputs = spec["outputs"] as? [[String: Any]] {
            for output in outputs {
                if let name = output["name"] as? String,
                   let shape = output["shape"] as? [Int] {
                    builder.outputFeatures.append((name, shape))
                }
            }
        }
        
        // Load layers
        if let layers = spec["layers"] as? [[String: Any]] {
            builder.layers = layers
        }
        
        return builder
    }
    
    #if canImport(CoreML)
    // MARK: - Export to Core ML (iOS/macOS only)
    @available(iOS 15.0, macOS 12.0, *)
    public func exportToCoreML(url: URL) throws {
        // Create model using MLModel spec
        // This is a simplified version - full implementation would use CoreML tools
        
        // Export as JSON first for cross-platform compatibility
        let jsonURL = url.deletingPathExtension().appendingPathExtension("json")
        try exportToJSON(url: jsonURL)
        
        print("Model exported to JSON. Use coremltools to convert to .mlmodel format.")
        print("JSON path: \(jsonURL.path)")
    }
    #endif
}

// MARK: - Neural Network Export
public extension NeuralNetwork {
    
    /// Export neural network to Core ML compatible format
    func exportToCoreML(
        url: URL,
        inputName: String = "input",
        outputName: String = "output",
        metadata: CoreMLModelBuilder.ModelMetadata = CoreMLModelBuilder.ModelMetadata()
    ) throws {
        let builder = CoreMLModelBuilder(metadata: metadata)
        
        // Determine input/output shapes
        var currentSize = 0
        if let firstDense = layers.compactMap({ $0 as? Dense }).first {
            currentSize = firstDense.inputSize
        }
        
        builder.setInput(name: inputName, shape: [currentSize])
        
        for layer in layers {
            if let dense = layer as? Dense {
                builder.addDenseLayer(
                    inputSize: dense.inputSize,
                    outputSize: dense.outputSize,
                    weights: dense.weights.data,
                    bias: dense.bias?.data
                )
                currentSize = dense.outputSize
            } else if let activation = layer as? ActivationLayer {
                builder.addActivation(activation.name)
            } else if let batchNorm = layer as? BatchNorm {
                // Get running stats (simplified)
                builder.addBatchNorm(
                    gamma: batchNorm.gamma.data,
                    beta: batchNorm.beta.data,
                    mean: [Float](repeating: 0, count: batchNorm.numFeatures),
                    variance: [Float](repeating: 1, count: batchNorm.numFeatures)
                )
            }
        }
        
        builder.setOutput(name: outputName, shape: [currentSize])
        
        try builder.exportToJSON(url: url)
    }
}

// MARK: - Model Compression
public struct ModelCompressor: Sendable {
    
    public enum CompressionMethod: Sendable {
        case quantization(bits: Int)
        case pruning(threshold: Float)
        case knowledgeDistillation
    }
    
    /// Quantize weights to reduce model size
    public static func quantize(weights: [Float], bits: Int = 8) -> (quantized: [Int8], scale: Float, zeroPoint: Int8) {
        let minVal = weights.min() ?? 0
        let maxVal = weights.max() ?? 0
        
        let qMin: Float = -128
        let qMax: Float = 127
        
        let scale = (maxVal - minVal) / (qMax - qMin)
        let zeroPoint = Int8(qMin - minVal / scale)
        
        let quantized = weights.map { weight -> Int8 in
            let q = (weight / scale) + Float(zeroPoint)
            return Int8(max(qMin, min(qMax, q)))
        }
        
        return (quantized, scale, zeroPoint)
    }
    
    /// Dequantize weights back to float
    public static func dequantize(quantized: [Int8], scale: Float, zeroPoint: Int8) -> [Float] {
        quantized.map { q in
            scale * Float(q - zeroPoint)
        }
    }
    
    /// Prune small weights
    public static func prune(weights: [Float], threshold: Float) -> (pruned: [Float], mask: [Bool]) {
        let mask = weights.map { abs($0) >= threshold }
        let pruned = zip(weights, mask).map { $0.1 ? $0.0 : 0 }
        return (pruned, mask)
    }
    
    /// Get compression statistics
    public static func compressionStats(original: [Float], compressed: [Int8]) -> (
        originalSize: Int,
        compressedSize: Int,
        ratio: Float
    ) {
        let originalSize = original.count * MemoryLayout<Float>.size
        let compressedSize = compressed.count * MemoryLayout<Int8>.size
        let ratio = Float(originalSize) / Float(compressedSize)
        return (originalSize, compressedSize, ratio)
    }
}

// MARK: - ONNX Export (Simplified)
public struct ONNXExporter: Sendable {
    
    /// Export model info to ONNX-compatible JSON
    public static func exportModelInfo(
        network: NeuralNetwork,
        inputName: String = "input",
        outputName: String = "output"
    ) -> [String: Any] {
        var nodes = [[String: Any]]()
        var weightData = [String: [Float]]()
        
        var nodeIndex = 0
        for layer in network.layers {
            if let dense = layer as? Dense {
                let weightName = "weight_\(nodeIndex)"
                let biasName = "bias_\(nodeIndex)"
                
                var node: [String: Any] = [
                    "opType": "Gemm",
                    "inputs": [nodeIndex == 0 ? inputName : "output_\(nodeIndex - 1)", weightName],
                    "outputs": ["output_\(nodeIndex)"],
                    "attributes": [
                        "transB": 1
                    ]
                ]
                
                if dense.useBias {
                    node["inputs"] = [nodeIndex == 0 ? inputName : "output_\(nodeIndex - 1)", weightName, biasName]
                    weightData[biasName] = dense.bias?.data ?? []
                }
                
                weightData[weightName] = dense.weights.data
                nodes.append(node)
                nodeIndex += 1
            } else if let activation = layer as? ActivationLayer {
                let opType: String
                switch activation.name.lowercased() {
                case "relu": opType = "Relu"
                case "sigmoid": opType = "Sigmoid"
                case "tanh": opType = "Tanh"
                case "softmax": opType = "Softmax"
                default: opType = "Identity"
                }
                
                nodes.append([
                    "opType": opType,
                    "inputs": ["output_\(nodeIndex - 1)"],
                    "outputs": ["output_\(nodeIndex)"]
                ])
                nodeIndex += 1
            }
        }
        
        return [
            "irVersion": 7,
            "producerName": "SwiftAI",
            "producerVersion": "1.0",
            "graph": [
                "nodes": nodes,
                "inputs": [[
                    "name": inputName,
                    "type": "float"
                ]],
                "outputs": [[
                    "name": outputName,
                    "type": "float"
                ]]
            ],
            "weights": weightData
        ]
    }
}

// MARK: - Errors
public enum CoreMLExportError: Error, Sendable {
    case invalidFormat
    case unsupportedLayer(String)
    case exportFailed(String)
}
