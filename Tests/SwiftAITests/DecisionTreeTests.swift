import Foundation
import Testing
@testable import SwiftAI

@Suite("DecisionTree")
struct DecisionTreeTests {
    @Test("A depth-2 iris tree splits on petal length, then petal width, like scikit-learn")
    func irisDepthTwo() throws {
        let tree = try DecisionTreeClassifier.fit(Dataset.iris, maxDepth: 2)
        // Petal length <= 2.45 and petal width <= 0.8 separate setosa equally well; the lower
        // feature index wins. scikit-learn breaks the tie at random, with the same accuracy.
        let root = tree.tree.nodes[0]
        #expect(root.feature == 2 && abs(root.threshold - 2.45) < 1e-12)
        let second = tree.tree.nodes[root.right]
        #expect(second.feature == 3 && abs(second.threshold - 1.75) < 1e-12)
        #expect(tree.depth == 2 && tree.leafCount == 3)
        #expect(try tree.accuracy(on: Dataset.iris) == 0.96)
        #expect(abs(tree.featureImportances.reduce(0, +) - 1) < 1e-12)
        #expect(tree.featureImportances[0] == 0 && tree.featureImportances[1] == 0)
        #expect(try tree.predict([5.0, 3.6, 1.4, 0.2]) == "setosa")
    }

    @Test("An unlimited tree fits the training data exactly")
    func unlimited() throws {
        let tree = try DecisionTreeClassifier.fit(Dataset.iris)
        #expect(try tree.accuracy(on: Dataset.iris) == 1)
        let pure = try tree.classProbabilities([6.3, 2.8, 5.1, 1.5])
        #expect(pure.contains(1))
    }

    @Test("Splits XOR, where no single split reduces the impurity at the root")
    func xor() throws {
        let data = try Dataset(features: [[0, 0], [0, 1], [1, 0], [1, 1]], targets: [0, 1, 1, 0])
        let tree = try DecisionTreeClassifier.fit(data)
        #expect(try tree.predict(data.features) == [0, 1, 1, 0])
        #expect(tree.depth == 2)
    }

    @Test("Leaf size and depth limits are respected")
    func limits() throws {
        let tree = try DecisionTreeClassifier.fit(Dataset.iris, minSamplesLeaf: 20)
        #expect(tree.tree.nodes.filter(\.isLeaf).allSatisfy { $0.sampleCount >= 20 })
        let stump = try DecisionTreeClassifier.fit(Dataset.iris, maxDepth: 0)
        #expect(stump.leafCount == 1)
        #expect(try stump.classProbabilities([5, 3, 1, 0]) == [1.0 / 3, 1.0 / 3, 1.0 / 3])
        let split = try DecisionTreeClassifier.fit(Dataset.iris, minSamplesSplit: 151)
        #expect(split.leafCount == 1)
    }

    @Test("A regression stump matches scikit-learn's threshold and leaf means")
    func regressionStump() throws {
        let data = try Dataset(features: [[1], [2], [3], [4], [5], [6]], targets: [1, 1.2, 0.9, 5, 5.2, 4.8])
        let tree = try DecisionTreeRegressor.fit(data, maxDepth: 1)
        #expect(tree.tree.nodes[0].threshold == 3.5)
        #expect(abs(try tree.predict([2.5]) - 1.0333333333333334) < 1e-12)
        #expect(abs(try tree.predict([4.5]) - 5) < 1e-12)
        #expect(try DecisionTreeRegressor.fit(data).r2Score(on: data) == 1)
    }

    @Test("Thresholds between values near the largest Double do not overflow")
    func hugeValues() throws {
        let huge = Double.greatestFiniteMagnitude
        let data = try Dataset(features: [[huge * 0.9], [huge]], targets: ["a", "b"])
        let tree = try DecisionTreeClassifier.fit(data)
        #expect(tree.tree.nodes[0].threshold.isFinite)
        #expect(try tree.predict([huge]) == "b")
        #expect(midpoint(1, 1.0000000000000002) == 1)
    }

    @Test("Rejects invalid limits and targets too large to compute with")
    func invalidInput() throws {
        #expect(throws: SwiftAIError.self) { try DecisionTreeClassifier.fit(Dataset.iris, maxDepth: -1) }
        #expect(throws: SwiftAIError.self) { try DecisionTreeClassifier.fit(Dataset.iris, minSamplesSplit: 1) }
        #expect(throws: SwiftAIError.self) { try DecisionTreeClassifier.fit(Dataset.iris, minSamplesLeaf: 0) }
        let huge = try Dataset(features: [[0], [1]], targets: [-1e308, 1e308])
        #expect(throws: SwiftAIError.self) { try DecisionTreeRegressor.fit(huge) }
        let nan = try Dataset(features: [[0], [1]], targets: [0, Double.nan])
        #expect(throws: SwiftAIError.nonFiniteTarget(row: 1)) { try DecisionTreeRegressor.fit(nan) }
    }

    @Test("Round-trips through JSON")
    func codable() throws {
        let tree = try DecisionTreeClassifier.fit(Dataset.iris, maxDepth: 3)
        let decoded = try JSONDecoder().decode(DecisionTreeClassifier<String>.self, from: JSONEncoder().encode(tree))
        #expect(decoded == tree)
        let regressor = try DecisionTreeRegressor.fit(Dataset(features: [[1], [2], [3]], targets: [1.0, 2, 3]))
        #expect(try JSONDecoder().decode(DecisionTreeRegressor.self, from: JSONEncoder().encode(regressor)) == regressor)
    }

    // A crafted file must not make prediction loop forever or index out of range.
    @Test("Rejects saved trees with cycles, dangling children or invalid values")
    func corruptTrees() throws {
        func node(_ feature: Int, _ left: Int, _ right: Int, value: String = "[1]", count: Int = 1) -> String {
            #"{"feature":\#(feature),"threshold":0,"left":\#(left),"right":\#(right),"value":\#(value),"impurity":0,"sampleCount":\#(count)}"#
        }
        let leaf = node(-1, -1, -1)
        let cases = [
            [node(0, 0, 1), leaf],          // a node that is its own child
            [leaf, node(0, 0, 0)],          // a split pointing back to the root
            [node(0, 1, 5), leaf],          // a child index past the end
            [node(0, 1, 1), leaf],          // both children the same node
            [node(3, 1, 2), leaf, leaf],    // a feature the model does not have
            [node(-2, -1, -1)],             // an invalid feature index
            [node(-1, -1, -1, value: "[1,2]")],
            [node(-1, -1, -1, count: 0)],
            [],
        ]
        for nodes in cases {
            let json = #"{"featureCount":1,"nodes":[\#(nodes.joined(separator: ","))]}"#
            #expect(throws: SwiftAIError.self) { try JSONDecoder().decode(DecisionTreeRegressor.self, from: Data(json.utf8)) }
        }
        let classifier = #"{"classes":["a","b"],"featureCount":1,"nodes":[\#(leaf)]}"#
        #expect(throws: SwiftAIError.self) {
            try JSONDecoder().decode(DecisionTreeClassifier<String>.self, from: Data(classifier.utf8))
        }
    }
}
