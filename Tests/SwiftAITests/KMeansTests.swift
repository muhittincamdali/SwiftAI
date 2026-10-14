import Foundation
import Testing
@testable import SwiftAI

@Suite("KMeans")
struct KMeansTests {
    @Test("Finds the same three iris clusters and inertia as scikit-learn")
    func iris() throws {
        let clusters = try KMeans.fit(Dataset.iris, clusterCount: 3, restarts: 10, seed: 0)
        // scikit-learn 1.9.1 KMeans(3, n_init=10, random_state=0): inertia 78.851441426146.
        #expect(abs(clusters.inertia - 78.851441426146) < 1e-6)
        let expected: [[Double]] = [[5.006, 3.428, 1.462, 0.246], [5.9016, 2.7484, 4.3935, 1.4339], [6.85, 3.0737, 5.7421, 2.0711]]
        let found = clusters.centroids.rowArrays.sorted { $0[0] < $1[0] }
        for (centroid, reference) in zip(found, expected) {
            expectClose(centroid, reference, tolerance: 1e-4)
        }
        // Every setosa sample falls into the same cluster.
        let setosa = try clusters.predict(Dataset.iris.features).prefix(50)
        #expect(Set(setosa).count == 1)
    }

    @Test("Separates well-apart groups exactly and assigns new samples to the nearest centroid")
    func blobs() throws {
        let features: Matrix = [[0, 0], [0, 1], [1, 0], [10, 10], [10, 11], [11, 10]]
        let clusters = try KMeans.fit(features, clusterCount: 2, seed: 5)
        let labels = try clusters.predict(features)
        #expect(labels[0] == labels[1] && labels[1] == labels[2])
        #expect(labels[3] == labels[4] && labels[4] == labels[5])
        #expect(labels[0] != labels[3])
        #expect(try clusters.predict([9, 9]) == labels[3])
        #expect(abs(clusters.inertia - 8.0 / 3) < 1e-12)
    }

    @Test("One cluster is the mean of all samples")
    func singleCluster() throws {
        let clusters = try KMeans.fit([[1, 2], [3, 4], [5, 9]] as Matrix, clusterCount: 1)
        #expect(clusters.centroids.row(0) == [3, 5])
    }

    @Test("The same seed gives the same clusters")
    func deterministic() throws {
        let first = try KMeans.fit(Dataset.iris, clusterCount: 4, seed: 11)
        let second = try KMeans.fit(Dataset.iris, clusterCount: 4, seed: 11)
        #expect(first == second)
    }

    @Test("Rejects invalid settings, too few distinct samples and values too large to compute with")
    func invalidInput() throws {
        let features: Matrix = [[1, 1], [1, 1], [2, 2]]
        #expect(throws: SwiftAIError.self) { try KMeans.fit(features, clusterCount: 0) }
        #expect(throws: SwiftAIError.insufficientSamples(required: 4, actual: 3)) { try KMeans.fit(features, clusterCount: 4) }
        #expect(throws: SwiftAIError.self) { try KMeans.fit(features, clusterCount: 3) }
        #expect(throws: SwiftAIError.self) { try KMeans.fit(features, clusterCount: 2, restarts: 0) }
        #expect(throws: SwiftAIError.self) { try KMeans.fit(features, clusterCount: 2, tolerance: -1) }
        #expect(throws: SwiftAIError.emptyDataset) { try KMeans.fit(Matrix(rows: 0, columns: 2), clusterCount: 1) }
        let huge: Matrix = [[-1e308, 0], [1e308, 0]]
        #expect(throws: SwiftAIError.self) { try KMeans.fit(huge, clusterCount: 2) }
        let clusters = try KMeans.fit(features, clusterCount: 2)
        #expect(throws: SwiftAIError.self) { try clusters.predict([1e300, 1e300]) }
        #expect(throws: SwiftAIError.featureCountMismatch(expected: 2, actual: 1)) { try clusters.predict([1]) }
    }

    @Test("Round-trips through JSON and rejects corrupt files")
    func codable() throws {
        let clusters = try KMeans.fit(Dataset.iris, clusterCount: 3)
        #expect(try JSONDecoder().decode(KMeans.self, from: JSONEncoder().encode(clusters)) == clusters)
        for json in [
            #"{"centroids":{"rows":0,"columns":0,"values":[]},"inertia":0,"iterations":1}"#,
            #"{"centroids":{"rows":1,"columns":1,"values":[1]},"inertia":-1,"iterations":1}"#,
        ] {
            #expect(throws: SwiftAIError.self) { try JSONDecoder().decode(KMeans.self, from: Data(json.utf8)) }
        }
    }
}
