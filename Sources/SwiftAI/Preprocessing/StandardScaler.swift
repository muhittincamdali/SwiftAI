/// Shifts and scales each feature to a mean of 0 and a standard deviation of 1.
///
/// Distance-based and gradient-trained models (k-nearest neighbours, logistic regression, neural
/// networks, k-means) work best when features have comparable ranges. Fit the scaler on the
/// training data and use it for every later sample.
///
/// ```swift
/// let scaler = try StandardScaler.fit(training.features)
/// let scaledTraining = try scaler.transform(training)
/// ```
///
/// A feature with the same value in every sample keeps a scale of 1, so it becomes 0 everywhere
/// instead of dividing by zero.
public struct StandardScaler: FeatureTransformer, Codable, Equatable {
    /// The mean of each feature in the training data.
    public let means: [Double]
    /// The population standard deviation of each feature, or 1 for a constant feature.
    public let scales: [Double]

    public var inputFeatureCount: Int { means.count }
    public var outputFeatureCount: Int { means.count }

    /// Learns the mean and standard deviation of each column.
    ///
    /// - Throws: ``SwiftAIError/emptyDataset`` without samples, or
    ///   ``SwiftAIError/nonFiniteValue(row:column:)``.
    public static func fit(_ features: Matrix) throws -> StandardScaler {
        guard features.rows > 0, features.columns > 0 else { throw SwiftAIError.emptyDataset }
        try checkFinite(features)
        let count = Double(features.rows)
        let means = features.columnSums().map { $0 / count }
        let scales = (0..<features.columns).map { column in
            let deviation = populationDeviation(features.column(column), mean: means[column])
            return isNegligible(deviation, comparedWith: means[column]) ? 1 : deviation
        }
        try requireRepresentable(means + scales)
        return StandardScaler(means: means, scales: scales)
    }

    /// Learns the mean and standard deviation of each feature of `data`.
    public static func fit<Target>(_ data: Dataset<Target>) throws -> StandardScaler {
        try fit(data.features)
    }

    private init(means: [Double], scales: [Double]) {
        self.means = means
        self.scales = scales
    }

    public func transform(_ sample: [Double]) throws -> [Double] {
        try transformChecked(sample, featureCount: inputFeatureCount) { sample in
            sample.indices.map { (sample[$0] - means[$0]) / scales[$0] }
        }
    }

    /// Maps scaled values back to the original units.
    public func inverseTransform(_ sample: [Double]) throws -> [Double] {
        try transformChecked(sample, featureCount: inputFeatureCount) { sample in
            sample.indices.map { sample[$0] * scales[$0] + means[$0] }
        }
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let means = try container.decode([Double].self, forKey: .means)
        let scales = try container.decode([Double].self, forKey: .scales)
        try requireConsistent(!means.isEmpty && means.count == scales.count, "means and scales differ in length")
        try requireFinite(means, "means")
        try requireConsistent(scales.allSatisfy { $0 > 0 && $0.isFinite }, "scales must be finite and positive")
        self.init(means: means, scales: scales)
    }
}

/// The population standard deviation of `values`.
///
/// Deviations are divided by the largest one before squaring, so values above about 1e154 do
/// not overflow to infinity when squared.
func populationDeviation(_ values: [Double], mean: Double) -> Double {
    let deviations = values.map { $0 - mean }
    let largest = deviations.map(abs).max() ?? 0
    guard largest > 0, largest.isFinite else { return largest }
    let meanSquare = deviations.map { ($0 / largest) * ($0 / largest) }.reduce(0, +) / Double(values.count)
    return largest * meanSquare.squareRoot()
}

/// Whether a spread is only rounding noise compared with the values it was measured on.
func isNegligible(_ spread: Double, comparedWith magnitude: Double) -> Bool {
    spread <= 1e-12 * max(abs(magnitude), 1)
}
