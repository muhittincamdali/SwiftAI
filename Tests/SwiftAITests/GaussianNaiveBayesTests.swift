import Foundation
import Testing
@testable import SwiftAI

@Suite("GaussianNaiveBayes")
struct GaussianNaiveBayesTests {
    @Test("Probabilities match scikit-learn's GaussianNB on iris")
    func matchesReference() throws {
        let model = try GaussianNaiveBayes.fit(Dataset.iris)
        #expect(model.classes == ["setosa", "versicolor", "virginica"])
        let third: Double = 1.0 / 3
        #expect(model.priors == [third, third, third])
        expectClose(try model.classProbabilities(irisQueries[0]), [8.39601787104591e-88, 0.996238286308169, 0.0037617136918309912], tolerance: 1e-9)
        expectClose(try model.classProbabilities(irisQueries[1]), [2.6838258262863244e-131, 0.7126451442155292, 0.28735485578447095], tolerance: 1e-9)
        #expect(try model.accuracy(on: Dataset.iris) == 0.96)
    }

    @Test("A feature that is constant within a class does not divide by zero")
    func constantFeature() throws {
        let data = try Dataset(features: [[1, 0], [1, 1], [2, 5], [2, 6]], targets: ["a", "a", "b", "b"])
        let model = try GaussianNaiveBayes.fit(data)
        #expect(model.variances.values.allSatisfy { $0 > 0 })
        #expect(try model.predict([1, 0.5]) == "a")
        let constant = try Dataset(features: [[3], [3]], targets: ["a", "b"])
        expectClose(try GaussianNaiveBayes.fit(constant).classProbabilities([3]), [0.5, 0.5], tolerance: 1e-12)
    }

    @Test("Rejects invalid smoothing and samples whose likelihood underflows for every class")
    func invalidInput() throws {
        #expect(throws: SwiftAIError.self) { try GaussianNaiveBayes.fit(Dataset.iris, varianceSmoothing: 0) }
        let model = try GaussianNaiveBayes.fit(Dataset.iris)
        #expect(throws: SwiftAIError.self) { try model.predict([1e300, 0, 0, 0]) }
        #expect(throws: SwiftAIError.featureCountMismatch(expected: 4, actual: 2)) { try model.predict([1, 2]) }
    }

    @Test("Round-trips through JSON and rejects inconsistent saved models")
    func codable() throws {
        let model = try GaussianNaiveBayes.fit(Dataset.iris)
        let decoded = try JSONDecoder().decode(GaussianNaiveBayes<String>.self, from: JSONEncoder().encode(model))
        #expect(decoded == model)
        let matrix = #"{"rows":2,"columns":1,"values":[0,1]}"#
        for json in [
            #"{"classes":["a","b"],"priors":[0.5,0.5],"means":\#(matrix),"variances":{"rows":2,"columns":1,"values":[1,0]}}"#,
            #"{"classes":["a","b"],"priors":[0.5],"means":\#(matrix),"variances":\#(matrix)}"#,
            #"{"classes":["a","b"],"priors":[0.5,-0.5],"means":\#(matrix),"variances":{"rows":2,"columns":1,"values":[1,1]}}"#,
            #"{"classes":["a"],"priors":[1],"means":\#(matrix),"variances":{"rows":2,"columns":1,"values":[1,1]}}"#,
        ] {
            #expect(throws: (any Error).self) { try JSONDecoder().decode(GaussianNaiveBayes<String>.self, from: Data(json.utf8)) }
        }
    }
}
