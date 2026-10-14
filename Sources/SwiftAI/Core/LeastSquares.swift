// Linear least squares with Householder QR. QR works on the data itself instead of the normal
// equations XᵀX, whose condition number is the square of the data's, so nearly collinear
// features keep more correct digits.

/// The Euclidean norm, computed on values divided by the largest one so that squaring large
/// values cannot overflow.
func euclideanNorm<Values: Collection<Double>>(_ values: Values) -> Double {
    let largest = values.lazy.map(abs).max() ?? 0
    guard largest > 0, largest.isFinite else { return largest }
    var sum = 0.0
    for value in values {
        let scaled = value / largest
        sum += scaled * scaled
    }
    return largest * sum.squareRoot()
}

/// Solves `min ‖a·x − b‖` for `x`.
///
/// Columns are scaled to unit norm first, so the rank test does not depend on the units of the
/// features.
///
/// - Throws: ``SwiftAIError/singularMatrix`` when the columns are linearly dependent (or nearly
///   so), including a column of zeros.
func solveLeastSquares(_ a: Matrix, _ b: [Double]) throws -> [Double] {
    let rowCount = a.rows
    let columnCount = a.columns
    guard rowCount >= columnCount, columnCount > 0 else { throw SwiftAIError.singularMatrix }

    var columns = (0..<columnCount).map { a.column($0) }
    let norms = columns.map { euclideanNorm($0) }
    try requireRepresentable(norms)
    guard norms.allSatisfy({ $0 > 0 }) else { throw SwiftAIError.singularMatrix }
    for index in columns.indices {
        columns[index] = columns[index].map { $0 / norms[index] }
    }

    var rhs = b
    var diagonal = [Double](repeating: 0, count: columnCount)
    for pivot in 0..<columnCount {
        let norm = euclideanNorm(columns[pivot][pivot...])
        guard norm > 0 else { throw SwiftAIError.singularMatrix }
        let alpha = columns[pivot][pivot] > 0 ? -norm : norm
        var reflector = Array(columns[pivot][pivot...])
        reflector[0] -= alpha
        let reflectorNormSquared = dot(reflector, reflector)
        diagonal[pivot] = alpha
        guard reflectorNormSquared > 0 else { continue }
        for column in (pivot + 1)..<columnCount {
            reflect(&columns[column], from: pivot, reflector, reflectorNormSquared)
        }
        reflect(&rhs, from: pivot, reflector, reflectorNormSquared)
    }

    // The columns have unit norm, so a diagonal entry this small means the column is a linear
    // combination of the previous ones up to rounding.
    let tolerance = 1e-10
    guard diagonal.allSatisfy({ abs($0) > tolerance }) else { throw SwiftAIError.singularMatrix }

    var solution = [Double](repeating: 0, count: columnCount)
    for row in stride(from: columnCount - 1, through: 0, by: -1) {
        var sum = rhs[row]
        for column in (row + 1)..<columnCount {
            sum -= columns[column][row] * solution[column]
        }
        solution[row] = sum / diagonal[row]
    }
    return zip(solution, norms).map { $0 / $1 }
}

/// Applies the Householder reflection `I − 2vvᵀ/(vᵀv)` to `values[start...]`.
private func reflect(_ values: inout [Double], from start: Int, _ reflector: [Double], _ normSquared: Double) {
    var projection = 0.0
    for index in reflector.indices {
        projection += reflector[index] * values[start + index]
    }
    let scale = 2 * projection / normSquared
    for index in reflector.indices {
        values[start + index] -= scale * reflector[index]
    }
}
