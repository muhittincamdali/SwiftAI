import Testing
@testable import SwiftAI

@Suite("CrossValidation")
struct CrossValidationTests {
    @Test("Scores a classifier on every stratified fold")
    func classifier() throws {
        let result = try Dataset.iris.crossValidate(folds: 5, seed: 1) { training in
            try GaussianNaiveBayes.fit(training)
        }
        #expect(result.scores.count == 5)
        #expect(result.mean > 0.9 && result.mean <= 1)
        let mean = result.scores.reduce(0, +) / 5
        #expect(abs(result.mean - mean) < 1e-15)
        let variance = result.scores.map { ($0 - mean) * ($0 - mean) }.reduce(0, +) / 5
        #expect(abs(result.standardDeviation - variance.squareRoot()) < 1e-15)
    }

    @Test("Scores a regressor with R² on every fold")
    func regressor() throws {
        let data = try noisySine(count: 120, seed: 3)
        let result = try data.crossValidate(folds: 4) { try KNearestNeighborsRegressor.fit($0, k: 5) }
        #expect(result.scores.count == 4)
        #expect(result.scores.allSatisfy { $0 > 0.8 })
    }

    @Test("Rejects fewer than two folds and more folds than samples")
    func invalidFolds() throws {
        #expect(throws: SwiftAIError.self) {
            try Dataset.iris.crossValidate(folds: 1) { try GaussianNaiveBayes.fit($0) }
        }
        let small = try Dataset(features: [[1], [2], [3]], targets: [1.0, 2, 3])
        #expect(throws: SwiftAIError.insufficientSamples(required: 4, actual: 3)) {
            try small.crossValidate(folds: 4) { try LinearRegression.fit($0) }
        }
    }
}
