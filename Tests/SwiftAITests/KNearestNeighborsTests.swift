import Foundation
import Testing
@testable import SwiftAI

@Suite("KNearestNeighbors")
struct KNearestNeighborsTests {
    // Two clusters on a line: "low" around 0-2, "high" around 10-12.
    let points = try! Dataset(features: [[0], [1], [2], [10], [11], [12]],
                              targets: ["low", "low", "low", "high", "high", "high"])

    @Test("Votes among the k closest samples decide the label and the probabilities")
    func uniformVotes() throws {
        let model = try KNearestNeighborsClassifier.fit(points, k: 3)
        #expect(model.classes == ["low", "high"])
        #expect(try model.predict([1.4]) == "low")
        #expect(try model.predict([9]) == "high")
        // The 5 nearest samples of 4 are 2, 1, 0 (low) and 10, 11 (high).
        let fiveNearest = try KNearestNeighborsClassifier.fit(points, k: 5)
        #expect(try fiveNearest.classProbabilities([4]) == [0.6, 0.4])
        #expect(try fiveNearest.probabilities([4]) == ["low": 0.6, "high": 0.4])
    }

    @Test("Distance weighting favours the closer neighbours")
    func distanceWeights() throws {
        // From 7 the neighbours are 10 (distance 3, high), 11 (4, high) and 2 (5, low); 12 is also
        // at distance 5 but comes later in the training data.
        let model = try KNearestNeighborsClassifier.fit(points, k: 3, weighting: .distance)
        let probabilities = try model.classProbabilities([7])
        let high = 1.0 / 3 + 1.0 / 4
        let low = 1.0 / 5
        #expect(abs(probabilities[1] - high / (high + low)) < 1e-12)
        // A sample equal to a training sample takes that sample's label alone.
        #expect(try model.classProbabilities([10]) == [0, 1])
    }

    @Test("Equal distances are broken by training order, so results are reproducible")
    func ties() throws {
        let data = try Dataset(features: [[-1], [1]], targets: ["left", "right"])
        let model = try KNearestNeighborsClassifier.fit(data, k: 1)
        #expect(try model.predict([0]) == "left")
    }

    @Test("Predicts the (weighted) mean of the neighbours' targets")
    func regressor() throws {
        let data = try Dataset(features: [[0], [1], [2], [10]], targets: [0.0, 10, 20, 100])
        let uniform = try KNearestNeighborsRegressor.fit(data, k: 2)
        #expect(try uniform.predict([0.4]) == 5)
        let weighted = try KNearestNeighborsRegressor.fit(data, k: 2, weighting: .distance)
        // Neighbours 0 (distance 0.25) and 1 (0.75): weights 4 and 4/3.
        #expect(abs(try weighted.predict([0.25]) - (4 * 0 + 4.0 / 3 * 10) / (4 + 4.0 / 3)) < 1e-12)
        #expect(try weighted.predict([2]) == 20)
    }

    @Test("Separates the iris species with high accuracy on unseen samples")
    func iris() throws {
        let (training, test) = try Dataset.iris.stratifiedSplit(testFraction: 0.3, seed: 7)
        let model = try KNearestNeighborsClassifier.fit(training, k: 5)
        #expect(try model.accuracy(on: test) >= 0.9)
    }

    @Test("Rejects invalid k, wrong samples and distances that overflow")
    func invalidInput() throws {
        #expect(throws: SwiftAIError.self) { try KNearestNeighborsClassifier.fit(points, k: 0) }
        #expect(throws: SwiftAIError.insufficientSamples(required: 7, actual: 6)) {
            try KNearestNeighborsClassifier.fit(points, k: 7)
        }
        let model = try KNearestNeighborsClassifier.fit(points, k: 3)
        #expect(throws: SwiftAIError.featureCountMismatch(expected: 1, actual: 2)) { try model.predict([1, 2]) }
        #expect(throws: SwiftAIError.nonFiniteValue(row: 0, column: 0)) { try model.predict([.nan]) }
        #expect(throws: SwiftAIError.self) { try model.predict([Double.greatestFiniteMagnitude]) }
        let nanTarget = try Dataset(features: [[0], [1]], targets: [1, Double.nan])
        #expect(throws: SwiftAIError.nonFiniteTarget(row: 1)) { try KNearestNeighborsRegressor.fit(nanTarget, k: 1) }
    }

    @Test("Round-trips through JSON and rejects inconsistent saved models")
    func codable() throws {
        let model = try KNearestNeighborsClassifier.fit(points, k: 3, weighting: .distance)
        let data = try JSONEncoder().encode(model)
        #expect(try JSONDecoder().decode(KNearestNeighborsClassifier<String>.self, from: data) == model)

        let features = #""features":{"rows":2,"columns":1,"values":[0,1]}"#
        for json in [
            #"{"k":3,"weighting":"uniform","classes":["a","b"],\#(features),"targetIndices":[0,1]}"#,
            #"{"k":1,"weighting":"uniform","classes":["a","b"],\#(features),"targetIndices":[0,2]}"#,
            #"{"k":1,"weighting":"uniform","classes":["a","a"],\#(features),"targetIndices":[0,1]}"#,
            #"{"k":1,"weighting":"uniform","classes":["a","b"],\#(features),"targetIndices":[0]}"#,
            #"{"k":1,"weighting":"cosine","classes":["a","b"],\#(features),"targetIndices":[0,1]}"#,
        ] {
            #expect(throws: (any Error).self) {
                try JSONDecoder().decode(KNearestNeighborsClassifier<String>.self, from: Data(json.utf8))
            }
        }

        let regressor = try KNearestNeighborsRegressor.fit(Dataset(features: [[0], [1]], targets: [1.0, 2]), k: 2)
        let decoded = try JSONDecoder().decode(KNearestNeighborsRegressor.self, from: JSONEncoder().encode(regressor))
        #expect(decoded == regressor)
    }
}
