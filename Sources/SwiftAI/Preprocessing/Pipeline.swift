/// A preprocessing step and a model that always run together.
///
/// A pipeline fits the transformer on the training data, trains the model on the transformed
/// data, and transforms every later sample the same way before predicting. That keeps test data
/// out of the transformer's statistics and makes it impossible to forget the scaling in the app.
///
/// ```swift
/// let model = try Pipeline.fit(training, transformer: StandardScaler.fit) { scaled in
///     try KNearestNeighborsClassifier.fit(scaled, k: 5)
/// }
/// let species = try model.predict([5.9, 3.0, 4.2, 1.5])   // raw, unscaled values
/// ```
///
/// A pipeline is a ``Classifier`` or ``Regressor`` when its model is, and `Codable` when both
/// parts are.
public struct Pipeline<Transformer: FeatureTransformer, Model: Sendable>: Sendable {
    /// The fitted preprocessing step.
    public let transformer: Transformer
    /// The model trained on transformed samples.
    public let model: Model

    /// Fits `transformer` on the features of `data`, then `model` on the transformed data.
    ///
    /// - Parameters:
    ///   - data: The training data.
    ///   - transformer: Fits the preprocessing step, for example `StandardScaler.fit`.
    ///   - model: Trains the model on the transformed data.
    public static func fit<Target>(
        _ data: Dataset<Target>,
        transformer makeTransformer: (Matrix) throws -> Transformer,
        model makeModel: (Dataset<Target>) throws -> Model
    ) throws -> Pipeline {
        let transformer = try makeTransformer(data.features)
        let model = try makeModel(transformer.transform(data))
        return Pipeline(transformer: transformer, model: model)
    }

    init(transformer: Transformer, model: Model) {
        self.transformer = transformer
        self.model = model
    }

    /// The number of raw features each sample must have.
    public var featureCount: Int { transformer.inputFeatureCount }
}

extension Pipeline: Classifier where Model: Classifier {
    public var classes: [Model.Label] { model.classes }

    public func predict(_ sample: [Double]) throws -> Model.Label {
        try model.predict(transformer.transform(sample))
    }
}

extension Pipeline: ProbabilisticClassifier where Model: ProbabilisticClassifier {
    public func classProbabilities(_ sample: [Double]) throws -> [Double] {
        try model.classProbabilities(transformer.transform(sample))
    }
}

extension Pipeline: Regressor where Model: Regressor {
    public func predict(_ sample: [Double]) throws -> Double {
        try model.predict(transformer.transform(sample))
    }
}

extension Pipeline: Equatable where Transformer: Equatable, Model: Equatable {}

extension Pipeline: Codable where Transformer: Codable, Model: Codable {
    private enum CodingKeys: String, CodingKey {
        case transformer, model
    }

    /// Decodes both parts and checks that they fit together.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let transformer = try container.decode(Transformer.self, forKey: .transformer)
        let model = try container.decode(Model.self, forKey: .model)
        if let expected = modelFeatureCount(model) {
            try requireConsistent(
                expected == transformer.outputFeatureCount,
                "the transformer produces \(transformer.outputFeatureCount) features but the model expects \(expected)"
            )
        }
        self.init(transformer: transformer, model: model)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(transformer, forKey: .transformer)
        try container.encode(model, forKey: .model)
    }
}

/// The feature count of a model, if it is a classifier, regressor or transformer.
private func modelFeatureCount(_ model: Any) -> Int? {
    switch model {
    case let classifier as any Classifier: classifier.featureCount
    case let regressor as any Regressor: regressor.featureCount
    case let transformer as any FeatureTransformer: transformer.inputFeatureCount
    default: nil
    }
}
