import Foundation

/// A probabilistic classifier that models each feature of each class as a normal distribution.
///
/// Naive Bayes assumes the features are independent within a class. It trains in one pass,
/// needs little data, and is a strong baseline for continuous features. The probabilities match
/// scikit-learn's `GaussianNB`.
///
/// ```swift
/// let model = try GaussianNaiveBayes.fit(training)
/// let species = try model.predict([5.9, 3.0, 4.2, 1.5])
/// ```
public struct GaussianNaiveBayes<Label: Hashable & Sendable>: ProbabilisticClassifier {
    public let classes: [Label]
    /// The share of training samples in each class.
    public let priors: [Double]
    /// The mean of each feature, one row per class.
    public let means: Matrix
    /// The variance of each feature, one row per class, including the smoothing term.
    public let variances: Matrix

    public var featureCount: Int { means.columns }

    /// Learns the class priors and the mean and variance of every feature per class.
    ///
    /// - Parameters:
    ///   - data: The training samples.
    ///   - varianceSmoothing: Added to every variance as a fraction of the largest feature
    ///     variance, so that a feature that is constant within a class does not divide by zero.
    /// - Throws: ``SwiftAIError/invalidParameter(name:reason:)`` for a smoothing value that is not positive
    ///   or features too large to compute with.
    public static func fit(_ data: Dataset<Label>, varianceSmoothing: Double = 1e-9) throws -> GaussianNaiveBayes {
        try requirePositive(varianceSmoothing, "varianceSmoothing")
        let index = ClassIndex(data.targets)
        let groups = data.indicesByClass()
        let features = data.features
        let largestVariance = try (0..<features.columns).map { column in
            let values = features.column(column)
            let mean = values.reduce(0, +) / Double(values.count)
            try requireRepresentable([mean])
            let deviation = populationDeviation(values, mean: mean)
            return deviation * deviation
        }.max() ?? 0
        let epsilon = varianceSmoothing * (largestVariance > 0 ? largestVariance : 1)

        var means = Matrix(rows: groups.count, columns: features.columns)
        var variances = Matrix(rows: groups.count, columns: features.columns)
        for (classIndex, members) in groups.enumerated() {
            let rows = features.selectingRows(members)
            for column in 0..<features.columns {
                let values = rows.column(column)
                let mean = values.reduce(0, +) / Double(values.count)
                let deviation = populationDeviation(values, mean: mean)
                means[classIndex, column] = mean
                variances[classIndex, column] = deviation * deviation + epsilon
            }
        }
        try requireRepresentable(means.values + variances.values)
        let priors = groups.map { Double($0.count) / Double(data.count) }
        return GaussianNaiveBayes(classes: index.classes, priors: priors, means: means, variances: variances)
    }

    private init(classes: [Label], priors: [Double], means: Matrix, variances: Matrix) {
        self.classes = classes
        self.priors = priors
        self.means = means
        self.variances = variances
    }

    public func classProbabilities(_ sample: [Double]) throws -> [Double] {
        try checkSample(sample, featureCount: featureCount)
        let logLikelihoods = (0..<classes.count).map { classIndex in
            var total = log(priors[classIndex])
            for column in 0..<featureCount {
                let variance = variances[classIndex, column]
                let deviation = sample[column] - means[classIndex, column]
                total -= 0.5 * (log(2 * Double.pi * variance) + deviation * deviation / variance)
            }
            return total
        }
        return try softmax(logLikelihoods)
    }

    public func predict(_ sample: [Double]) throws -> Label {
        classes[argmax(try classProbabilities(sample))]
    }
}

extension GaussianNaiveBayes: Equatable where Label: Equatable {}

extension GaussianNaiveBayes: Codable where Label: Codable {
    private enum CodingKeys: String, CodingKey {
        case classes, priors, means, variances
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let classes = try container.decode([Label].self, forKey: .classes)
        let priors = try container.decode([Double].self, forKey: .priors)
        let means = try container.decode(Matrix.self, forKey: .means)
        let variances = try container.decode(Matrix.self, forKey: .variances)
        try requireValidClasses(classes)
        try requireConsistent(priors.count == classes.count, "there must be one prior per class")
        try requireConsistent(priors.allSatisfy { $0 > 0 && $0 <= 1 }, "priors must be between 0 and 1")
        try requireConsistent(
            means.rows == classes.count && means.columns > 0 && variances.rows == means.rows && variances.columns == means.columns,
            "means and variances must have one row per class and the same number of features"
        )
        try requireFinite(means.values, "means")
        try requireConsistent(variances.values.allSatisfy { $0 > 0 && $0.isFinite }, "variances must be finite and positive")
        self.init(classes: classes, priors: priors, means: means, variances: variances)
    }
}
