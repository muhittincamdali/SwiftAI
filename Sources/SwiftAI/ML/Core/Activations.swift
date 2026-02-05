// Activations.swift
// SwiftAI - Pure Swift Machine Learning Framework
// Copyright © 2024 Muhittin Camdali. All rights reserved.

import Foundation
import Accelerate

// MARK: - Activation Function Protocol
public protocol Activation: Sendable {
    func forward(_ x: Tensor<Float>) -> Tensor<Float>
    func backward(_ x: Tensor<Float>, gradient: Tensor<Float>) -> Tensor<Float>
    var name: String { get }
}

// MARK: - ReLU (Rectified Linear Unit)
public struct ReLU: Activation {
    public let name = "ReLU"
    
    public init() {}
    
    public func forward(_ x: Tensor<Float>) -> Tensor<Float> {
        var result = [Float](repeating: 0, count: x.count)
        var zero: Float = 0
        var maxVal = Float.greatestFiniteMagnitude
        vDSP_vclip(x.data, 1, &zero, &maxVal, &result, 1, vDSP_Length(x.count))
        return Tensor(shape: x.shape, data: result)
    }
    
    public func backward(_ x: Tensor<Float>, gradient: Tensor<Float>) -> Tensor<Float> {
        let mask = x.data.map { $0 > 0 ? Float(1) : Float(0) }
        var result = [Float](repeating: 0, count: x.count)
        vDSP_vmul(gradient.data, 1, mask, 1, &result, 1, vDSP_Length(x.count))
        return Tensor(shape: x.shape, data: result)
    }
}

// MARK: - Leaky ReLU
public struct LeakyReLU: Activation {
    public let name = "LeakyReLU"
    public let alpha: Float
    
    public init(alpha: Float = 0.01) {
        self.alpha = alpha
    }
    
    public func forward(_ x: Tensor<Float>) -> Tensor<Float> {
        let result = x.data.map { $0 > 0 ? $0 : alpha * $0 }
        return Tensor(shape: x.shape, data: result)
    }
    
    public func backward(_ x: Tensor<Float>, gradient: Tensor<Float>) -> Tensor<Float> {
        let mask = x.data.map { $0 > 0 ? Float(1) : alpha }
        var result = [Float](repeating: 0, count: x.count)
        vDSP_vmul(gradient.data, 1, mask, 1, &result, 1, vDSP_Length(x.count))
        return Tensor(shape: x.shape, data: result)
    }
}

// MARK: - ELU (Exponential Linear Unit)
public struct ELU: Activation {
    public let name = "ELU"
    public let alpha: Float
    
    public init(alpha: Float = 1.0) {
        self.alpha = alpha
    }
    
    public func forward(_ x: Tensor<Float>) -> Tensor<Float> {
        let result = x.data.map { $0 > 0 ? $0 : alpha * (exp($0) - 1) }
        return Tensor(shape: x.shape, data: result)
    }
    
    public func backward(_ x: Tensor<Float>, gradient: Tensor<Float>) -> Tensor<Float> {
        let mask = x.data.map { $0 > 0 ? Float(1) : alpha * exp($0) }
        var result = [Float](repeating: 0, count: x.count)
        vDSP_vmul(gradient.data, 1, mask, 1, &result, 1, vDSP_Length(x.count))
        return Tensor(shape: x.shape, data: result)
    }
}

// MARK: - SELU (Scaled ELU)
public struct SELU: Activation {
    public let name = "SELU"
    private let lambda: Float = 1.0507
    private let alpha: Float = 1.6733
    
    public init() {}
    
    public func forward(_ x: Tensor<Float>) -> Tensor<Float> {
        let result = x.data.map { lambda * ($0 > 0 ? $0 : alpha * (exp($0) - 1)) }
        return Tensor(shape: x.shape, data: result)
    }
    
    public func backward(_ x: Tensor<Float>, gradient: Tensor<Float>) -> Tensor<Float> {
        let mask = x.data.map { lambda * ($0 > 0 ? Float(1) : alpha * exp($0)) }
        var result = [Float](repeating: 0, count: x.count)
        vDSP_vmul(gradient.data, 1, mask, 1, &result, 1, vDSP_Length(x.count))
        return Tensor(shape: x.shape, data: result)
    }
}

// MARK: - Sigmoid
public struct Sigmoid: Activation {
    public let name = "Sigmoid"
    
    public init() {}
    
    public func forward(_ x: Tensor<Float>) -> Tensor<Float> {
        let result = x.data.map { 1.0 / (1.0 + exp(-$0)) }
        return Tensor(shape: x.shape, data: result)
    }
    
    public func backward(_ x: Tensor<Float>, gradient: Tensor<Float>) -> Tensor<Float> {
        let s = forward(x)
        let derivative = s.data.enumerated().map { (i, val) in val * (1 - val) }
        var result = [Float](repeating: 0, count: x.count)
        vDSP_vmul(gradient.data, 1, derivative, 1, &result, 1, vDSP_Length(x.count))
        return Tensor(shape: x.shape, data: result)
    }
}

// MARK: - Tanh
public struct Tanh: Activation {
    public let name = "Tanh"
    
    public init() {}
    
    public func forward(_ x: Tensor<Float>) -> Tensor<Float> {
        var result = [Float](repeating: 0, count: x.count)
        var n = Int32(x.count)
        vvtanhf(&result, x.data, &n)
        return Tensor(shape: x.shape, data: result)
    }
    
    public func backward(_ x: Tensor<Float>, gradient: Tensor<Float>) -> Tensor<Float> {
        let t = forward(x)
        let derivative = t.data.map { 1 - $0 * $0 }
        var result = [Float](repeating: 0, count: x.count)
        vDSP_vmul(gradient.data, 1, derivative, 1, &result, 1, vDSP_Length(x.count))
        return Tensor(shape: x.shape, data: result)
    }
}

// MARK: - Softmax
public struct Softmax: Activation {
    public let name = "Softmax"
    public let axis: Int
    
    public init(axis: Int = -1) {
        self.axis = axis
    }
    
    public func forward(_ x: Tensor<Float>) -> Tensor<Float> {
        // For numerical stability: softmax(x) = softmax(x - max(x))
        let maxVal = x.max()
        let shifted = x.data.map { $0 - maxVal }
        let exps = shifted.map { exp($0) }
        let sum = exps.reduce(0, +)
        let result = exps.map { $0 / sum }
        return Tensor(shape: x.shape, data: result)
    }
    
    public func backward(_ x: Tensor<Float>, gradient: Tensor<Float>) -> Tensor<Float> {
        let s = forward(x)
        // Jacobian: diag(s) - s * s^T
        // For simplicity in 1D case: grad * s * (1 - s) for each element contribution
        var result = [Float](repeating: 0, count: x.count)
        for i in 0..<x.count {
            var sum: Float = 0
            for j in 0..<x.count {
                let jacobian = i == j ? s.data[i] * (1 - s.data[j]) : -s.data[i] * s.data[j]
                sum += gradient.data[j] * jacobian
            }
            result[i] = sum
        }
        return Tensor(shape: x.shape, data: result)
    }
}

// MARK: - Swish (SiLU)
public struct Swish: Activation {
    public let name = "Swish"
    
    public init() {}
    
    public func forward(_ x: Tensor<Float>) -> Tensor<Float> {
        // swish(x) = x * sigmoid(x)
        let sigmoid = x.data.map { 1.0 / (1.0 + exp(-$0)) }
        var result = [Float](repeating: 0, count: x.count)
        vDSP_vmul(x.data, 1, sigmoid, 1, &result, 1, vDSP_Length(x.count))
        return Tensor(shape: x.shape, data: result)
    }
    
    public func backward(_ x: Tensor<Float>, gradient: Tensor<Float>) -> Tensor<Float> {
        let s = x.data.map { 1.0 / (1.0 + exp(-$0)) }
        // swish'(x) = swish(x) + sigmoid(x) * (1 - swish(x))
        let swish = zip(x.data, s).map { $0 * $1 }
        let derivative = zip(swish, s).map { sw, sig in sw + sig * (1 - sw) }
        var result = [Float](repeating: 0, count: x.count)
        vDSP_vmul(gradient.data, 1, derivative, 1, &result, 1, vDSP_Length(x.count))
        return Tensor(shape: x.shape, data: result)
    }
}

// MARK: - GELU (Gaussian Error Linear Unit)
public struct GELU: Activation {
    public let name = "GELU"
    
    public init() {}
    
    public func forward(_ x: Tensor<Float>) -> Tensor<Float> {
        // GELU(x) = 0.5 * x * (1 + tanh(sqrt(2/π) * (x + 0.044715 * x^3)))
        let sqrt2pi: Float = 0.7978845608 // sqrt(2/π)
        let result = x.data.map { val in
            let inner = sqrt2pi * (val + 0.044715 * val * val * val)
            return 0.5 * val * (1 + tanh(inner))
        }
        return Tensor(shape: x.shape, data: result)
    }
    
    public func backward(_ x: Tensor<Float>, gradient: Tensor<Float>) -> Tensor<Float> {
        let sqrt2pi: Float = 0.7978845608
        let derivative = x.data.map { val -> Float in
            let x3 = val * val * val
            let inner = sqrt2pi * (val + 0.044715 * x3)
            let tanhVal = tanh(inner)
            let sech2 = 1 - tanhVal * tanhVal
            let innerDerivative = sqrt2pi * (1 + 3 * 0.044715 * val * val)
            return 0.5 * (1 + tanhVal) + 0.5 * val * sech2 * innerDerivative
        }
        var result = [Float](repeating: 0, count: x.count)
        vDSP_vmul(gradient.data, 1, derivative, 1, &result, 1, vDSP_Length(x.count))
        return Tensor(shape: x.shape, data: result)
    }
}

// MARK: - Softplus
public struct Softplus: Activation {
    public let name = "Softplus"
    
    public init() {}
    
    public func forward(_ x: Tensor<Float>) -> Tensor<Float> {
        // softplus(x) = log(1 + exp(x))
        let result = x.data.map { log(1 + exp($0)) }
        return Tensor(shape: x.shape, data: result)
    }
    
    public func backward(_ x: Tensor<Float>, gradient: Tensor<Float>) -> Tensor<Float> {
        // softplus'(x) = sigmoid(x)
        let derivative = x.data.map { 1.0 / (1.0 + exp(-$0)) }
        var result = [Float](repeating: 0, count: x.count)
        vDSP_vmul(gradient.data, 1, derivative, 1, &result, 1, vDSP_Length(x.count))
        return Tensor(shape: x.shape, data: result)
    }
}

// MARK: - Linear (Identity)
public struct Linear: Activation {
    public let name = "Linear"
    
    public init() {}
    
    public func forward(_ x: Tensor<Float>) -> Tensor<Float> {
        x.copy()
    }
    
    public func backward(_ x: Tensor<Float>, gradient: Tensor<Float>) -> Tensor<Float> {
        gradient.copy()
    }
}

// MARK: - Activation Factory
public enum ActivationType: String, CaseIterable, Sendable {
    case relu
    case leakyRelu
    case elu
    case selu
    case sigmoid
    case tanh
    case softmax
    case swish
    case gelu
    case softplus
    case linear
    
    public func create() -> any Activation {
        switch self {
        case .relu: return ReLU()
        case .leakyRelu: return LeakyReLU()
        case .elu: return ELU()
        case .selu: return SELU()
        case .sigmoid: return Sigmoid()
        case .tanh: return Tanh()
        case .softmax: return Softmax()
        case .swish: return Swish()
        case .gelu: return GELU()
        case .softplus: return Softplus()
        case .linear: return Linear()
        }
    }
}
