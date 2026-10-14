import Foundation
import Testing
@testable import SwiftAI

@Suite("NeuralNetwork")
struct NeuralNetworkTests {
    @Test("Learns XOR, which no linear model can represent")
    func xor() throws {
        let data = try Dataset(features: [[0, 0], [0, 1], [1, 0], [1, 1]], targets: ["off", "on", "on", "off"])
        let model = try NeuralNetworkClassifier.fit(data, hiddenLayers: [8], learningRate: 0.05, epochs: 1000, seed: 3)
        #expect(try model.predict(data.features) == data.targets)
        #expect(model.hiddenLayers == [8])
        #expect(model.lossCurve.last! < model.lossCurve.first!)
    }

    @Test("Classifies held-out iris samples behind a scaler")
    func iris() throws {
        let (training, test) = try Dataset.iris.stratifiedSplit(testFraction: 0.3, seed: 5)
        let model = try Pipeline.fit(training, transformer: StandardScaler.fit) { scaled in
            try NeuralNetworkClassifier.fit(scaled, hiddenLayers: [16], learningRate: 0.01, epochs: 300, seed: 1)
        }
        #expect(try model.accuracy(on: test) >= 0.9)
        let probabilities = try model.classProbabilities(test.features.row(0))
        #expect(abs(probabilities.reduce(0, +) - 1) < 1e-12)
    }

    @Test("Fits a smooth curve with a regression network")
    func regression() throws {
        let training = try noisySine(count: 200, seed: 1)
        let test = try noisySine(count: 100, seed: 2)
        let model = try NeuralNetworkRegressor.fit(training, hiddenLayers: [16, 16], learningRate: 0.02, epochs: 300, batchSize: 32, seed: 2)
        #expect(model.hiddenLayers == [16, 16])
        #expect(try model.r2Score(on: test) > 0.9)
    }

    @Test("Stops early once the loss stops improving, and the same seed gives the same network")
    func earlyStoppingAndSeeds() throws {
        let data = try Dataset(features: [[0], [1], [2], [3]], targets: ["a", "a", "b", "b"])
        let first = try NeuralNetworkClassifier.fit(data, hiddenLayers: [4], learningRate: 0.1, epochs: 5000, seed: 7)
        #expect(first.lossCurve.count < 5000)
        let second = try NeuralNetworkClassifier.fit(data, hiddenLayers: [4], learningRate: 0.1, epochs: 5000, seed: 7)
        #expect(first == second)
    }

    @Test("Rejects invalid settings, one class, oversized layers and diverging training")
    func invalidInput() throws {
        let data = try Dataset(features: [[0], [1]], targets: ["a", "b"])
        #expect(throws: SwiftAIError.self) { try NeuralNetworkClassifier.fit(data, hiddenLayers: []) }
        #expect(throws: SwiftAIError.self) { try NeuralNetworkClassifier.fit(data, hiddenLayers: [4, 0]) }
        #expect(throws: SwiftAIError.self) { try NeuralNetworkClassifier.fit(data, learningRate: 0) }
        #expect(throws: SwiftAIError.self) { try NeuralNetworkClassifier.fit(data, epochs: 0) }
        #expect(throws: SwiftAIError.self) { try NeuralNetworkClassifier.fit(data, batchSize: 0) }
        #expect(throws: SwiftAIError.self) { try NeuralNetworkClassifier.fit(data, regularization: -1) }
        #expect(throws: SwiftAIError.singleClass) {
            try NeuralNetworkClassifier.fit(Dataset(features: [[0], [1]], targets: ["a", "a"]))
        }
        // The parameter count of these layers does not fit in an Int; this must throw, not trap.
        #expect(throws: SwiftAIError.self) { try NeuralNetworkClassifier.fit(data, hiddenLayers: [Int.max / 2, Int.max / 2]) }
        let huge = try Dataset(features: [[1e200], [-1e200], [3e200]], targets: [1e200, -1e200, 2e200])
        #expect(throws: SwiftAIError.self) { try NeuralNetworkRegressor.fit(huge, hiddenLayers: [4], learningRate: 1) }
    }

    @Test("Round-trips through JSON and rejects layers that do not fit together")
    func codable() throws {
        let data = try Dataset(features: [[0, 1], [1, 0], [1, 1]], targets: ["a", "b", "a"])
        let model = try NeuralNetworkClassifier.fit(data, hiddenLayers: [3], epochs: 5)
        let decoded = try JSONDecoder().decode(NeuralNetworkClassifier<String>.self, from: JSONEncoder().encode(model))
        #expect(decoded == model)
        let regressor = try NeuralNetworkRegressor.fit(noisySine(count: 10, seed: 1), hiddenLayers: [2], epochs: 3)
        #expect(try JSONDecoder().decode(NeuralNetworkRegressor.self, from: JSONEncoder().encode(regressor)) == regressor)

        func layer(_ rows: Int, _ columns: Int, biases: Int? = nil) -> String {
            let values = [String](repeating: "0.5", count: rows * columns).joined(separator: ",")
            let bias = [String](repeating: "0", count: biases ?? rows).joined(separator: ",")
            return #"{"weights":{"rows":\#(rows),"columns":\#(columns),"values":[\#(values)]},"biases":[\#(bias)]}"#
        }
        for layers in [
            [layer(3, 2), layer(1, 4)],          // the second layer expects 4 inputs, the first gives 3
            [layer(3, 2), layer(2, 3)],          // two outputs for a regressor
            [layer(1, 2, biases: 2)],            // one output but two biases
            [],
        ] {
            let json = #"{"layers":[\#(layers.joined(separator: ","))],"lossCurve":[]}"#
            #expect(throws: SwiftAIError.self) { try JSONDecoder().decode(NeuralNetworkRegressor.self, from: Data(json.utf8)) }
        }
    }
}
