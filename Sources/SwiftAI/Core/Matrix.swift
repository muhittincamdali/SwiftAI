/// A two-dimensional grid of `Double` values, stored row by row.
///
/// `Matrix` holds the feature values of a ``Dataset``: one row per sample and one column per
/// feature. It is a value type, so copies are independent, and it is `Sendable` and `Codable`.
///
/// ```swift
/// let features: Matrix = [
///     [5.1, 3.5],
///     [6.2, 2.9],
/// ]
/// features.rows        // 2
/// features[1, 0]       // 6.2
/// ```
public struct Matrix: Sendable, Hashable {
    /// The number of rows.
    public let rows: Int
    /// The number of columns.
    public let columns: Int
    /// All values in row-major order: the first row, then the second, and so on.
    public private(set) var values: [Double]

    /// Creates a matrix with every value set to `value`.
    ///
    /// - Precondition: `rows` and `columns` are not negative and their product fits in an `Int`.
    public init(rows: Int, columns: Int, repeating value: Double = 0) {
        guard let count = checkedProduct(rows, columns) else {
            preconditionFailure("A \(rows)×\(columns) matrix has negative or too many values")
        }
        self.rows = rows
        self.columns = columns
        self.values = Array(repeating: value, count: count)
    }

    /// Creates a matrix from values in row-major order.
    ///
    /// - Precondition: `values.count == rows * columns`.
    public init(rows: Int, columns: Int, values: [Double]) {
        precondition(
            checkedProduct(rows, columns) == values.count,
            "\(values.count) values do not fill a \(rows)×\(columns) matrix"
        )
        self.rows = rows
        self.columns = columns
        self.values = values
    }

    /// Creates a matrix from an array of rows.
    ///
    /// An empty array gives a matrix with no rows and no columns.
    ///
    /// - Throws: ``SwiftAIError/raggedRows(row:expectedColumns:actualColumns:)`` when the rows do
    ///   not all have the same length.
    public init(_ rowArrays: [[Double]]) throws {
        let columns = rowArrays.first?.count ?? 0
        var values: [Double] = []
        values.reserveCapacity(checkedProduct(rowArrays.count, columns) ?? 0)
        for (index, row) in rowArrays.enumerated() {
            guard row.count == columns else {
                throw SwiftAIError.raggedRows(row: index, expectedColumns: columns, actualColumns: row.count)
            }
            values.append(contentsOf: row)
        }
        self.init(rows: rowArrays.count, columns: columns, values: values)
    }

    /// Accesses the value at `row` and `column`.
    public subscript(row: Int, column: Int) -> Double {
        get {
            checkIndex(row: row, column: column)
            return values[row * columns + column]
        }
        set {
            checkIndex(row: row, column: column)
            values[row * columns + column] = newValue
        }
    }

    /// Returns the values of one row.
    public func row(_ index: Int) -> [Double] {
        precondition(index >= 0 && index < rows, "Row \(index) is out of range 0..<\(rows)")
        let start = index * columns
        return Array(values[start..<start + columns])
    }

    /// Returns the values of one column.
    public func column(_ index: Int) -> [Double] {
        precondition(index >= 0 && index < columns, "Column \(index) is out of range 0..<\(columns)")
        return (0..<rows).map { values[$0 * columns + index] }
    }

    /// The matrix as an array of rows.
    public var rowArrays: [[Double]] {
        (0..<rows).map(row)
    }

    /// Returns a matrix whose rows are the rows at `indices`, in that order.
    ///
    /// Indices may repeat, which is how bootstrap samples are drawn.
    public func selectingRows(_ indices: [Int]) -> Matrix {
        var selected: [Double] = []
        selected.reserveCapacity(indices.count * columns)
        for index in indices {
            precondition(index >= 0 && index < rows, "Row \(index) is out of range 0..<\(rows)")
            let start = index * columns
            selected.append(contentsOf: values[start..<start + columns])
        }
        return Matrix(rows: indices.count, columns: columns, values: selected)
    }

    /// Returns the transpose: rows become columns.
    public func transposed() -> Matrix {
        var result = [Double](repeating: 0, count: values.count)
        for row in 0..<rows {
            for column in 0..<columns {
                result[column * rows + row] = values[row * columns + column]
            }
        }
        return Matrix(rows: columns, columns: rows, values: result)
    }

    /// Returns the identity matrix of the given size.
    public static func identity(_ size: Int) -> Matrix {
        var matrix = Matrix(rows: size, columns: size)
        for index in 0..<size {
            matrix.values[index * size + index] = 1
        }
        return matrix
    }

    private func checkIndex(row: Int, column: Int) {
        precondition(row >= 0 && row < rows, "Row \(row) is out of range 0..<\(rows)")
        precondition(column >= 0 && column < columns, "Column \(column) is out of range 0..<\(columns)")
    }
}

extension Matrix: ExpressibleByArrayLiteral {
    /// Creates a matrix from a literal list of rows.
    ///
    /// - Precondition: All rows have the same length. Use ``init(_:)`` to get an error instead.
    public init(arrayLiteral rows: [Double]...) {
        do {
            try self.init(rows)
        } catch {
            preconditionFailure("\(error)")
        }
    }
}

extension Matrix: CustomStringConvertible {
    public var description: String {
        let rendered = rowArrays.map { row in
            "[" + row.map { "\($0)" }.joined(separator: ", ") + "]"
        }
        return "Matrix(\(rows)×\(columns))[" + rendered.joined(separator: ", ") + "]"
    }
}

extension Matrix: Codable {
    private enum CodingKeys: String, CodingKey {
        case rows, columns, values
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let rows = try container.decode(Int.self, forKey: .rows)
        let columns = try container.decode(Int.self, forKey: .columns)
        let values = try container.decode([Double].self, forKey: .values)
        // The shape comes from the file, so the product is checked: a crafted file with huge
        // dimensions must be rejected, not overflow.
        guard checkedProduct(rows, columns) == values.count else {
            throw DecodingError.dataCorruptedError(
                forKey: .values, in: container,
                debugDescription: "\(values.count) values do not fill a \(rows)×\(columns) matrix"
            )
        }
        self.init(rows: rows, columns: columns, values: values)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(rows, forKey: .rows)
        try container.encode(columns, forKey: .columns)
        try container.encode(values, forKey: .values)
    }
}
