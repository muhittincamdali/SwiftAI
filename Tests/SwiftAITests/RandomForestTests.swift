import Foundation
import Testing
@testable import SwiftAI

/// y = sin(x) plus seeded noise, for x in 0..<6.
func noisySine(count: Int, seed: UInt64) throws -> Dataset<Double> {
    var generator = SeededGenerator(seed: seed)
    let xs = (0..<count).map { _ in generator.nextUnitInterval() * 6 }
    let ys = xs.map { sin($0) + generator.nextGaussian(standardDeviation: 0.1) }
    return try Dataset(features: xs.map { [$0] }, targets: ys)
}

@Suite("RandomForest")
struct RandomForestTests {
    @Test("Classifies held-out iris samples and averages tree probabilities")
    func classifier() throws {
        let (training, test) = try Dataset.iris.stratifiedSplit(testFraction: 0.3, seed: 3)
        let forest = try RandomForestClassifier.fit(training, treeCount: 50, seed: 1)
        #expect(forest.treeCount == 50)
        #expect(try forest.accuracy(on: test) >= 0.9)
        let probabilities = try forest.classProbabilities([6.3, 2.8, 5.1, 1.5])
        #expect(abs(probabilities.reduce(0, +) - 1) < 1e-12)
        let importances = forest.featureImportances
        #expect(abs(importances.reduce(0, +) - 1) < 1e-12)
        // Petal measurements separate the species far better than sepal width.
        #expect(importances[2] > importances[1])
    }

    @Test("The same seed gives the same forest, although trees are trained in parallel")
    func deterministic() throws {
        let first = try RandomForestClassifier.fit(Dataset.iris, treeCount: 20, seed: 9)
        let second = try RandomForestClassifier.fit(Dataset.iris, treeCount: 20, seed: 9)
        let other = try RandomForestClassifier.fit(Dataset.iris, treeCount: 20, seed: 10)
        #expect(first == second)
        #expect(first != other)
    }

    @Test("A regression forest generalizes better than one unlimited tree on noisy data")
    func regressor() throws {
        let training = try noisySine(count: 200, seed: 1)
        let test = try noisySine(count: 100, seed: 2)
        let forest = try RandomForestRegressor.fit(training, treeCount: 60, seed: 4)
        let tree = try DecisionTreeRegressor.fit(training)
        let forestScore = try forest.r2Score(on: test)
        let treeScore = try tree.r2Score(on: test)
        #expect(forestScore > 0.9)
        #expect(forestScore > treeScore)
    }

    @Test("Rejects invalid settings")
    func invalidInput() throws {
        #expect(throws: SwiftAIError.self) { try RandomForestClassifier.fit(Dataset.iris, treeCount: 0) }
        #expect(throws: SwiftAIError.self) { try RandomForestClassifier.fit(Dataset.iris, maxFeatures: 5) }
        #expect(throws: SwiftAIError.self) { try RandomForestClassifier.fit(Dataset.iris, maxFeatures: 0) }
        let nan = try Dataset(features: [[0], [1]], targets: [0, Double.nan])
        #expect(throws: SwiftAIError.self) { try RandomForestRegressor.fit(nan) }
    }

    @Test("Round-trips through JSON and rejects a forest without trees")
    func codable() throws {
        let forest = try RandomForestClassifier.fit(Dataset.iris, treeCount: 5, maxDepth: 3)
        let decoded = try JSONDecoder().decode(RandomForestClassifier<String>.self, from: JSONEncoder().encode(forest))
        #expect(decoded == forest)
        let regressor = try RandomForestRegressor.fit(noisySine(count: 20, seed: 1), treeCount: 3)
        let decodedRegressor = try JSONDecoder().decode(RandomForestRegressor.self, from: JSONEncoder().encode(regressor))
        #expect(decodedRegressor == regressor)
        let empty = #"{"classes":["a","b"],"featureCount":1,"trees":[]}"#
        #expect(throws: SwiftAIError.self) {
            try JSONDecoder().decode(RandomForestClassifier<String>.self, from: Data(empty.utf8))
        }
    }
}
