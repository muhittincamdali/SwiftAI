/// Predicts a number as a weighted sum of the features plus a constant.
///
/// With `regularization` 0 this is ordinary least squares. A positive value adds an L2 penalty on
/// the coefficients (ridge regression), which keeps them small and makes the fit stable when
/// features are correlated or there are few samples. The value means the same as `alpha` in
/// scikit-learn's `Ridge`; the intercept is not penalized.
///
/// ```swift
/// let houses = try Dataset<Double>(features: [[50, 1], [80, 2], [120, 3], [65, 1]],
///                                  targets: [150_000, 245_000, 350_000, 190_000])
/// let model = try LinearRegression.fit(houses)
/// let price = try model.predict([100, 2])
/// ```
public struct LinearRegression: Regressor, Codable, Equatable {
    /// The weight of each feature.
    public let coefficients: [Double]
    /// The prediction for a sample whose features are all 0.
    public let intercept: Double
    /// The L2 penalty the model was fitted with.
    public let regularization: Double

    public var featureCount: Int { coefficients.count }

    /// Fits the coefficients that minimize the squared error (plus the penalty).
    ///
    /// - Parameters:
    ///   - data: The training samples and their target values.
    ///   - regularization: The L2 penalty, at least 0.
    /// - Throws: ``SwiftAIError/singularMatrix`` without regularization when a feature is constant
    ///   or a combination of others, or when there are fewer samples than features;
    ///   ``SwiftAIError/nonFiniteTarget(row:)`` for a NaN or infinite target.
    public static func fit(_ data: Dataset<Double>, regularization: Double = 0) throws -> LinearRegression {
        try requireNonNegative(regularization, "regularization")
        try checkFinite(targets: data.targets)
        let features = data.features
        let sampleCount = Double(data.count)
        let featureMeans = features.columnSums().map { $0 / sampleCount }
        let targetMean = data.targets.reduce(0, +) / sampleCount
        try requireRepresentable(featureMeans + [targetMean])

        // Centering removes the intercept from the system; the penalty rows below the data
        // (sqrt(λ)·I) turn least squares into ridge regression.
        let penaltyRows = regularization > 0 ? features.columns : 0
        var system = Matrix(rows: features.rows + penaltyRows, columns: features.columns)
        for row in 0..<features.rows {
            for column in 0..<features.columns {
                system[row, column] = features[row, column] - featureMeans[column]
            }
        }
        for index in 0..<penaltyRows {
            system[features.rows + index, index] = regularization.squareRoot()
        }
        let centeredTargets = data.targets.map { $0 - targetMean }
            + [Double](repeating: 0, count: penaltyRows)

        let coefficients = try solveLeastSquares(system, centeredTargets)
        let intercept = targetMean - dot(coefficients, featureMeans)
        try requireRepresentable(coefficients + [intercept])
        return LinearRegression(coefficients: coefficients, intercept: intercept, regularization: regularization)
    }

    private init(coefficients: [Double], intercept: Double, regularization: Double) {
        self.coefficients = coefficients
        self.intercept = intercept
        self.regularization = regularization
    }

    public func predict(_ sample: [Double]) throws -> Double {
        try checkSample(sample, featureCount: featureCount)
        return try finitePrediction(intercept + dot(coefficients, sample))
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let coefficients = try container.decode([Double].self, forKey: .coefficients)
        let intercept = try container.decode(Double.self, forKey: .intercept)
        let regularization = try container.decode(Double.self, forKey: .regularization)
        try requireConsistent(!coefficients.isEmpty, "there are no coefficients")
        try requireFinite(coefficients + [intercept], "coefficients")
        try requireConsistent(regularization >= 0 && regularization.isFinite, "regularization must be at least 0")
        self.init(coefficients: coefficients, intercept: intercept, regularization: regularization)
    }
}
