/// A neural network (multilayer perceptron) that classifies samples.
///
/// Hidden layers use ReLU; the output layer has one unit per class and a softmax. Training uses
/// mini-batch Adam on the cross-entropy plus an L2 penalty, the same setup and defaults as
/// scikit-learn's `MLPClassifier`, and stops early when the loss stops improving.
///
/// Neural networks need scaled features: use a ``Pipeline`` with ``StandardScaler``.
///
/// ```swift
/// let model = try Pipeline.fit(training, transformer: StandardScaler.fit) { scaled in
///     try NeuralNetworkClassifier.fit(scaled, hiddenLayers: [16], epochs: 300, seed: 1)
/// }
/// ```
public struct NeuralNetworkClassifier<Label: Hashable & Sendable>: ProbabilisticClassifier {
    public let classes: [Label]
    let network: Perceptron
    /// The mean training loss after each epoch; its length is the number of epochs trained.
    public let lossCurve: [Double]

    public var featureCount: Int { network.inputCount }
    /// The number of units in each hidden layer.
    public var hiddenLayers: [Int] { network.layers.dropLast().map(\.weights.rows) }

    /// Trains the network.
    ///
    /// - Parameters:
    ///   - hiddenLayers: The number of units in each hidden layer, for example `[32, 16]`.
    ///   - learningRate: Adam's step size.
    ///   - epochs: The most passes over the training data.
    ///   - batchSize: Samples per gradient step (all of them if there are fewer).
    ///   - regularization: The L2 penalty on the weights (`alpha` in scikit-learn).
    ///   - seed: Determines the initial weights and the order of samples.
    /// - Throws: ``SwiftAIError/singleClass`` with one label, and
    ///   ``SwiftAIError/invalidParameter(name:reason:)`` for invalid settings or when training diverges.
    public static func fit(
        _ data: Dataset<Label>, hiddenLayers: [Int] = [100], learningRate: Double = 0.001, epochs: Int = 200,
        batchSize: Int = 200, regularization: Double = 0.0001, seed: UInt64 = 0
    ) throws -> NeuralNetworkClassifier {
        let settings = PerceptronSettings(
            hiddenLayers: hiddenLayers, learningRate: learningRate, epochs: epochs,
            batchSize: batchSize, regularization: regularization, seed: seed
        )
        try settings.validate()
        let index = ClassIndex(data.targets)
        guard index.classes.count >= 2 else { throw SwiftAIError.singleClass }
        let oneHot = index.encode(data.targets).map { target in
            (0..<index.classes.count).map { $0 == target ? 1.0 : 0 }
        }
        let trained = try trainPerceptron(features: data.features, targets: oneHot, loss: .crossEntropy, settings: settings)
        return NeuralNetworkClassifier(classes: index.classes, network: trained.network, lossCurve: trained.lossCurve)
    }

    init(classes: [Label], network: Perceptron, lossCurve: [Double]) {
        self.classes = classes
        self.network = network
        self.lossCurve = lossCurve
    }

    public func classProbabilities(_ sample: [Double]) throws -> [Double] {
        try checkSample(sample, featureCount: featureCount)
        return try softmax(network.output(sample))
    }

    public func predict(_ sample: [Double]) throws -> Label {
        classes[argmax(try classProbabilities(sample))]
    }
}

extension NeuralNetworkClassifier: Equatable where Label: Equatable {}

extension NeuralNetworkClassifier: Codable where Label: Codable {
    private enum CodingKeys: String, CodingKey {
        case classes, layers, lossCurve
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let classes = try container.decode([Label].self, forKey: .classes)
        try requireValidClasses(classes)
        try requireConsistent(classes.count >= 2, "a classifier needs at least two classes")
        let network = try Perceptron(
            validating: container.decode([DenseLayer].self, forKey: .layers), inputCount: nil, outputCount: classes.count
        )
        let lossCurve = try container.decode([Double].self, forKey: .lossCurve)
        try requireFinite(lossCurve, "lossCurve")
        self.init(classes: classes, network: network, lossCurve: lossCurve)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(classes, forKey: .classes)
        try container.encode(network.layers, forKey: .layers)
        try container.encode(lossCurve, forKey: .lossCurve)
    }
}

/// A neural network (multilayer perceptron) that predicts a number.
///
/// Like ``NeuralNetworkClassifier``, with one linear output unit and the squared error as the
/// loss (scikit-learn's `MLPRegressor`). Scale the features, and consider scaling the target too.
///
/// ```swift
/// let model = try NeuralNetworkRegressor.fit(scaled, hiddenLayers: [32, 32], learningRate: 0.01)
/// ```
public struct NeuralNetworkRegressor: Regressor, Equatable, Codable {
    let network: Perceptron
    /// The mean training loss after each epoch.
    public let lossCurve: [Double]

    public var featureCount: Int { network.inputCount }
    /// The number of units in each hidden layer.
    public var hiddenLayers: [Int] { network.layers.dropLast().map(\.weights.rows) }

    /// Trains the network.
    ///
    /// - Throws: The errors of ``NeuralNetworkClassifier/fit(_:hiddenLayers:learningRate:epochs:batchSize:regularization:seed:)``
    ///   except ``SwiftAIError/singleClass``, and ``SwiftAIError/nonFiniteTarget(row:)``.
    public static func fit(
        _ data: Dataset<Double>, hiddenLayers: [Int] = [100], learningRate: Double = 0.001, epochs: Int = 200,
        batchSize: Int = 200, regularization: Double = 0.0001, seed: UInt64 = 0
    ) throws -> NeuralNetworkRegressor {
        let settings = PerceptronSettings(
            hiddenLayers: hiddenLayers, learningRate: learningRate, epochs: epochs,
            batchSize: batchSize, regularization: regularization, seed: seed
        )
        try settings.validate()
        try checkFinite(targets: data.targets)
        let trained = try trainPerceptron(
            features: data.features, targets: data.targets.map { [$0] }, loss: .squaredError, settings: settings
        )
        return NeuralNetworkRegressor(network: trained.network, lossCurve: trained.lossCurve)
    }

    init(network: Perceptron, lossCurve: [Double]) {
        self.network = network
        self.lossCurve = lossCurve
    }

    public func predict(_ sample: [Double]) throws -> Double {
        try checkSample(sample, featureCount: featureCount)
        return try finitePrediction(network.output(sample)[0])
    }

    private enum CodingKeys: String, CodingKey {
        case layers, lossCurve
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        network = try Perceptron(validating: container.decode([DenseLayer].self, forKey: .layers), inputCount: nil, outputCount: 1)
        lossCurve = try container.decode([Double].self, forKey: .lossCurve)
        try requireFinite(lossCurve, "lossCurve")
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(network.layers, forKey: .layers)
        try container.encode(lossCurve, forKey: .lossCurve)
    }
}
