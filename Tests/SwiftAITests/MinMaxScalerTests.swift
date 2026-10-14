import Foundation
import Testing
@testable import SwiftAI

@Suite("MinMaxScaler")
struct MinMaxScalerTests {
    let features: Matrix = [[1, -10], [3, 0], [5, 10]]

    @Test("Maps the training range of each feature onto 0...1 and back")
    func unitRange() throws {
        let scaler = try MinMaxScaler.fit(features)
        #expect(scaler.minimums == [1, -10] && scaler.maximums == [5, 10])
        #expect(try scaler.transform(features).values == [0, 0, 0.5, 0.5, 1, 1])
        #expect(try scaler.transform([7, -20]) == [1.5, -0.5])
        #expect(try scaler.inverseTransform([0.25, 0.75]) == [2, 5])
    }

    @Test("Maps onto a custom range")
    func customRange() throws {
        let scaler = try MinMaxScaler.fit(features, range: -1...1)
        #expect(try scaler.transform([3, 10]) == [0, 1])
    }

    @Test("A constant feature maps to the lower end of the range")
    func constantFeature() throws {
        let scaler = try MinMaxScaler.fit([[4, 1], [4, 2]] as Matrix, range: 2...3)
        #expect(try scaler.transform([4, 1.5]) == [2, 2.5])
    }

    @Test("Rejects empty data, invalid ranges and spreads too large to represent")
    func invalidInput() throws {
        #expect(throws: SwiftAIError.emptyDataset) { try MinMaxScaler.fit(Matrix(rows: 0, columns: 1)) }
        #expect(throws: SwiftAIError.self) { try MinMaxScaler.fit(features, range: 1...1) }
        #expect(throws: SwiftAIError.self) { try MinMaxScaler.fit(features, range: -Double.greatestFiniteMagnitude...Double.greatestFiniteMagnitude) }
        #expect(throws: SwiftAIError.self) { try MinMaxScaler.fit([[-1e308], [1e308]] as Matrix) }
        let scaler = try MinMaxScaler.fit(features)
        #expect(throws: SwiftAIError.nonFiniteValue(row: 0, column: 0)) { try scaler.transform([.nan, 0]) }
    }

    @Test("Round-trips through JSON and rejects inconsistent saved values")
    func codable() throws {
        let scaler = try MinMaxScaler.fit(features, range: -1...1)
        #expect(try JSONDecoder().decode(MinMaxScaler.self, from: JSONEncoder().encode(scaler)) == scaler)
        for json in [
            #"{"minimums":[2],"maximums":[1],"range":[0,1]}"#,
            #"{"minimums":[1],"maximums":[2,3],"range":[0,1]}"#,
            #"{"minimums":[1],"maximums":[2],"range":[1,1]}"#,
            #"{"minimums":[1],"maximums":[2],"range":[1,0]}"#,
        ] {
            #expect(throws: (any Error).self) { try JSONDecoder().decode(MinMaxScaler.self, from: Data(json.utf8)) }
        }
    }
}
