/// Projects samples onto the directions in which the training data varies most.
///
/// Principal component analysis (PCA) reduces the number of features while keeping as much of
/// the variance as possible: for plotting data in 2D, for removing correlated features, or for
/// speeding up a model. Components are the eigenvectors of the covariance matrix, ordered by
/// variance; each one's largest loading is positive, as in scikit-learn.
///
/// ```swift
/// let pca = try PrincipalComponentAnalysis.fit(data.features, componentCount: 2)
/// pca.explainedVarianceRatio   // [0.92, 0.05] for iris
/// let points = try pca.transform(data.features)
/// ```
public struct PrincipalComponentAnalysis: FeatureTransformer, Codable, Equatable {
    /// The mean of each input feature.
    public let means: [Double]
    /// One row per component, one column per input feature.
    public let components: Matrix
    /// The variance of the training data along each component (sample variance, n − 1).
    public let explainedVariance: [Double]
    /// Each component's share of the total variance.
    public let explainedVarianceRatio: [Double]

    public var inputFeatureCount: Int { means.count }
    public var outputFeatureCount: Int { components.rows }

    /// Computes the principal components of the rows of `features`.
    ///
    /// - Parameters:
    ///   - features: The training samples, one per row.
    ///   - componentCount: The number of components to keep, between 1 and the feature count;
    ///     all of them when `nil`.
    /// - Throws: ``SwiftAIError/insufficientSamples(required:actual:)`` with fewer than two
    ///   samples, ``SwiftAIError/invalidParameter(name:reason:)`` for an invalid count or values
    ///   too large to compute with.
    public static func fit(_ features: Matrix, componentCount: Int? = nil) throws -> PrincipalComponentAnalysis {
        guard features.rows >= 2 else { throw SwiftAIError.insufficientSamples(required: 2, actual: features.rows) }
        try checkFinite(features)
        let count = componentCount ?? features.columns
        guard (1...features.columns).contains(count) else {
            throw SwiftAIError.invalidParameter(
                name: "componentCount", reason: "must be between 1 and the feature count \(features.columns), got \(count)"
            )
        }
        let means = features.columnSums().map { $0 / Double(features.rows) }
        try requireRepresentable(means)
        let covariance = covarianceMatrix(features, means: means)
        try requireRepresentable(covariance.values)

        let (eigenvalues, eigenvectors) = symmetricEigen(covariance)
        let order = eigenvalues.indices.sorted { eigenvalues[$0] > eigenvalues[$1] }.prefix(count)
        let variances = eigenvalues.map { max($0, 0) }
        let total = variances.reduce(0, +)
        let components = try Matrix(order.map { index in
            let vector = eigenvectors.column(index)
            let largest = vector.indices.max { abs(vector[$0]) < abs(vector[$1]) }!
            return vector[largest] < 0 ? vector.map { -$0 } : vector
        })
        return PrincipalComponentAnalysis(
            means: means, components: components,
            explainedVariance: order.map { variances[$0] },
            explainedVarianceRatio: order.map { total > 0 ? variances[$0] / total : 0 }
        )
    }

    /// Computes the principal components of the features of `data`.
    public static func fit<Target>(_ data: Dataset<Target>, componentCount: Int? = nil) throws -> PrincipalComponentAnalysis {
        try fit(data.features, componentCount: componentCount)
    }

    private init(means: [Double], components: Matrix, explainedVariance: [Double], explainedVarianceRatio: [Double]) {
        self.means = means
        self.components = components
        self.explainedVariance = explainedVariance
        self.explainedVarianceRatio = explainedVarianceRatio
    }

    /// The coordinates of `sample` along each component.
    public func transform(_ sample: [Double]) throws -> [Double] {
        try transformChecked(sample, featureCount: inputFeatureCount) { sample in
            let centered = zip(sample, means).map { $0 - $1 }
            return (0..<components.rows).map { dot(components.row($0), centered) }
        }
    }

    /// Maps component coordinates back to the input features. Information in dropped
    /// components is lost.
    public func inverseTransform(_ coordinates: [Double]) throws -> [Double] {
        try transformChecked(coordinates, featureCount: outputFeatureCount) { coordinates in
            (0..<inputFeatureCount).map { feature in
                means[feature] + (0..<components.rows).reduce(0) { $0 + coordinates[$1] * components[$1, feature] }
            }
        }
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let means = try container.decode([Double].self, forKey: .means)
        let components = try container.decode(Matrix.self, forKey: .components)
        let variance = try container.decode([Double].self, forKey: .explainedVariance)
        let ratio = try container.decode([Double].self, forKey: .explainedVarianceRatio)
        try requireConsistent(!means.isEmpty && components.columns == means.count, "components must have one column per feature")
        try requireConsistent(
            components.rows > 0 && components.rows <= means.count && variance.count == components.rows && ratio.count == components.rows,
            "there must be between 1 and \(means.count) components, each with a variance and a ratio"
        )
        try requireFinite(means + components.values + variance + ratio, "components")
        self.init(means: means, components: components, explainedVariance: variance, explainedVarianceRatio: ratio)
    }
}

/// The sample covariance matrix (divided by n − 1).
func covarianceMatrix(_ features: Matrix, means: [Double]) -> Matrix {
    let columns = features.columns
    var covariance = Matrix(rows: columns, columns: columns)
    for row in 0..<features.rows {
        let centered = (0..<columns).map { features[row, $0] - means[$0] }
        for first in 0..<columns {
            for second in first..<columns {
                covariance[first, second] += centered[first] * centered[second]
            }
        }
    }
    let divisor = Double(features.rows - 1)
    for first in 0..<columns {
        for second in first..<columns {
            covariance[first, second] /= divisor
            covariance[second, first] = covariance[first, second]
        }
    }
    return covariance
}

/// Eigenvalues and eigenvectors (as columns) of a symmetric matrix, by cyclic Jacobi rotations.
///
/// Each sweep rotates every off-diagonal pair to zero; the loop stops when the off-diagonal part
/// is negligible and runs at most 100 sweeps, far more than the 6 to 10 that convergence needs.
func symmetricEigen(_ matrix: Matrix) -> (values: [Double], vectors: Matrix) {
    let size = matrix.rows
    var a = matrix
    var vectors = Matrix.identity(size)
    let scale = euclideanNorm(matrix.values)
    for _ in 0..<100 {
        var offDiagonal = 0.0
        for row in 0..<size {
            for column in (row + 1)..<size {
                offDiagonal = max(offDiagonal, abs(a[row, column]))
            }
        }
        if offDiagonal <= 1e-15 * scale { break }
        for p in 0..<size {
            for q in (p + 1)..<size where a[p, q] != 0 {
                let theta = (a[q, q] - a[p, p]) / (2 * a[p, q])
                let tangent = (theta >= 0 ? 1 : -1) / (abs(theta) + (theta * theta + 1).squareRoot())
                let cosine = 1 / (tangent * tangent + 1).squareRoot()
                let sine = tangent * cosine
                for k in 0..<size {
                    let akp = a[k, p], akq = a[k, q]
                    a[k, p] = cosine * akp - sine * akq
                    a[k, q] = sine * akp + cosine * akq
                }
                for k in 0..<size {
                    let apk = a[p, k], aqk = a[q, k]
                    a[p, k] = cosine * apk - sine * aqk
                    a[q, k] = sine * apk + cosine * aqk
                }
                for k in 0..<size {
                    let vkp = vectors[k, p], vkq = vectors[k, q]
                    vectors[k, p] = cosine * vkp - sine * vkq
                    vectors[k, q] = sine * vkp + cosine * vkq
                }
            }
        }
    }
    return ((0..<size).map { a[$0, $0] }, vectors)
}
