import Foundation

/// A linear classifier that predicts class probabilities.
///
/// Each class gets a weighted sum of the features; the softmax of those scores gives the
/// probabilities. With two classes this is binary logistic regression with one weight vector.
/// Training minimizes the cross-entropy plus an L2 penalty with L-BFGS, the same objective as
/// scikit-learn's `LogisticRegression` with `C = 1 / regularization`.
///
/// ```swift
/// let model = try LogisticRegression.fit(training)
/// let odds = try model.probabilities([5.9, 3.0, 4.2, 1.5])
/// ```
///
/// Scaling the features (``StandardScaler``) speeds up training and makes the penalty treat all
/// features alike.
public struct LogisticRegression<Label: Hashable & Sendable>: ProbabilisticClassifier {
    public let classes: [Label]
    /// One row of feature weights per class. For two classes the first row is all zeros and
    /// the second holds the binary model's weights.
    public let weights: Matrix
    /// The constant score of each class.
    public let intercepts: [Double]
    /// Whether the optimizer reached the requested tolerance. If `false`, raise
    /// `maxIterations` or scale the features.
    public let converged: Bool

    public var featureCount: Int { weights.columns }

    /// Trains the model.
    ///
    /// - Parameters:
    ///   - data: Samples with at least two different labels.
    ///   - regularization: Strength of the L2 penalty on the weights, greater than 0. `1` gives
    ///     scikit-learn's default (`C = 1`); smaller values fit the training data more closely.
    ///   - maxIterations: The most optimizer steps.
    ///   - tolerance: Training stops when no gradient component is larger than this.
    /// - Throws: ``SwiftAIError/singleClass`` with only one label, and
    ///   ``SwiftAIError/invalidParameter(name:reason:)`` for invalid settings or features too
    ///   large to compute with.
    public static func fit(
        _ data: Dataset<Label>, regularization: Double = 1, maxIterations: Int = 500, tolerance: Double = 1e-6
    ) throws -> LogisticRegression {
        try requirePositive(regularization, "regularization")
        try requirePositive(maxIterations, "maxIterations")
        try requirePositive(tolerance, "tolerance")
        let index = ClassIndex(data.targets)
        guard index.classes.count >= 2 else { throw SwiftAIError.singleClass }
        let problem = SoftmaxProblem(
            features: data.features, targets: index.encode(data.targets),
            classCount: index.classes.count, regularization: regularization
        )
        let minimum = try minimizeLBFGS(
            start: [Double](repeating: 0, count: problem.parameterCount),
            maxIterations: maxIterations, tolerance: tolerance, objective: problem.evaluate
        )
        let (weights, intercepts) = problem.unpack(minimum.point)
        return LogisticRegression(classes: index.classes, weights: weights, intercepts: intercepts, converged: minimum.converged)
    }

    private init(classes: [Label], weights: Matrix, intercepts: [Double], converged: Bool) {
        self.classes = classes
        self.weights = weights
        self.intercepts = intercepts
        self.converged = converged
    }

    public func classProbabilities(_ sample: [Double]) throws -> [Double] {
        try checkSample(sample, featureCount: featureCount)
        return try softmax(scores(sample))
    }

    public func predict(_ sample: [Double]) throws -> Label {
        classes[argmax(try classProbabilities(sample))]
    }

    func scores(_ sample: [Double]) -> [Double] {
        (0..<classes.count).map { intercepts[$0] + dot(weights.row($0), sample) }
    }
}

extension LogisticRegression: Equatable where Label: Equatable {}

extension LogisticRegression: Codable where Label: Codable {
    private enum CodingKeys: String, CodingKey {
        case classes, weights, intercepts, converged
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let classes = try container.decode([Label].self, forKey: .classes)
        let weights = try container.decode(Matrix.self, forKey: .weights)
        let intercepts = try container.decode([Double].self, forKey: .intercepts)
        try requireValidClasses(classes)
        try requireConsistent(classes.count >= 2, "a classifier needs at least two classes")
        try requireConsistent(weights.rows == classes.count && weights.columns > 0, "there must be one row of weights per class")
        try requireConsistent(intercepts.count == classes.count, "there must be one intercept per class")
        try requireFinite(weights.values + intercepts, "weights")
        try self.init(
            classes: classes, weights: weights, intercepts: intercepts,
            converged: container.decode(Bool.self, forKey: .converged)
        )
    }
}

/// The penalized cross-entropy of a linear softmax model, divided by the sample count.
///
/// Parameters are laid out per free class: its feature weights, then its intercept. With two
/// classes only the second class is free (the first has zero scores), which matches binary
/// logistic regression.
struct SoftmaxProblem {
    let features: Matrix
    let targets: [Int]
    let classCount: Int
    let regularization: Double

    var freeClasses: Int { classCount == 2 ? 1 : classCount }
    var parameterCount: Int { freeClasses * (features.columns + 1) }

    func evaluate(_ parameters: [Double]) -> (value: Double, gradient: [Double]) {
        let columns = features.columns
        let stride = columns + 1
        let firstFree = classCount - freeClasses
        var loss = 0.0
        var gradient = [Double](repeating: 0, count: parameters.count)
        var scores = [Double](repeating: 0, count: classCount)
        for row in 0..<features.rows {
            let sample = features.row(row)
            for free in 0..<freeClasses {
                let offset = free * stride
                var score = parameters[offset + columns]
                for column in 0..<columns {
                    score += parameters[offset + column] * sample[column]
                }
                scores[firstFree + free] = score
            }
            let largest = scores.max() ?? 0
            let logNormalizer = largest + log(scores.reduce(0) { $0 + exp($1 - largest) })
            loss += logNormalizer - scores[targets[row]]
            for free in 0..<freeClasses {
                let classIndex = firstFree + free
                let error = exp(scores[classIndex] - logNormalizer) - (classIndex == targets[row] ? 1 : 0)
                let offset = free * stride
                for column in 0..<columns {
                    gradient[offset + column] += error * sample[column]
                }
                gradient[offset + columns] += error
            }
        }
        var penalty = 0.0
        for free in 0..<freeClasses {
            for column in 0..<columns {
                let index = free * stride + column
                penalty += parameters[index] * parameters[index]
                gradient[index] += regularization * parameters[index]
            }
        }
        let count = Double(features.rows)
        return ((loss + regularization / 2 * penalty) / count, gradient.map { $0 / count })
    }

    func unpack(_ parameters: [Double]) -> (weights: Matrix, intercepts: [Double]) {
        let columns = features.columns
        var weights = Matrix(rows: classCount, columns: columns)
        var intercepts = [Double](repeating: 0, count: classCount)
        let firstFree = classCount - freeClasses
        for free in 0..<freeClasses {
            for column in 0..<columns {
                weights[firstFree + free, column] = parameters[free * (columns + 1) + column]
            }
            intercepts[firstFree + free] = parameters[free * (columns + 1) + columns]
        }
        return (weights, intercepts)
    }
}
