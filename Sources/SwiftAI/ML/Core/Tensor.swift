// Tensor.swift
// SwiftAI - Pure Swift Machine Learning Framework
// Copyright © 2024 Muhittin Camdali. All rights reserved.

import Foundation
import Accelerate

// MARK: - Tensor Core
/// High-performance multi-dimensional array for machine learning computations
/// Uses Accelerate framework for SIMD-optimized operations
public final class Tensor<T: TensorNumeric>: @unchecked Sendable {
    
    // MARK: - Properties
    public private(set) var data: [T]
    public let shape: [Int]
    public let rank: Int
    public let count: Int
    
    private let strides: [Int]
    
    // MARK: - Initialization
    public init(shape: [Int], repeating value: T = .zero) {
        precondition(shape.allSatisfy { $0 > 0 }, "Shape dimensions must be positive")
        self.shape = shape
        self.rank = shape.count
        self.count = shape.reduce(1, *)
        self.strides = Self.computeStrides(shape)
        self.data = Array(repeating: value, count: count)
    }
    
    public init(shape: [Int], data: [T]) {
        precondition(shape.allSatisfy { $0 > 0 }, "Shape dimensions must be positive")
        let expectedCount = shape.reduce(1, *)
        precondition(data.count == expectedCount, "Data count must match shape")
        self.shape = shape
        self.rank = shape.count
        self.count = expectedCount
        self.strides = Self.computeStrides(shape)
        self.data = data
    }
    
    // MARK: - Factory Methods
    public static func zeros(_ shape: [Int]) -> Tensor<T> {
        Tensor(shape: shape, repeating: .zero)
    }
    
    public static func ones(_ shape: [Int]) -> Tensor<T> {
        Tensor(shape: shape, repeating: .one)
    }
    
    public static func random(_ shape: [Int], min: T = .zero, max: T = .one) -> Tensor<T> where T: BinaryFloatingPoint {
        let count = shape.reduce(1, *)
        var data = [T](repeating: .zero, count: count)
        for i in 0..<count {
            let random = T(Double.random(in: 0...1))
            data[i] = min + random * (max - min)
        }
        return Tensor(shape: shape, data: data)
    }
    
    public static func eye(_ size: Int) -> Tensor<T> {
        var tensor = zeros([size, size])
        for i in 0..<size {
            tensor[i, i] = .one
        }
        return tensor
    }
    
    public static func randn(_ shape: [Int], mean: T = .zero, std: T = .one) -> Tensor<T> where T: BinaryFloatingPoint {
        let count = shape.reduce(1, *)
        var data = [T](repeating: .zero, count: count)
        for i in stride(from: 0, to: count - 1, by: 2) {
            // Box-Muller transform
            let u1 = T(Double.random(in: Double.leastNonzeroMagnitude...1))
            let u2 = T(Double.random(in: 0...1))
            let mag = std * T(sqrt(-2.0 * Double(log(Double(u1)))))
            let angle = T(2.0 * Double.pi) * u2
            data[i] = mean + mag * T(cos(Double(angle)))
            if i + 1 < count {
                data[i + 1] = mean + mag * T(sin(Double(angle)))
            }
        }
        if count % 2 == 1 {
            let u1 = T(Double.random(in: Double.leastNonzeroMagnitude...1))
            let u2 = T(Double.random(in: 0...1))
            let mag = std * T(sqrt(-2.0 * Double(log(Double(u1)))))
            data[count - 1] = mean + mag * T(cos(Double(2.0 * Double.pi * Double(u2))))
        }
        return Tensor(shape: shape, data: data)
    }
    
    // MARK: - Indexing
    public subscript(_ indices: Int...) -> T {
        get {
            let flatIndex = computeFlatIndex(indices)
            return data[flatIndex]
        }
        set {
            let flatIndex = computeFlatIndex(indices)
            data[flatIndex] = newValue
        }
    }
    
    public subscript(row row: Int) -> Tensor<T> {
        precondition(rank >= 1, "Tensor must have at least 1 dimension")
        precondition(row >= 0 && row < shape[0], "Row index out of bounds")
        if rank == 1 {
            return Tensor(shape: [1], data: [data[row]])
        }
        let newShape = Array(shape.dropFirst())
        let rowSize = newShape.reduce(1, *)
        let startIndex = row * rowSize
        let rowData = Array(data[startIndex..<(startIndex + rowSize)])
        return Tensor(shape: newShape, data: rowData)
    }
    
    public subscript(column column: Int) -> Tensor<T> {
        precondition(rank == 2, "Column indexing requires 2D tensor")
        precondition(column >= 0 && column < shape[1], "Column index out of bounds")
        var columnData = [T](repeating: .zero, count: shape[0])
        for i in 0..<shape[0] {
            columnData[i] = self[i, column]
        }
        return Tensor(shape: [shape[0]], data: columnData)
    }
    
    // MARK: - Shape Operations
    public func reshape(_ newShape: [Int]) -> Tensor<T> {
        var resolvedShape = newShape
        if let inferIndex = newShape.firstIndex(of: -1) {
            let known = newShape.filter { $0 > 0 }.reduce(1, *)
            resolvedShape[inferIndex] = count / known
        }
        precondition(resolvedShape.reduce(1, *) == count, "New shape must have same count")
        return Tensor(shape: resolvedShape, data: data)
    }
    
    public func flatten() -> Tensor<T> {
        Tensor(shape: [count], data: data)
    }
    
    public func transpose() -> Tensor<T> {
        precondition(rank == 2, "Transpose requires 2D tensor")
        let rows = shape[0]
        let cols = shape[1]
        var transposed = [T](repeating: .zero, count: count)
        for i in 0..<rows {
            for j in 0..<cols {
                transposed[j * rows + i] = data[i * cols + j]
            }
        }
        return Tensor(shape: [cols, rows], data: transposed)
    }
    
    public var T: Tensor<T> { transpose() }
    
    // MARK: - Private Helpers
    private static func computeStrides(_ shape: [Int]) -> [Int] {
        var strides = [Int](repeating: 1, count: shape.count)
        for i in stride(from: shape.count - 2, through: 0, by: -1) {
            strides[i] = strides[i + 1] * shape[i + 1]
        }
        return strides
    }
    
    private func computeFlatIndex(_ indices: [Int]) -> Int {
        precondition(indices.count == rank, "Index count must match rank")
        var flatIndex = 0
        for (i, idx) in indices.enumerated() {
            precondition(idx >= 0 && idx < shape[i], "Index out of bounds")
            flatIndex += idx * strides[i]
        }
        return flatIndex
    }
    
    public func copy() -> Tensor<T> {
        Tensor(shape: shape, data: data)
    }
}

// MARK: - Tensor Numeric Protocol
public protocol TensorNumeric: Numeric, Comparable, ExpressibleByFloatLiteral {
    static var zero: Self { get }
    static var one: Self { get }
    init(_ value: Double)
    func toDouble() -> Double
}

extension Float: TensorNumeric {
    public static var one: Float { 1.0 }
    public func toDouble() -> Double { Double(self) }
}

extension Double: TensorNumeric {
    public static var one: Double { 1.0 }
    public func toDouble() -> Double { self }
}

// MARK: - Accelerate Optimized Operations (Float)
public extension Tensor where T == Float {
    
    static func + (lhs: Tensor<Float>, rhs: Tensor<Float>) -> Tensor<Float> {
        precondition(lhs.shape == rhs.shape, "Shapes must match for addition")
        var result = [Float](repeating: 0, count: lhs.count)
        vDSP_vadd(lhs.data, 1, rhs.data, 1, &result, 1, vDSP_Length(lhs.count))
        return Tensor(shape: lhs.shape, data: result)
    }
    
    static func - (lhs: Tensor<Float>, rhs: Tensor<Float>) -> Tensor<Float> {
        precondition(lhs.shape == rhs.shape, "Shapes must match for subtraction")
        var result = [Float](repeating: 0, count: lhs.count)
        vDSP_vsub(rhs.data, 1, lhs.data, 1, &result, 1, vDSP_Length(lhs.count))
        return Tensor(shape: lhs.shape, data: result)
    }
    
    static func * (lhs: Tensor<Float>, scalar: Float) -> Tensor<Float> {
        var result = [Float](repeating: 0, count: lhs.count)
        var s = scalar
        vDSP_vsmul(lhs.data, 1, &s, &result, 1, vDSP_Length(lhs.count))
        return Tensor(shape: lhs.shape, data: result)
    }
    
    static func * (lhs: Tensor<Float>, rhs: Tensor<Float>) -> Tensor<Float> {
        // Element-wise multiplication
        precondition(lhs.shape == rhs.shape, "Shapes must match for element-wise multiplication")
        var result = [Float](repeating: 0, count: lhs.count)
        vDSP_vmul(lhs.data, 1, rhs.data, 1, &result, 1, vDSP_Length(lhs.count))
        return Tensor(shape: lhs.shape, data: result)
    }
    
    func matmul(_ other: Tensor<Float>) -> Tensor<Float> {
        precondition(self.rank == 2 && other.rank == 2, "Matrix multiplication requires 2D tensors")
        precondition(self.shape[1] == other.shape[0], "Inner dimensions must match")
        
        let M = Int32(self.shape[0])
        let N = Int32(other.shape[1])
        let K = Int32(self.shape[1])
        
        var result = [Float](repeating: 0, count: Int(M * N))
        
        cblas_sgemm(
            CblasRowMajor, CblasNoTrans, CblasNoTrans,
            M, N, K,
            1.0,
            self.data, K,
            other.data, N,
            0.0,
            &result, N
        )
        
        return Tensor(shape: [Int(M), Int(N)], data: result)
    }
    
    func dot(_ other: Tensor<Float>) -> Float {
        precondition(self.count == other.count, "Vectors must have same length")
        var result: Float = 0
        vDSP_dotpr(self.data, 1, other.data, 1, &result, vDSP_Length(count))
        return result
    }
    
    func sum() -> Float {
        var result: Float = 0
        vDSP_sve(data, 1, &result, vDSP_Length(count))
        return result
    }
    
    func mean() -> Float {
        var result: Float = 0
        vDSP_meanv(data, 1, &result, vDSP_Length(count))
        return result
    }
    
    func variance() -> Float {
        let m = mean()
        var meanSq: Float = 0
        vDSP_measqv(data, 1, &meanSq, vDSP_Length(count))
        return meanSq - m * m
    }
    
    func std() -> Float {
        sqrt(variance())
    }
    
    func max() -> Float {
        var result: Float = 0
        vDSP_maxv(data, 1, &result, vDSP_Length(count))
        return result
    }
    
    func min() -> Float {
        var result: Float = 0
        vDSP_minv(data, 1, &result, vDSP_Length(count))
        return result
    }
    
    func argmax() -> Int {
        var maxVal: Float = 0
        var maxIdx: vDSP_Length = 0
        vDSP_maxvi(data, 1, &maxVal, &maxIdx, vDSP_Length(count))
        return Int(maxIdx)
    }
    
    func argmin() -> Int {
        var minVal: Float = 0
        var minIdx: vDSP_Length = 0
        vDSP_minvi(data, 1, &minVal, &minIdx, vDSP_Length(count))
        return Int(minIdx)
    }
    
    func exp() -> Tensor<Float> {
        var result = [Float](repeating: 0, count: count)
        var n = Int32(count)
        vvexpf(&result, data, &n)
        return Tensor(shape: shape, data: result)
    }
    
    func log() -> Tensor<Float> {
        var result = [Float](repeating: 0, count: count)
        var n = Int32(count)
        vvlogf(&result, data, &n)
        return Tensor(shape: shape, data: result)
    }
    
    func sqrt() -> Tensor<Float> {
        var result = [Float](repeating: 0, count: count)
        var n = Int32(count)
        vvsqrtf(&result, data, &n)
        return Tensor(shape: shape, data: result)
    }
    
    func pow(_ exponent: Float) -> Tensor<Float> {
        var result = [Float](repeating: 0, count: count)
        var exp = [Float](repeating: exponent, count: count)
        var n = Int32(count)
        vvpowf(&result, &exp, data, &n)
        return Tensor(shape: shape, data: result)
    }
    
    func clip(min minVal: Float, max maxVal: Float) -> Tensor<Float> {
        var result = [Float](repeating: 0, count: count)
        var minV = minVal
        var maxV = maxVal
        vDSP_vclip(data, 1, &minV, &maxV, &result, 1, vDSP_Length(count))
        return Tensor(shape: shape, data: result)
    }
    
    func normalize() -> Tensor<Float> {
        let m = mean()
        let s = std()
        guard s > 0 else { return self.copy() }
        var result = [Float](repeating: 0, count: count)
        var negMean = -m
        vDSP_vsadd(data, 1, &negMean, &result, 1, vDSP_Length(count))
        var invStd = 1.0 / s
        vDSP_vsmul(result, 1, &invStd, &result, 1, vDSP_Length(count))
        return Tensor(shape: shape, data: result)
    }
}

// MARK: - Accelerate Optimized Operations (Double)
public extension Tensor where T == Double {
    
    static func + (lhs: Tensor<Double>, rhs: Tensor<Double>) -> Tensor<Double> {
        precondition(lhs.shape == rhs.shape, "Shapes must match for addition")
        var result = [Double](repeating: 0, count: lhs.count)
        vDSP_vaddD(lhs.data, 1, rhs.data, 1, &result, 1, vDSP_Length(lhs.count))
        return Tensor(shape: lhs.shape, data: result)
    }
    
    static func - (lhs: Tensor<Double>, rhs: Tensor<Double>) -> Tensor<Double> {
        precondition(lhs.shape == rhs.shape, "Shapes must match for subtraction")
        var result = [Double](repeating: 0, count: lhs.count)
        vDSP_vsubD(rhs.data, 1, lhs.data, 1, &result, 1, vDSP_Length(lhs.count))
        return Tensor(shape: lhs.shape, data: result)
    }
    
    static func * (lhs: Tensor<Double>, scalar: Double) -> Tensor<Double> {
        var result = [Double](repeating: 0, count: lhs.count)
        var s = scalar
        vDSP_vsmulD(lhs.data, 1, &s, &result, 1, vDSP_Length(lhs.count))
        return Tensor(shape: lhs.shape, data: result)
    }
    
    func matmul(_ other: Tensor<Double>) -> Tensor<Double> {
        precondition(self.rank == 2 && other.rank == 2, "Matrix multiplication requires 2D tensors")
        precondition(self.shape[1] == other.shape[0], "Inner dimensions must match")
        
        let M = Int32(self.shape[0])
        let N = Int32(other.shape[1])
        let K = Int32(self.shape[1])
        
        var result = [Double](repeating: 0, count: Int(M * N))
        
        cblas_dgemm(
            CblasRowMajor, CblasNoTrans, CblasNoTrans,
            M, N, K,
            1.0,
            self.data, K,
            other.data, N,
            0.0,
            &result, N
        )
        
        return Tensor(shape: [Int(M), Int(N)], data: result)
    }
    
    func sum() -> Double {
        var result: Double = 0
        vDSP_sveD(data, 1, &result, vDSP_Length(count))
        return result
    }
    
    func mean() -> Double {
        var result: Double = 0
        vDSP_meanvD(data, 1, &result, vDSP_Length(count))
        return result
    }
}

// MARK: - Description
extension Tensor: CustomStringConvertible {
    public var description: String {
        "Tensor<\(T.self)>(shape: \(shape), data: \(data.prefix(10))...)"
    }
}
