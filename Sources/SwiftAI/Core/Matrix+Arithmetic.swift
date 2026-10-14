#if canImport(Accelerate)
import Accelerate
#endif

extension Matrix {
    /// Returns the matrix product of `lhs` and `rhs`.
    ///
    /// On Apple platforms the product is computed with Accelerate; elsewhere with a portable loop
    /// that gives the same result up to floating-point rounding.
    ///
    /// - Precondition: `lhs.columns == rhs.rows`.
    public static func * (lhs: Matrix, rhs: Matrix) -> Matrix {
        precondition(
            lhs.columns == rhs.rows,
            "Cannot multiply a \(lhs.rows)×\(lhs.columns) matrix by a \(rhs.rows)×\(rhs.columns) matrix"
        )
        guard lhs.rows > 0, rhs.columns > 0, lhs.columns > 0 else {
            return Matrix(rows: lhs.rows, columns: rhs.columns)
        }
        #if canImport(Accelerate)
        return acceleratedProduct(lhs, rhs)
        #else
        return portableProduct(lhs, rhs)
        #endif
    }

    /// Returns the element-wise sum.
    ///
    /// - Precondition: Both matrices have the same shape.
    public static func + (lhs: Matrix, rhs: Matrix) -> Matrix {
        lhs.combined(with: rhs, +)
    }

    /// Returns the element-wise difference.
    ///
    /// - Precondition: Both matrices have the same shape.
    public static func - (lhs: Matrix, rhs: Matrix) -> Matrix {
        lhs.combined(with: rhs, -)
    }

    /// Returns the matrix with every value multiplied by `scalar`.
    public static func * (scalar: Double, matrix: Matrix) -> Matrix {
        matrix.map { scalar * $0 }
    }

    /// Returns a matrix of the same shape with `transform` applied to every value.
    public func map(_ transform: (Double) throws -> Double) rethrows -> Matrix {
        Matrix(rows: rows, columns: columns, values: try values.map(transform))
    }

    func combined(with other: Matrix, _ operation: (Double, Double) -> Double) -> Matrix {
        precondition(
            rows == other.rows && columns == other.columns,
            "Shapes \(rows)×\(columns) and \(other.rows)×\(other.columns) differ"
        )
        return Matrix(rows: rows, columns: columns, values: zip(values, other.values).map(operation))
    }

    /// Adds `vector` to every row.
    func addingToEachRow(_ vector: [Double]) -> Matrix {
        precondition(vector.count == columns, "Vector length \(vector.count) does not match \(columns) columns")
        var result = values
        for row in 0..<rows {
            let start = row * columns
            for column in 0..<columns {
                result[start + column] += vector[column]
            }
        }
        return Matrix(rows: rows, columns: columns, values: result)
    }

    /// The sum of each column.
    func columnSums() -> [Double] {
        var sums = [Double](repeating: 0, count: columns)
        for row in 0..<rows {
            let start = row * columns
            for column in 0..<columns {
                sums[column] += values[start + column]
            }
        }
        return sums
    }

    /// Row-by-column product written as three nested loops, used where Accelerate is missing and
    /// by the tests that compare both paths.
    static func portableProduct(_ lhs: Matrix, _ rhs: Matrix) -> Matrix {
        let inner = lhs.columns
        let width = rhs.columns
        var result = [Double](repeating: 0, count: lhs.rows * width)
        for row in 0..<lhs.rows {
            for k in 0..<inner {
                let factor = lhs.values[row * inner + k]
                if factor == 0 { continue }
                let rhsStart = k * width
                let resultStart = row * width
                for column in 0..<width {
                    result[resultStart + column] += factor * rhs.values[rhsStart + column]
                }
            }
        }
        return Matrix(rows: lhs.rows, columns: width, values: result)
    }

    #if canImport(Accelerate)
    static func acceleratedProduct(_ lhs: Matrix, _ rhs: Matrix) -> Matrix {
        var result = [Double](repeating: 0, count: lhs.rows * rhs.columns)
        lhs.values.withUnsafeBufferPointer { left in
            rhs.values.withUnsafeBufferPointer { right in
                result.withUnsafeMutableBufferPointer { output in
                    vDSP_mmulD(
                        left.baseAddress!, 1, right.baseAddress!, 1, output.baseAddress!, 1,
                        vDSP_Length(lhs.rows), vDSP_Length(rhs.columns), vDSP_Length(lhs.columns)
                    )
                }
            }
        }
        return Matrix(rows: lhs.rows, columns: rhs.columns, values: result)
    }
    #endif
}

/// Dot product of two vectors of the same length.
@inline(__always)
func dot(_ lhs: [Double], _ rhs: [Double]) -> Double {
    var sum = 0.0
    for index in lhs.indices {
        sum += lhs[index] * rhs[index]
    }
    return sum
}
