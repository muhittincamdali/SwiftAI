import Foundation
import Testing
@testable import SwiftAI

@Suite("LogisticRegression")
struct LogisticRegressionTests {
    @Test("Multinomial probabilities match scikit-learn's LogisticRegression(C=1) on iris")
    func multinomial() throws {
        let model = try LogisticRegression.fit(Dataset.iris, tolerance: 1e-9)
        #expect(model.converged)
        expectClose(try model.classProbabilities(irisQueries[0]), [0.015187611427178463, 0.8988187182500309, 0.08599367032279066], tolerance: 1e-5)
        expectClose(try model.classProbabilities(irisQueries[1]), [0.0005290066624490954, 0.4755655890757715, 0.5239054042617793], tolerance: 1e-5)
        expectClose(try model.classProbabilities(irisQueries[2]), [0.9852348483718644, 0.01476513962454159, 1.2003594117533507e-08], tolerance: 1e-5)
        let accuracy = try model.accuracy(on: Dataset.iris)
        #expect(abs(accuracy - 0.9733333333333334) < 1e-12)
    }

    @Test("Two classes give binary logistic regression with one weight vector")
    func binary() throws {
        let data = try Dataset(features: [[0.5], [1.0], [1.5], [2.0], [2.5], [3.0], [3.5], [4.0]],
                               targets: [0, 0, 1, 0, 1, 0, 1, 1])
        let model = try LogisticRegression.fit(data, tolerance: 1e-10)
        #expect(model.weights.row(0) == [0])
        #expect(abs(model.weights[1, 0] - 0.7387763479908741) < 1e-6)
        #expect(abs(model.intercepts[1] - -1.662246783039085) < 1e-6)
        expectClose(try model.classProbabilities([2.2]), [0.509233654463493, 0.49076634553650705], tolerance: 1e-6)
    }

    @Test("Separable data stays finite thanks to the penalty")
    func separable() throws {
        let data = try Dataset(features: [[0], [1], [10], [11]], targets: ["no", "no", "yes", "yes"])
        let model = try LogisticRegression.fit(data, regularization: 1e-6)
        #expect(model.weights.values.allSatisfy { $0.isFinite })
        #expect(try model.predict([0.5]) == "no")
        #expect(try model.predict([10.5]) == "yes")
    }

    @Test("Rejects one class, invalid settings and features too large to compute with")
    func invalidInput() throws {
        let one = try Dataset(features: [[1], [2]], targets: ["a", "a"])
        #expect(throws: SwiftAIError.singleClass) { try LogisticRegression.fit(one) }
        #expect(throws: SwiftAIError.self) { try LogisticRegression.fit(Dataset.iris, regularization: 0) }
        #expect(throws: SwiftAIError.self) { try LogisticRegression.fit(Dataset.iris, maxIterations: 0) }
        #expect(throws: SwiftAIError.self) { try LogisticRegression.fit(Dataset.iris, tolerance: .nan) }
        let huge = try Dataset(features: [[1e308], [-1e308], [1e308]], targets: ["a", "b", "a"])
        #expect(throws: SwiftAIError.self) { try LogisticRegression.fit(huge) }
        let model = try LogisticRegression.fit(Dataset.iris)
        #expect(throws: SwiftAIError.self) { try model.predict([1e308, 1e308, -1e308, 1e308]) }
    }

    @Test("Reports when the iteration limit stops training early")
    func iterationLimit() throws {
        let model = try LogisticRegression.fit(Dataset.iris, maxIterations: 2)
        #expect(!model.converged)
    }

    @Test("Round-trips through JSON and rejects inconsistent saved models")
    func codable() throws {
        let model = try LogisticRegression.fit(Dataset.iris)
        let decoded = try JSONDecoder().decode(LogisticRegression<String>.self, from: JSONEncoder().encode(model))
        #expect(decoded == model)
        let weights = #"{"rows":2,"columns":1,"values":[0,1]}"#
        for json in [
            #"{"classes":["a","b"],"weights":\#(weights),"intercepts":[0],"converged":true}"#,
            #"{"classes":["a","b","c"],"weights":\#(weights),"intercepts":[0,0,0],"converged":true}"#,
            #"{"classes":["a","b"],"weights":{"rows":2,"columns":1,"values":[0,1e999]},"intercepts":[0,0],"converged":true}"#,
        ] {
            #expect(throws: (any Error).self) { try JSONDecoder().decode(LogisticRegression<String>.self, from: Data(json.utf8)) }
        }
    }
}
