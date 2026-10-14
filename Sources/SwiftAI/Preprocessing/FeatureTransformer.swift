/// A fitted step that turns feature values into other feature values, such as a scaler.
///
/// Fit a transformer on training data only, then apply the same transformer to every sample the
/// model sees later. ``Pipeline`` does that for you.
public protocol FeatureTransformer: Sendable {
    /// The number of features each input sample must have.
    var inputFeatureCount: Int { get }
    /// The number of features each transformed sample has.
    var outputFeatureCount: Int { get }

    /// Transforms one sample.
    ///
    /// - Throws: ``SwiftAIError/featureCountMismatch(expected:actual:)`` or
    ///   ``SwiftAIError/nonFiniteValue(row:column:)``.
    func transform(_ sample: [Double]) throws -> [Double]
}

extension FeatureTransformer {
    /// Transforms every row of `features`.
    public func transform(_ features: Matrix) throws -> Matrix {
        try checkFeatures(features, featureCount: inputFeatureCount)
        var values: [Double] = []
        values.reserveCapacity(checkedProduct(features.rows, outputFeatureCount) ?? 0)
        for row in 0..<features.rows {
            values += try transform(features.row(row))
        }
        let result = Matrix(rows: features.rows, columns: outputFeatureCount, values: values)
        try checkFinite(result)
        return result
    }

    /// Returns `data` with transformed features and the same targets.
    public func transform<Target>(_ data: Dataset<Target>) throws -> Dataset<Target> {
        try Dataset(features: transform(data.features), targets: data.targets)
    }
}

/// Validates one input sample and checks that the transformed values are finite.
///
/// Scaling a finite value can still overflow (a huge value divided by a tiny scale), and a model
/// must never receive the resulting infinity.
func transformChecked(
    _ sample: [Double], featureCount: Int, _ transform: ([Double]) -> [Double]
) throws -> [Double] {
    try checkSample(sample, featureCount: featureCount)
    let result = transform(sample)
    for (column, value) in result.enumerated() where !value.isFinite {
        throw SwiftAIError.nonFiniteValue(row: 0, column: column)
    }
    return result
}
