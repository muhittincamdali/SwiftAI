import Foundation
import Testing
@testable import SwiftAI

@Suite("LinearRegression")
struct LinearRegressionTests {
    let data = try! Dataset(
        features: [[1, 2], [2, 1], [3, 4], [4, 3], [5, 5]],
        targets: [3.1, 2.9, 7.2, 6.8, 10.1]
    )

    // Reference values from scikit-learn 1.9.1 LinearRegression and Ridge(alpha=1.0).
    @Test("Ordinary least squares matches scikit-learn")
    func ordinaryLeastSquares() throws {
        let model = try LinearRegression.fit(data)
        #expect(abs(model.coefficients[0] - 0.8611111111111095) < 1e-10)
        #expect(abs(model.coefficients[1] - 1.1611111111111112) < 1e-10)
        #expect(abs(model.intercept - -0.04666666666666153) < 1e-10)
        #expect(abs(try model.predict([2.5, 3.5]) - 6.17) < 1e-10)
    }

    @Test("Ridge regression matches scikit-learn and does not penalize the intercept")
    func ridge() throws {
        let model = try LinearRegression.fit(data, regularization: 1)
        #expect(abs(model.coefficients[0] - 0.8578947368421049) < 1e-10)
        #expect(abs(model.coefficients[1] - 1.0578947368421054) < 1e-10)
        #expect(abs(model.intercept - 0.27263157894736967) < 1e-10)
    }

    @Test("Recovers an exact linear relation, also with features in very different units")
    func exactRelation() throws {
        let rows = (0..<20).map { index -> [Double] in
            let value = Double(index)
            return [value * 1e6, (value * value).truncatingRemainder(dividingBy: 7) * 1e-6]
        }
        let targets = rows.map { 3e-6 * $0[0] - 2e5 * $0[1] + 4 }
        let model = try LinearRegression.fit(Dataset(features: rows, targets: targets))
        #expect(abs(model.coefficients[0] - 3e-6) < 1e-15)
        #expect(abs(model.coefficients[1] - -2e5) < 1e-4)
        #expect(abs(model.intercept - 4) < 1e-9)
        #expect(try model.r2Score(on: Dataset(features: rows, targets: targets)) > 0.999_999_999)
    }

    @Test("Duplicated or constant features make the system singular unless regularized")
    func singular() throws {
        let duplicated = try Dataset(features: [[1, 2], [2, 4], [3, 6], [4, 8]], targets: [1.0, 2, 3, 4])
        #expect(throws: SwiftAIError.singularMatrix) { try LinearRegression.fit(duplicated) }
        let constant = try Dataset(features: [[1, 5], [2, 5], [3, 5]], targets: [1.0, 2, 3])
        #expect(throws: SwiftAIError.singularMatrix) { try LinearRegression.fit(constant) }
        let tooFew = try Dataset(features: [[1, 2, 3], [4, 5, 7]], targets: [1.0, 2])
        #expect(throws: SwiftAIError.singularMatrix) { try LinearRegression.fit(tooFew) }

        let ridge = try LinearRegression.fit(duplicated, regularization: 0.1)
        #expect(abs(ridge.coefficients[1] - 2 * ridge.coefficients[0]) < 1e-12)
    }

    @Test("Rejects NaN targets, negative penalties and wrong samples")
    func invalidInput() throws {
        let nanTarget = try Dataset(features: [[1], [2]], targets: [1, .nan])
        #expect(throws: SwiftAIError.nonFiniteTarget(row: 1)) { try LinearRegression.fit(nanTarget) }
        #expect(throws: SwiftAIError.self) { try LinearRegression.fit(data, regularization: -1) }
        #expect(throws: SwiftAIError.self) { try LinearRegression.fit(data, regularization: .nan) }
        let model = try LinearRegression.fit(data)
        #expect(throws: SwiftAIError.featureCountMismatch(expected: 2, actual: 3)) { try model.predict([1, 2, 3]) }
    }

    @Test("Targets whose sum overflows and predictions that overflow throw")
    func overflow() throws {
        let huge = Double.greatestFiniteMagnitude
        let hugeTargets = try Dataset(features: [[1], [2]], targets: [huge, huge])
        #expect(throws: SwiftAIError.self) { try LinearRegression.fit(hugeTargets) }
        let model = try LinearRegression.fit(data)
        #expect(throws: SwiftAIError.self) { try model.predict([huge, huge]) }
    }

    @Test("Round-trips through JSON and rejects corrupt files")
    func codable() throws {
        let model = try LinearRegression.fit(data, regularization: 0.5)
        let decoded = try JSONDecoder().decode(LinearRegression.self, from: JSONEncoder().encode(model))
        #expect(decoded == model)
        for json in [
            #"{"coefficients":[],"intercept":0,"regularization":0}"#,
            #"{"coefficients":[1],"intercept":0,"regularization":-1}"#,
        ] {
            #expect(throws: SwiftAIError.self) { try JSONDecoder().decode(LinearRegression.self, from: Data(json.utf8)) }
        }
    }
}
