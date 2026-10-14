/// A trained model that assigns one of a fixed set of labels to a sample.
///
/// Every classifier in SwiftAI is created by a static `fit` function and is immutable afterwards,
/// so a value of a classifier type is always ready to predict.
public protocol Classifier<Label>: Sendable {
    /// The type of the labels, for example `String`.
    associatedtype Label: Hashable & Sendable

    /// The number of features the model was trained on; every sample must have this many.
    var featureCount: Int { get }

    /// The labels seen during training, in order of first appearance.
    var classes: [Label] { get }

    /// Predicts the label of one sample.
    ///
    /// - Throws: ``SwiftAIError/featureCountMismatch(expected:actual:)`` or
    ///   ``SwiftAIError/nonFiniteValue(row:column:)`` for an invalid sample.
    func predict(_ sample: [Double]) throws -> Label
}

/// A classifier that can also say how likely each label is.
public protocol ProbabilisticClassifier<Label>: Classifier {
    /// The probability of each label in ``Classifier/classes``, in the same order. The values add up to 1.
    func classProbabilities(_ sample: [Double]) throws -> [Double]
}

/// A trained model that predicts a number for a sample.
public protocol Regressor: Sendable {
    /// The number of features the model was trained on; every sample must have this many.
    var featureCount: Int { get }

    /// Predicts the target value of one sample.
    ///
    /// - Throws: ``SwiftAIError/featureCountMismatch(expected:actual:)`` or
    ///   ``SwiftAIError/nonFiniteValue(row:column:)`` for an invalid sample.
    func predict(_ sample: [Double]) throws -> Double
}

extension Classifier {
    /// Predicts the label of every row.
    public func predict(_ features: Matrix) throws -> [Label] {
        try checkFeatures(features, featureCount: featureCount)
        return try (0..<features.rows).map { try predict(features.row($0)) }
    }

    /// Predicts the label of every sample.
    public func predict(_ samples: [[Double]]) throws -> [Label] {
        try predict(Matrix(samples))
    }

    /// The share of samples in `data` whose label the model predicts correctly, from 0 to 1.
    public func accuracy(on data: Dataset<Label>) throws -> Double {
        try Metrics.accuracy(actual: data.targets, predicted: predict(data.features))
    }

    /// Accuracy, per-class precision, recall and F1 score, and the confusion matrix on `data`.
    public func evaluate(on data: Dataset<Label>) throws -> ClassificationReport<Label> {
        try ClassificationReport(actual: data.targets, predicted: predict(data.features), classes: classes)
    }
}

extension ProbabilisticClassifier {
    /// The probability of each label for one sample.
    ///
    /// ```swift
    /// let odds = try model.probabilities([5.9, 3.0, 4.2, 1.5])
    /// odds["versicolor"]   // for example 0.93
    /// ```
    public func probabilities(_ sample: [Double]) throws -> [Label: Double] {
        let values = try classProbabilities(sample)
        return Dictionary(uniqueKeysWithValues: zip(classes, values))
    }
}

extension Regressor {
    /// Predicts the target value of every row.
    public func predict(_ features: Matrix) throws -> [Double] {
        try checkFeatures(features, featureCount: featureCount)
        return try (0..<features.rows).map { try predict(features.row($0)) }
    }

    /// Predicts the target value of every sample.
    public func predict(_ samples: [[Double]]) throws -> [Double] {
        try predict(Matrix(samples))
    }

    /// The coefficient of determination (R²) on `data`: 1 is a perfect fit, 0 is no better than
    /// always predicting the mean.
    public func r2Score(on data: Dataset<Double>) throws -> Double {
        try Metrics.r2Score(actual: data.targets, predicted: predict(data.features))
    }

    /// Error measures of the model's predictions on `data`.
    public func evaluate(on data: Dataset<Double>) throws -> RegressionReport {
        try RegressionReport(actual: data.targets, predicted: predict(data.features))
    }
}

/// Maps labels to the indices `0..<classes.count` that models compute with.
struct ClassIndex<Label: Hashable>: Sendable where Label: Sendable {
    let classes: [Label]
    private let positions: [Label: Int]

    /// Classes in order of first appearance in `targets`.
    init(_ targets: [Label]) {
        var classes: [Label] = []
        var positions: [Label: Int] = [:]
        for target in targets where positions[target] == nil {
            positions[target] = classes.count
            classes.append(target)
        }
        self.classes = classes
        self.positions = positions
    }

    init(classes: [Label]) {
        self.classes = classes
        self.positions = Dictionary(uniqueKeysWithValues: classes.enumerated().map { ($1, $0) })
    }

    func index(of label: Label) -> Int? {
        positions[label]
    }

    /// Indices of `targets`, which must all be known classes.
    func encode(_ targets: [Label]) -> [Int] {
        targets.map { positions[$0]! }
    }
}

/// Index of the largest value; the first one wins a tie.
func argmax(_ values: [Double]) -> Int {
    var best = 0
    for index in values.indices where values[index] > values[best] {
        best = index
    }
    return best
}
