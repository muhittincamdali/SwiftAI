import Foundation
import Testing
@testable import SwiftAI

@Suite("StandardScaler")
struct StandardScalerTests {
    let features: Matrix = [[1, 2], [3, 6], [5, 10]]

    @Test("Learns the mean and population standard deviation of each column")
    func fit() throws {
        let scaler = try StandardScaler.fit(features)
        #expect(scaler.means == [3, 6])
        #expect(abs(scaler.scales[0] - (8.0 / 3).squareRoot()) < 1e-12)
        #expect(abs(scaler.scales[1] - (32.0 / 3).squareRoot()) < 1e-12)
    }

    @Test("Scaled columns have mean 0 and standard deviation 1, and invert exactly")
    func transformRoundTrip() throws {
        let scaler = try StandardScaler.fit(features)
        let scaled = try scaler.transform(features)
        for column in 0..<2 {
            let values = scaled.column(column)
            let mean = values.reduce(0, +) / 3
            let variance = values.map { ($0 - mean) * ($0 - mean) }.reduce(0, +) / 3
            #expect(abs(mean) < 1e-12)
            #expect(abs(variance - 1) < 1e-12)
        }
        let restored = try scaler.inverseTransform(scaled.row(2))
        #expect(abs(restored[0] - 5) < 1e-12 && abs(restored[1] - 10) < 1e-12)
    }

    @Test("A constant column becomes 0 instead of dividing by zero")
    func constantColumn() throws {
        let scaler = try StandardScaler.fit([[7, 1], [7, 2]] as Matrix)
        #expect(scaler.scales[0] == 1)
        #expect(try scaler.transform([7, 1.5]) == [0, 0])
    }

    @Test("Rejects empty data, NaN values and the wrong number of features")
    func invalidInput() throws {
        #expect(throws: SwiftAIError.emptyDataset) { try StandardScaler.fit(Matrix(rows: 0, columns: 2)) }
        #expect(throws: SwiftAIError.nonFiniteValue(row: 1, column: 0)) {
            try StandardScaler.fit([[1, 2], [.nan, 3]] as Matrix)
        }
        let scaler = try StandardScaler.fit(features)
        #expect(throws: SwiftAIError.featureCountMismatch(expected: 2, actual: 1)) { try scaler.transform([1]) }
        #expect(throws: SwiftAIError.nonFiniteValue(row: 0, column: 1)) { try scaler.transform([1, .infinity]) }
    }

    @Test("Values whose sum overflows are rejected instead of producing infinite statistics")
    func overflowingStatistics() {
        let huge = Double.greatestFiniteMagnitude
        #expect(throws: SwiftAIError.self) { try StandardScaler.fit([[huge], [huge]] as Matrix) }
    }

    @Test("A finite sample that scales to infinity is rejected")
    func overflowingTransform() throws {
        // The mean is -0.75e308, so subtracting it from the largest Double overflows.
        let scaler = try StandardScaler.fit([[-0.8e308], [-0.7e308]] as Matrix)
        #expect(throws: SwiftAIError.nonFiniteValue(row: 0, column: 0)) {
            try scaler.transform([Double.greatestFiniteMagnitude])
        }
    }

    @Test("Round-trips through JSON and rejects inconsistent saved values")
    func codable() throws {
        let scaler = try StandardScaler.fit(features)
        let data = try JSONEncoder().encode(scaler)
        #expect(try JSONDecoder().decode(StandardScaler.self, from: data) == scaler)

        let corrupt = [
            #"{"means":[1,2],"scales":[1]}"#,
            #"{"means":[1],"scales":[0]}"#,
            #"{"means":[1],"scales":[-1]}"#,
            #"{"means":[],"scales":[]}"#,
        ]
        for json in corrupt {
            #expect(throws: SwiftAIError.self) {
                try JSONDecoder().decode(StandardScaler.self, from: Data(json.utf8))
            }
        }
    }
}
