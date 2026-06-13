import Foundation
import Accelerate

// MARK: - Tensor Core
/// High-performance multi-dimensional array for machine learning computations
/// Uses Accelerate framework for SIMD-optimized operations
public struct Tensor<T: TensorNumeric>: Sendable {
    
    // MARK: - Properties
    public var data: [T]
    public let shape: [Int]
    
    public var rank: Int { shape.count }
    public var count: Int { data.count }
    
    // MARK: - Initialization
    public init(shape: [Int], repeating value: T = .zero) {
        precondition(shape.allSatisfy { $0 > 0 }, "Shape dimensions must be positive")
        self.shape = shape
        let totalCount = shape.reduce(1, *)
        self.data = Array(repeating: value, count: totalCount)
    }
    
    public init(shape: [Int], data: [T]) {
        precondition(shape.allSatisfy { $0 > 0 }, "Shape dimensions must be positive")
        let expectedCount = shape.reduce(1, *)
        precondition(data.count == expectedCount, "Data count must match shape")
        self.shape = shape
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
        let totalCount = shape.reduce(1, *)
        var data = [T](repeating: .zero, count: totalCount)
        for i in 0..<totalCount {
            let randomValue = Double.random(in: 0...1)
            data[i] = min + T(randomValue) * (max - min)
        }
        return Tensor(shape: shape, data: data)
    }
    
    public static func randn(_ shape: [Int], mean: T = .zero, std: T = .one) -> Tensor<T> where T: BinaryFloatingPoint {
        let totalCount = shape.reduce(1, *)
        var data = [T](repeating: .zero, count: totalCount)
        for i in Swift.stride(from: 0, to: totalCount - 1, by: 2) {
            let u1 = Double.random(in: Double.leastNonzeroMagnitude...1)
            let u2 = Double.random(in: 0...1)
            let mag = Double(std) * sqrt(-2.0 * log(u1))
            let angle = 2.0 * Double.pi * u2
            data[i] = mean + T(mag * cos(angle))
            if i + 1 < totalCount {
                data[i + 1] = mean + T(mag * sin(angle))
            }
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
    private func computeFlatIndex(_ indices: [Int]) -> Int {
        precondition(indices.count == rank, "Index count must match rank")
        var flatIndex = 0
        var currentStride = 1
        for i in Swift.stride(from: rank - 1, through: 0, by: -1) {
            precondition(indices[i] >= 0 && indices[i] < shape[i], "Index out of bounds")
            flatIndex += indices[i] * currentStride
            currentStride *= shape[i]
        }
        return flatIndex
    }
    
    public func copy() -> Tensor<T> { self }
    
    // MARK: - Math Operations
    public func max() -> T {
        data.max() ?? .zero
    }

    public func argmax() -> Int {
        guard !data.isEmpty else { return 0 }
        var maxIdx = 0
        var maxValue = data[0]
        for i in 1..<data.count {
            if data[i] > maxValue {
                maxValue = data[i]
                maxIdx = i
            }
        }
        return maxIdx
    }
    
    public func sum() -> T {
        if T.self == Float.self {
            var result: Float = 0
            vDSP_sve(data as! [Float], 1, &result, vDSP_Length(count))
            return result as! T
        }
        return data.reduce(.zero, +)
    }
    
    public func mean() -> T {
        if T.self == Float.self {
            var result: Float = 0
            vDSP_meanv(data as! [Float], 1, &result, vDSP_Length(count))
            return result as! T
        }
        // Generic fallback with manual division
        let s = sum()
        if let floatS = s as? Float {
            return (floatS / Float(count)) as! T
        } else if let doubleS = s as? Double {
            return (doubleS / Double(count)) as! T
        }
        return s
    }

    public func variance() -> T {
        let m = mean()
        if T.self == Float.self {
            var result: Float = 0
            let floatData = data as! [Float]
            let floatMean = m as! Float
            var dev = [Float](repeating: 0, count: count)
            vDSP_vsub(floatData, 1, [floatMean], 0, &dev, 1, vDSP_Length(count))
            vDSP_measqv(dev, 1, &result, vDSP_Length(count))
            return result as! T
        }
        return .zero 
    }
    
    public func dot(_ other: Tensor<T>) -> T {
        precondition(count == other.count, "Tensors must have same count for dot product")
        if T.self == Float.self {
            var result: Float = 0
            vDSP_dotpr(data as! [Float], 1, other.data as! [Float], 1, &result, vDSP_Length(count))
            return result as! T
        }
        var currentSum: T = .zero
        for i in 0..<count {
            currentSum += data[i] * other.data[i]
        }
        return currentSum
    }
    
    public func matmul(_ other: Tensor<T>) -> Tensor<T> {
        precondition(rank == 2 && other.rank == 2, "Matrix multiplication requires 2D tensors")
        precondition(shape[1] == other.shape[0], "Matrix dimensions must match")
        
        let m = shape[0]
        let k = shape[1]
        let n = other.shape[1]
        
        var resultData = [T](repeating: .zero, count: m * n)
        
        if T.self == Float.self {
            let a = data as! [Float]
            let b = other.data as! [Float]
            var c = [Float](repeating: 0, count: m * n)
            cblas_sgemm(CblasRowMajor, CblasNoTrans, CblasNoTrans,
                        Int32(m), Int32(n), Int32(k),
                        1.0, a, Int32(k),
                        b, Int32(n),
                        0.0, &c, Int32(n))
            resultData = c as! [T]
        } else {
            for i in 0..<m {
                for j in 0..<n {
                    var currentSum: T = .zero
                    for l in 0..<k {
                        currentSum += self[i, l] * other[l, j]
                    }
                    resultData[i * n + j] = currentSum
                }
            }
        }
        
        return Tensor(shape: [m, n], data: resultData)
    }

    public static func *(lhs: Tensor<T>, rhs: Tensor<T>) -> Tensor<T> {
        precondition(lhs.shape == rhs.shape, "Shapes must match for element-wise multiplication")
        var res = [T](repeating: .zero, count: lhs.count)
        if T.self == Float.self {
            var floatRes = [Float](repeating: 0, count: lhs.count)
            vDSP_vmul(lhs.data as! [Float], 1, rhs.data as! [Float], 1, &floatRes, 1, vDSP_Length(lhs.count))
            res = floatRes as! [T]
        } else {
            for i in 0..<lhs.count {
                res[i] = lhs.data[i] * rhs.data[i]
            }
        }
        return Tensor(shape: lhs.shape, data: res)
    }
}

// MARK: - Tensor Numeric Protocol
public protocol TensorNumeric: Numeric, Comparable, ExpressibleByFloatLiteral, Sendable {
    static var zero: Self { get }
    static var one: Self { get }
    init(_ value: Double)
}

extension Float: TensorNumeric {
    public static var one: Float { 1.0 }
}

extension Double: TensorNumeric {
    public static var one: Double { 1.0 }
}
