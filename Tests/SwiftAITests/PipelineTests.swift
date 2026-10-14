import Foundation
import Testing
@testable import SwiftAI

@Suite("Pipeline")
struct PipelineTests {
    @Test("Scales raw samples with statistics from the training data only")
    func scalesBeforePredicting() throws {
        let (training, test) = try Dataset.iris.stratifiedSplit(testFraction: 0.3, seed: 2)
        let model = try Pipeline.fit(training, transformer: StandardScaler.fit) { scaled in
            try KNearestNeighborsClassifier.fit(scaled, k: 5)
        }
        #expect(model.transformer == (try StandardScaler.fit(training.features)))
        #expect(model.featureCount == 4)
        #expect(model.classes == model.model.classes)
        let sample = test.features.row(0)
        #expect(try model.predict(sample) == model.model.predict(model.transformer.transform(sample)))
        #expect(try model.accuracy(on: test) >= 0.9)
        #expect(abs(try model.classProbabilities(sample).reduce(0, +) - 1) < 1e-12)
    }

    @Test("Works for regressors and with a transformer that changes the feature count")
    func regressorWithPCA() throws {
        let data = try Dataset(features: [[1, 2], [2, 4.1], [3, 5.9], [4, 8.2], [5, 9.9]], targets: [1.0, 2, 3, 4, 5])
        let model = try Pipeline.fit(data, transformer: { try PrincipalComponentAnalysis.fit($0, componentCount: 1) }) {
            try LinearRegression.fit($0)
        }
        #expect(model.model.featureCount == 1)
        #expect(try model.r2Score(on: data) > 0.99)
    }

    @Test("Round-trips through JSON and rejects parts that do not fit together")
    func codable() throws {
        let model = try Pipeline.fit(Dataset.iris, transformer: StandardScaler.fit) { try LogisticRegression.fit($0) }
        let data = try JSONEncoder().encode(model)
        let decoded = try JSONDecoder().decode(Pipeline<StandardScaler, LogisticRegression<String>>.self, from: data)
        #expect(decoded == model)

        let scaler = try StandardScaler.fit([[1, 2], [3, 4]] as Matrix)
        let regression = try LinearRegression.fit(Dataset(features: [[1], [2], [3]], targets: [1.0, 2, 3]))
        let mismatched = #"{"transformer":\#(String(decoding: try JSONEncoder().encode(scaler), as: UTF8.self)),"model":\#(String(decoding: try JSONEncoder().encode(regression), as: UTF8.self))}"#
        #expect(throws: SwiftAIError.self) {
            try JSONDecoder().decode(Pipeline<StandardScaler, LinearRegression>.self, from: Data(mismatched.utf8))
        }
    }
}
