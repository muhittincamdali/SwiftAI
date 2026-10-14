/// Samples to learn from: a feature matrix and one target per row.
///
/// For classification the targets are labels (`String`, `Int`, or your own `Hashable` type);
/// for regression they are `Double` values.
///
/// ```swift
/// let houses = try Dataset<Double>(
///     features: [[50], [80], [120]],     // size in square metres
///     targets: [150_000, 240_000, 360_000]
/// )
/// ```
///
/// Creating a dataset validates it once: rows must have the same length, values must be finite,
/// and there must be exactly one target per row. Models can then rely on that.
public struct Dataset<Target: Sendable>: Sendable {
    /// The feature values, one row per sample.
    public let features: Matrix
    /// The target of each sample, in row order.
    public let targets: [Target]

    /// Creates a dataset from a feature matrix and its targets.
    ///
    /// - Throws: ``SwiftAIError/emptyDataset`` without samples,
    ///   ``SwiftAIError/sampleCountMismatch(features:targets:)`` when the counts differ,
    ///   ``SwiftAIError/nonFiniteValue(row:column:)`` for NaN or infinite values.
    public init(features: Matrix, targets: [Target]) throws {
        guard features.rows > 0, features.columns > 0 else {
            throw SwiftAIError.emptyDataset
        }
        guard features.rows == targets.count else {
            throw SwiftAIError.sampleCountMismatch(features: features.rows, targets: targets.count)
        }
        try checkFinite(features)
        self.features = features
        self.targets = targets
    }

    /// Creates a dataset from rows of feature values and their targets.
    ///
    /// - Throws: The errors of ``init(features:targets:)``, and
    ///   ``SwiftAIError/raggedRows(row:expectedColumns:actualColumns:)`` when the rows differ in
    ///   length.
    public init(features: [[Double]], targets: [Target]) throws {
        try self.init(features: Matrix(features), targets: targets)
    }

    /// Already validated parts, used when deriving a dataset from another one.
    init(validFeatures: Matrix, targets: [Target]) {
        self.features = validFeatures
        self.targets = targets
    }

    /// The number of samples.
    public var count: Int { features.rows }

    /// The number of features per sample.
    public var featureCount: Int { features.columns }

    /// The samples at `indices`, in that order.
    public func subset(_ indices: [Int]) -> Dataset {
        Dataset(validFeatures: features.selectingRows(indices), targets: indices.map { targets[$0] })
    }

    /// The same samples in a random order determined by `seed`.
    public func shuffled(seed: UInt64 = 0) -> Dataset {
        var generator = SeededGenerator(seed: seed)
        return subset(generator.permutation(of: count))
    }

    /// Returns a dataset with the same targets and transformed features, for example scaled ones.
    ///
    /// - Throws: Whatever `transform` throws, or ``SwiftAIError`` when the result is not a valid
    ///   feature matrix for these targets.
    public func mapFeatures(_ transform: (Matrix) throws -> Matrix) throws -> Dataset {
        try Dataset(features: transform(features), targets: targets)
    }
}

extension Dataset: Equatable where Target: Equatable {}
