import Foundation
import Testing
@testable import SwiftAI

@Suite("Matrix")
struct MatrixTests {
    @Test("Rows are stored in row-major order")
    func rowMajorLayout() throws {
        let matrix = try Matrix([[1, 2, 3], [4, 5, 6]])
        #expect(matrix.rows == 2)
        #expect(matrix.columns == 3)
        #expect(matrix.values == [1, 2, 3, 4, 5, 6])
        #expect(matrix[1, 0] == 4)
        #expect(matrix.row(1) == [4, 5, 6])
        #expect(matrix.column(2) == [3, 6])
        #expect(matrix.rowArrays == [[1, 2, 3], [4, 5, 6]])
    }

    @Test("Ragged rows are rejected with the offending row")
    func raggedRows() {
        #expect(throws: SwiftAIError.raggedRows(row: 2, expectedColumns: 2, actualColumns: 1)) {
            try Matrix([[1, 2], [3, 4], [5]])
        }
    }

    @Test("An empty array gives a 0×0 matrix")
    func emptyMatrix() throws {
        let matrix = try Matrix([])
        #expect(matrix.rows == 0)
        #expect(matrix.columns == 0)
        #expect(matrix.values.isEmpty)
    }

    @Test("Subscript writes change one value")
    func subscriptWrite() {
        var matrix = Matrix(rows: 2, columns: 2)
        matrix[0, 1] = 7
        #expect(matrix.values == [0, 7, 0, 0])
    }

    @Test("Transpose swaps rows and columns")
    func transpose() throws {
        let matrix = try Matrix([[1, 2, 3], [4, 5, 6]])
        let transposed = matrix.transposed()
        #expect(transposed.rows == 3)
        #expect(transposed.rowArrays == [[1, 4], [2, 5], [3, 6]])
        #expect(transposed.transposed() == matrix)
    }

    @Test("Matrix product matches a hand-computed result")
    func product() throws {
        let lhs = try Matrix([[1, 2], [3, 4], [5, 6]])
        let rhs = try Matrix([[7, 8, 9], [10, 11, 12]])
        let expected = try Matrix([[27, 30, 33], [61, 68, 75], [95, 106, 117]])
        #expect(lhs * rhs == expected)
        #expect(Matrix.portableProduct(lhs, rhs) == expected)
    }

    @Test("Identity is neutral for the product")
    func identity() throws {
        let matrix = try Matrix([[2, -1], [0.5, 3]])
        #expect(Matrix.identity(2) * matrix == matrix)
        #expect(matrix * Matrix.identity(2) == matrix)
    }

    @Test("Accelerate and the portable loop agree on random matrices")
    func productPathsAgree() {
        var generator = SeededGenerator(seed: 11)
        let lhs = Matrix(rows: 17, columns: 9, values: (0..<153).map { _ in generator.nextGaussian() })
        let rhs = Matrix(rows: 9, columns: 13, values: (0..<117).map { _ in generator.nextGaussian() })
        let fast = lhs * rhs
        let portable = Matrix.portableProduct(lhs, rhs)
        for (a, b) in zip(fast.values, portable.values) {
            #expect(abs(a - b) < 1e-12)
        }
    }

    @Test("Products with an empty dimension give zeros of the right shape")
    func emptyProduct() {
        let lhs = Matrix(rows: 2, columns: 0)
        let rhs = Matrix(rows: 0, columns: 3)
        #expect(lhs * rhs == Matrix(rows: 2, columns: 3))
    }

    @Test("Element-wise arithmetic")
    func elementWise() throws {
        let a = try Matrix([[1, 2], [3, 4]])
        let b = try Matrix([[10, 20], [30, 40]])
        #expect((a + b).values == [11, 22, 33, 44])
        #expect((b - a).values == [9, 18, 27, 36])
        #expect((2 * a).values == [2, 4, 6, 8])
        #expect(a.map { $0 * $0 }.values == [1, 4, 9, 16])
        #expect(a.addingToEachRow([100, 200]).values == [101, 202, 103, 204])
        #expect(a.columnSums() == [4, 6])
    }

    @Test("Selecting rows keeps order and allows repeats")
    func selectingRows() throws {
        let matrix = try Matrix([[1], [2], [3]])
        #expect(matrix.selectingRows([2, 0, 2]).values == [3, 1, 3])
        #expect(matrix.selectingRows([]).rows == 0)
    }

    @Test("Array literals build a matrix")
    func literal() {
        let matrix: Matrix = [[1, 2], [3, 4]]
        #expect(matrix.values == [1, 2, 3, 4])
    }

    @Test("Codable round trip keeps shape and values")
    func codableRoundTrip() throws {
        let matrix = try Matrix([[1.5, -2], [0, 1e-9]])
        let data = try JSONEncoder().encode(matrix)
        #expect(try JSONDecoder().decode(Matrix.self, from: data) == matrix)
    }

    @Test("Decoding rejects a value count that does not fit the shape")
    func decodingRejectsBadShape() {
        let json = Data(#"{"rows":2,"columns":2,"values":[1,2,3]}"#.utf8)
        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(Matrix.self, from: json)
        }
    }

    @Test("Description lists the shape and rows")
    func description() throws {
        let matrix = try Matrix([[1, 2]])
        #expect(matrix.description == "Matrix(1×2)[[1.0, 2.0]]")
    }
}
