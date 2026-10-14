/// Rescales each feature linearly so that the training data spans a target range, 0...1 by default.
///
/// Use it when a model expects bounded inputs (neural networks) or when features have no
/// meaningful mean. Samples outside the training range map outside the target range.
///
/// ```swift
/// let scaler = try MinMaxScaler.fit(training.features)
/// let scaled = try scaler.transform([5.9, 3.0, 4.2, 1.5])
/// ```
///
/// A feature with the same value in every training sample maps to the lower end of the range.
public struct MinMaxScaler: FeatureTransformer, Codable, Equatable {
    /// The smallest value of each feature in the training data.
    public let minimums: [Double]
    /// The largest value of each feature in the training data.
    public let maximums: [Double]
    /// The range the training data is mapped to.
    public let range: ClosedRange<Double>

    public var inputFeatureCount: Int { minimums.count }
    public var outputFeatureCount: Int { minimums.count }

    /// Learns the smallest and largest value of each column.
    ///
    /// - Throws: ``SwiftAIError/emptyDataset`` without samples,
    ///   ``SwiftAIError/nonFiniteValue(row:column:)``, and
    ///   ``SwiftAIError/invalidParameter(name:reason:)`` for an empty or infinite range or a
    ///   feature whose spread is too large to represent.
    public static func fit(_ features: Matrix, range: ClosedRange<Double> = 0...1) throws -> MinMaxScaler {
        guard features.rows > 0, features.columns > 0 else { throw SwiftAIError.emptyDataset }
        try checkFinite(features)
        try checkRange(range)
        let columns = (0..<features.columns).map(features.column)
        let minimums = columns.map { $0.min()! }
        let maximums = columns.map { $0.max()! }
        try requireRepresentable(zip(maximums, minimums).map { $0 - $1 })
        return MinMaxScaler(minimums: minimums, maximums: maximums, range: range)
    }

    /// Learns the smallest and largest value of each feature of `data`.
    public static func fit<Target>(_ data: Dataset<Target>, range: ClosedRange<Double> = 0...1) throws -> MinMaxScaler {
        try fit(data.features, range: range)
    }

    private init(minimums: [Double], maximums: [Double], range: ClosedRange<Double>) {
        self.minimums = minimums
        self.maximums = maximums
        self.range = range
    }

    public func transform(_ sample: [Double]) throws -> [Double] {
        try transformChecked(sample, featureCount: inputFeatureCount) { sample in
            sample.indices.map { index in
                let fraction = (sample[index] - minimums[index]) / spread(index)
                return range.lowerBound + fraction * (range.upperBound - range.lowerBound)
            }
        }
    }

    /// Maps scaled values back to the original units.
    public func inverseTransform(_ sample: [Double]) throws -> [Double] {
        try transformChecked(sample, featureCount: inputFeatureCount) { sample in
            sample.indices.map { index in
                let fraction = (sample[index] - range.lowerBound) / (range.upperBound - range.lowerBound)
                return minimums[index] + fraction * spread(index)
            }
        }
    }

    /// The training range of a feature, or 1 for a constant feature.
    private func spread(_ index: Int) -> Double {
        let spread = maximums[index] - minimums[index]
        return spread > 0 ? spread : 1
    }

    private static func checkRange(_ range: ClosedRange<Double>) throws {
        guard range.lowerBound < range.upperBound, (range.upperBound - range.lowerBound).isFinite else {
            throw SwiftAIError.invalidParameter(name: "range", reason: "must be a finite range with lower bound below upper bound, got \(range)")
        }
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let minimums = try container.decode([Double].self, forKey: .minimums)
        let maximums = try container.decode([Double].self, forKey: .maximums)
        let range = try container.decode(ClosedRange<Double>.self, forKey: .range)
        try requireConsistent(!minimums.isEmpty && minimums.count == maximums.count, "minimums and maximums differ in length")
        try requireFinite(minimums + maximums, "minimums and maximums")
        try requireConsistent(zip(minimums, maximums).allSatisfy { $0 <= $1 && ($1 - $0).isFinite }, "a minimum exceeds its maximum")
        do {
            try Self.checkRange(range)
        } catch {
            throw SwiftAIError.unreadableModel(reason: "the target range is empty or infinite")
        }
        self.init(minimums: minimums, maximums: maximums, range: range)
    }
}
