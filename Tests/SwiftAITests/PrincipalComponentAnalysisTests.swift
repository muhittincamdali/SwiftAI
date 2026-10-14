import Foundation
import Testing
@testable import SwiftAI

@Suite("PrincipalComponentAnalysis")
struct PrincipalComponentAnalysisTests {
    // Reference values from scikit-learn 1.9.1 PCA(n_components=2) on iris.
    @Test("Components, variances and projections match scikit-learn on iris")
    func iris() throws {
        let pca = try PrincipalComponentAnalysis.fit(Dataset.iris, componentCount: 2)
        expectClose(pca.components.row(0), [0.3613865917853659, -0.08452251406457255, 0.8566706059498348, 0.35828919715155183], tolerance: 1e-10)
        expectClose(pca.components.row(1), [0.6565887712868537, 0.7301614347850159, -0.17337266279585964, -0.0754810199174582], tolerance: 1e-10)
        expectClose(pca.explainedVariance, [4.228241706034831, 0.24267074792862006], tolerance: 1e-10)
        expectClose(pca.explainedVarianceRatio, [0.9246187232017291, 0.05306648311706544], tolerance: 1e-10)
        expectClose(try pca.transform([5.9, 3.0, 4.2, 1.5]), [0.5116985574475974, -0.10398123549903904], tolerance: 1e-10)
    }

    @Test("Keeping every component makes the transform invertible and orthonormal")
    func fullRank() throws {
        let pca = try PrincipalComponentAnalysis.fit(Dataset.iris)
        #expect(abs(pca.explainedVarianceRatio.reduce(0, +) - 1) < 1e-12)
        let product = pca.components * pca.components.transposed()
        expectClose(product.values, Matrix.identity(4).values, tolerance: 1e-12)
        let sample: [Double] = [6.1, 2.9, 4.7, 1.4]
        expectClose(try pca.inverseTransform(pca.transform(sample)), sample, tolerance: 1e-12)
    }

    @Test("Perfectly correlated features collapse onto one component")
    func correlated() throws {
        let features: Matrix = [[1, 2], [2, 4], [3, 6], [4, 8]]
        let pca = try PrincipalComponentAnalysis.fit(features)
        #expect(abs(pca.explainedVarianceRatio[0] - 1) < 1e-12)
        #expect(abs(pca.explainedVariance[1]) < 1e-12)
        expectClose(pca.components.row(0), [1 / 5.0.squareRoot(), 2 / 5.0.squareRoot()], tolerance: 1e-12)
    }

    @Test("Rejects too few samples, invalid counts and values whose products overflow")
    func invalidInput() throws {
        #expect(throws: SwiftAIError.insufficientSamples(required: 2, actual: 1)) {
            try PrincipalComponentAnalysis.fit([[1, 2]] as Matrix)
        }
        #expect(throws: SwiftAIError.self) { try PrincipalComponentAnalysis.fit(Dataset.iris, componentCount: 5) }
        #expect(throws: SwiftAIError.self) { try PrincipalComponentAnalysis.fit(Dataset.iris, componentCount: 0) }
        #expect(throws: SwiftAIError.self) { try PrincipalComponentAnalysis.fit([[1e200, 0], [-1e200, 1]] as Matrix) }
    }

    @Test("Round-trips through JSON and rejects corrupt files")
    func codable() throws {
        let pca = try PrincipalComponentAnalysis.fit(Dataset.iris, componentCount: 3)
        let decoded = try JSONDecoder().decode(PrincipalComponentAnalysis.self, from: JSONEncoder().encode(pca))
        #expect(decoded == pca)
        let json = #"{"means":[0],"components":{"rows":2,"columns":1,"values":[1,1]},"explainedVariance":[1,1],"explainedVarianceRatio":[1,0]}"#
        #expect(throws: SwiftAIError.self) { try JSONDecoder().decode(PrincipalComponentAnalysis.self, from: Data(json.utf8)) }
    }
}
