import Foundation

/// A fully connected layer: `outputs = weights · inputs + biases`.
struct DenseLayer: Sendable, Equatable, Codable {
    /// One row per output, one column per input.
    var weights: Matrix
    var biases: [Double]
}

/// A multilayer perceptron with ReLU hidden layers and a linear output layer.
struct Perceptron: Sendable, Equatable {
    var layers: [DenseLayer]

    var inputCount: Int { layers[0].weights.columns }
    var outputCount: Int { layers[layers.count - 1].weights.rows }

    /// The activations of every layer, starting with the input.
    func activations(_ input: [Double]) -> [[Double]] {
        var result = [input]
        for (index, layer) in layers.enumerated() {
            let previous = result[result.count - 1]
            let isHidden = index < layers.count - 1
            let weights = layer.weights.values
            let columns = layer.weights.columns
            result.append((0..<layer.weights.rows).map { output in
                var sum = layer.biases[output]
                for input in 0..<columns {
                    sum += weights[output * columns + input] * previous[input]
                }
                return isHidden ? max(sum, 0) : sum
            })
        }
        return result
    }

    func output(_ input: [Double]) -> [Double] {
        activations(input)[layers.count]
    }

    /// Checks the layers of a network read from a file: consecutive sizes fit together and every
    /// value is finite.
    init(validating layers: [DenseLayer], inputCount: Int?, outputCount: Int) throws {
        try requireConsistent(!layers.isEmpty, "the network has no layers")
        for (index, layer) in layers.enumerated() {
            try requireConsistent(layer.weights.rows > 0 && layer.weights.columns > 0, "layer \(index) is empty")
            try requireConsistent(layer.biases.count == layer.weights.rows, "layer \(index) needs one bias per output")
            try requireFinite(layer.weights.values + layer.biases, "layer \(index)")
            if index > 0 {
                try requireConsistent(
                    layer.weights.columns == layers[index - 1].weights.rows,
                    "layer \(index) expects \(layer.weights.columns) inputs, but the previous layer has \(layers[index - 1].weights.rows) outputs"
                )
            }
        }
        if let inputCount {
            try requireConsistent(layers[0].weights.columns == inputCount, "the network expects a different number of features")
        }
        try requireConsistent(layers[layers.count - 1].weights.rows == outputCount, "the network has the wrong number of outputs")
        self.layers = layers
    }

    init(layers: [DenseLayer]) {
        self.layers = layers
    }
}

/// How the network's outputs are compared with the targets.
enum PerceptronLoss {
    /// Softmax over the outputs and cross-entropy with one-hot targets.
    case crossEntropy
    /// Half the squared difference between output and target.
    case squaredError
}

/// The settings shared by the neural network classifier and regressor.
struct PerceptronSettings {
    var hiddenLayers: [Int]
    var learningRate: Double
    var epochs: Int
    var batchSize: Int
    var regularization: Double
    var seed: UInt64

    /// Training stops early when the loss has not improved by `tolerance` for `patience` epochs.
    let tolerance = 1e-4
    let patience = 10

    func validate() throws {
        guard !hiddenLayers.isEmpty, hiddenLayers.allSatisfy({ $0 > 0 }) else {
            throw SwiftAIError.invalidParameter(name: "hiddenLayers", reason: "needs at least one layer and every size greater than 0, got \(hiddenLayers)")
        }
        try requirePositive(learningRate, "learningRate")
        try requirePositive(epochs, "epochs")
        try requirePositive(batchSize, "batchSize")
        try requireNonNegative(regularization, "regularization")
    }
}

/// The result of training: the network and the training loss after each epoch.
struct TrainedPerceptron {
    let network: Perceptron
    let lossCurve: [Double]
}

/// Trains a perceptron with mini-batch Adam, like scikit-learn's MLPClassifier and MLPRegressor.
///
/// Weights start uniformly in ±sqrt(6 / (fan-in + fan-out)). The L2 penalty
/// `regularization / (2n) · ‖W‖²` applies to weights, not biases. Every loop is bounded by
/// `epochs`.
///
/// - Throws: ``SwiftAIError/invalidParameter(name:reason:)`` when the layer sizes need more
///   parameters than an `Int` can count, or when the loss stops being finite (training diverged).
func trainPerceptron(
    features: Matrix, targets: [[Double]], loss: PerceptronLoss, settings: PerceptronSettings
) throws -> TrainedPerceptron {
    var generator = SeededGenerator(seed: settings.seed)
    let sizes = [features.columns] + settings.hiddenLayers + [targets[0].count]
    var parameterCount = 0
    for index in 1..<sizes.count {
        guard let weights = checkedProduct(sizes[index - 1] + 1, sizes[index]),
              case (let total, false) = parameterCount.addingReportingOverflow(weights) else {
            throw SwiftAIError.invalidParameter(name: "hiddenLayers", reason: "the network would have too many parameters")
        }
        parameterCount = total
    }
    var network = Perceptron(layers: (1..<sizes.count).map { index in
        let bound = (6 / Double(sizes[index - 1] + sizes[index])).squareRoot()
        let draw = { (_: Int) in (generator.nextUnitInterval() * 2 - 1) * bound }
        let weights = Matrix(rows: sizes[index], columns: sizes[index - 1], values: (0..<(sizes[index] * sizes[index - 1])).map(draw))
        return DenseLayer(weights: weights, biases: (0..<sizes[index]).map(draw))
    })

    var optimizer = AdamState(layers: network.layers, learningRate: settings.learningRate)
    let sampleCount = features.rows
    let batchSize = min(settings.batchSize, sampleCount)
    var lossCurve: [Double] = []
    var bestLoss = Double.infinity
    var epochsWithoutImprovement = 0

    for _ in 0..<settings.epochs {
        let order = generator.permutation(of: sampleCount)
        var epochLoss = 0.0
        for start in stride(from: 0, to: sampleCount, by: batchSize) {
            let batch = order[start..<min(start + batchSize, sampleCount)]
            // One flat array per layer: the weight gradients row by row, then the bias gradients.
            var gradients = network.layers.map { [Double](repeating: 0, count: $0.weights.values.count + $0.biases.count) }
            for sample in batch {
                epochLoss += backpropagate(network, features.row(sample), targets[sample], loss, into: &gradients)
            }
            let scale = 1 / Double(batch.count)
            for index in gradients.indices {
                let weights = network.layers[index].weights.values
                for component in gradients[index].indices {
                    let penalty = component < weights.count ? settings.regularization * weights[component] : 0
                    gradients[index][component] = (gradients[index][component] + penalty) * scale
                }
            }
            optimizer.step(&network.layers, gradients)
        }
        let weightNorm = network.layers.reduce(0) { $0 + dot($1.weights.values, $1.weights.values) }
        let meanLoss = (epochLoss + settings.regularization / 2 * weightNorm) / Double(sampleCount)
        guard meanLoss.isFinite, network.layers.allSatisfy({ $0.weights.values.allSatisfy(\.isFinite) }) else {
            throw SwiftAIError.invalidParameter(
                name: "learningRate", reason: "training diverged; lower the learning rate or scale the features"
            )
        }
        lossCurve.append(meanLoss)
        if meanLoss > bestLoss - settings.tolerance {
            epochsWithoutImprovement += 1
            if epochsWithoutImprovement > settings.patience { break }
        } else {
            epochsWithoutImprovement = 0
        }
        bestLoss = min(bestLoss, meanLoss)
    }
    return TrainedPerceptron(network: network, lossCurve: lossCurve)
}

/// Adds one sample's gradients to `gradients` and returns its loss.
private func backpropagate(
    _ network: Perceptron, _ input: [Double], _ target: [Double], _ loss: PerceptronLoss, into gradients: inout [[Double]]
) -> Double {
    let activations = network.activations(input)
    let output = activations[network.layers.count]
    var delta: [Double]
    let sampleLoss: Double
    switch loss {
    case .crossEntropy:
        let largest = output.max()!
        let logNormalizer = largest + log(output.reduce(0) { $0 + exp($1 - largest) })
        delta = zip(output, target).map { exp($0 - logNormalizer) - $1 }
        sampleLoss = zip(output, target).reduce(0) { $0 - $1.1 * ($1.0 - logNormalizer) }
    case .squaredError:
        delta = zip(output, target).map { $0 - $1 }
        sampleLoss = delta.reduce(0) { $0 + $1 * $1 } / 2
    }
    for index in stride(from: network.layers.count - 1, through: 0, by: -1) {
        let layer = network.layers[index]
        let weights = layer.weights.values
        let rows = layer.weights.rows
        let columns = layer.weights.columns
        let previous = activations[index]
        for output in 0..<rows where delta[output] != 0 {
            for input in 0..<columns {
                gradients[index][output * columns + input] += delta[output] * previous[input]
            }
            gradients[index][weights.count + output] += delta[output]
        }
        guard index > 0 else { break }
        delta = (0..<columns).map { input in
            guard previous[input] > 0 else { return 0 }
            var sum = 0.0
            for output in 0..<rows {
                sum += weights[output * columns + input] * delta[output]
            }
            return sum
        }
    }
    return sampleLoss
}

/// The moment estimates of the Adam optimizer (β1 = 0.9, β2 = 0.999, ε = 1e-8).
private struct AdamState {
    let learningRate: Double
    var firstMoments: [[Double]]
    var secondMoments: [[Double]]
    var step = 0

    init(layers: [DenseLayer], learningRate: Double) {
        self.learningRate = learningRate
        let zeros = layers.map { [Double](repeating: 0, count: $0.weights.values.count + $0.biases.count) }
        firstMoments = zeros
        secondMoments = zeros
    }

    mutating func step(_ layers: inout [DenseLayer], _ gradients: [[Double]]) {
        step += 1
        let correction = (1 - pow(0.999, Double(step))).squareRoot() / (1 - pow(0.9, Double(step)))
        for index in layers.indices {
            let gradient = gradients[index]
            var parameters = layers[index].weights.values + layers[index].biases
            for component in parameters.indices {
                firstMoments[index][component] = 0.9 * firstMoments[index][component] + 0.1 * gradient[component]
                secondMoments[index][component] = 0.999 * secondMoments[index][component] + 0.001 * gradient[component] * gradient[component]
                parameters[component] -= learningRate * correction * firstMoments[index][component]
                    / (secondMoments[index][component].squareRoot() + 1e-8)
            }
            let weightCount = layers[index].weights.values.count
            layers[index].weights = Matrix(
                rows: layers[index].weights.rows, columns: layers[index].weights.columns,
                values: Array(parameters[..<weightCount])
            )
            layers[index].biases = Array(parameters[weightCount...])
        }
    }
}
