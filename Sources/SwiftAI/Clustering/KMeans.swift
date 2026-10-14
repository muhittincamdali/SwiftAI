/// Groups samples into `k` clusters around centroids, without labels.
///
/// Centroids start with k-means++ (spread out, chosen at random with a seed) and move with
/// Lloyd's algorithm until they settle. The run with the lowest inertia of several restarts is
/// kept. Scale the features first so that each one counts the same in the distance.
///
/// ```swift
/// let clusters = try KMeans.fit(features, clusterCount: 3, seed: 1)
/// let cluster = try clusters.predict([5.9, 3.0, 4.2, 1.5])   // 0, 1 or 2
/// ```
public struct KMeans: Sendable, Equatable, Codable {
    /// One row per cluster: the mean of the samples assigned to it.
    public let centroids: Matrix
    /// The sum of squared distances from the training samples to their closest centroid.
    public let inertia: Double
    /// The number of update rounds the best run needed.
    public let iterations: Int

    /// The number of clusters.
    public var clusterCount: Int { centroids.rows }
    /// The number of features per sample.
    public var featureCount: Int { centroids.columns }

    /// Finds `clusterCount` clusters in the rows of `features`.
    ///
    /// - Parameters:
    ///   - features: The samples, one per row.
    ///   - clusterCount: The number of clusters, between 1 and the number of distinct samples.
    ///   - maxIterations: The most update rounds per run.
    ///   - tolerance: A run stops when the centroids move less than this, relative to the mean
    ///     feature variance (squared distance).
    ///   - restarts: The number of runs with different starting centroids, at least 1.
    ///   - seed: Determines the starting centroids.
    /// - Throws: ``SwiftAIError/invalidParameter(name:reason:)`` for invalid settings, when there
    ///   are fewer distinct samples than clusters, or when the values are too large to compute with.
    public static func fit(
        _ features: Matrix, clusterCount: Int, maxIterations: Int = 300, tolerance: Double = 1e-4,
        restarts: Int = 3, seed: UInt64 = 0
    ) throws -> KMeans {
        guard features.rows > 0, features.columns > 0 else { throw SwiftAIError.emptyDataset }
        try checkFinite(features)
        try requirePositive(clusterCount, "clusterCount")
        try requirePositive(maxIterations, "maxIterations")
        try requireNonNegative(tolerance, "tolerance")
        try requirePositive(restarts, "restarts")
        guard clusterCount <= features.rows else {
            throw SwiftAIError.insufficientSamples(required: clusterCount, actual: features.rows)
        }
        let means = features.columnSums().map { $0 / Double(features.rows) }
        try requireRepresentable(means)
        let variances = (0..<features.columns).map { column in
            let deviation = populationDeviation(features.column(column), mean: means[column])
            return deviation * deviation
        }
        let threshold = tolerance * variances.reduce(0, +) / Double(features.columns)

        var generator = SeededGenerator(seed: seed)
        var best: KMeans?
        for _ in 0..<restarts {
            let start = try initialCentroids(features, count: clusterCount, generator: &generator)
            let run = try lloyd(features, centroids: start, maxIterations: maxIterations, threshold: threshold)
            if best == nil || run.inertia < best!.inertia {
                best = run
            }
        }
        return best!
    }

    /// Finds clusters in the features of `data`; the targets are ignored.
    public static func fit<Target>(
        _ data: Dataset<Target>, clusterCount: Int, maxIterations: Int = 300, tolerance: Double = 1e-4,
        restarts: Int = 3, seed: UInt64 = 0
    ) throws -> KMeans {
        try fit(data.features, clusterCount: clusterCount, maxIterations: maxIterations,
                tolerance: tolerance, restarts: restarts, seed: seed)
    }

    private init(centroids: Matrix, inertia: Double, iterations: Int) {
        self.centroids = centroids
        self.inertia = inertia
        self.iterations = iterations
    }

    /// The index of the centroid closest to `sample`.
    public func predict(_ sample: [Double]) throws -> Int {
        try checkSample(sample, featureCount: featureCount)
        let (cluster, distance) = nearestCentroid(sample, centroids)
        guard distance.isFinite else {
            throw SwiftAIError.invalidParameter(name: "sample", reason: "the distances are too large to represent; rescale the features")
        }
        return cluster
    }

    /// The closest centroid of every row.
    public func predict(_ features: Matrix) throws -> [Int] {
        try checkFeatures(features, featureCount: featureCount)
        return try (0..<features.rows).map { try predict(features.row($0)) }
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let centroids = try container.decode(Matrix.self, forKey: .centroids)
        let inertia = try container.decode(Double.self, forKey: .inertia)
        let iterations = try container.decode(Int.self, forKey: .iterations)
        try requireConsistent(centroids.rows > 0 && centroids.columns > 0, "there are no centroids")
        try requireFinite(centroids.values + [inertia], "centroids")
        try requireConsistent(inertia >= 0 && iterations >= 0, "inertia and iterations must not be negative")
        self.init(centroids: centroids, inertia: inertia, iterations: iterations)
    }

    /// k-means++: each new centroid is a sample drawn with probability proportional to its
    /// squared distance from the closest centroid chosen so far.
    private static func initialCentroids(_ features: Matrix, count: Int, generator: inout SeededGenerator) throws -> Matrix {
        var chosen = [features.row(generator.nextIndex(below: features.rows))]
        var distances = (0..<features.rows).map { squaredDistance(features.row($0), chosen[0]) }
        while chosen.count < count {
            let total = distances.reduce(0, +)
            try requireRepresentable([total])
            guard total > 0 else {
                throw SwiftAIError.invalidParameter(
                    name: "clusterCount", reason: "the data has fewer than \(count) distinct samples"
                )
            }
            var target = generator.nextUnitInterval() * total
            var pick = distances.lastIndex { $0 > 0 }!
            for (index, distance) in distances.enumerated() where distance > 0 {
                target -= distance
                if target < 0 {
                    pick = index
                    break
                }
            }
            let centroid = features.row(pick)
            chosen.append(centroid)
            for index in distances.indices {
                distances[index] = min(distances[index], squaredDistance(features.row(index), centroid))
            }
        }
        return try Matrix(chosen)
    }

    /// Lloyd's algorithm: assign every sample to its closest centroid, move each centroid to the
    /// mean of its samples, repeat. An empty cluster takes the sample farthest from its centroid.
    private static func lloyd(_ features: Matrix, centroids start: Matrix, maxIterations: Int, threshold: Double) throws -> KMeans {
        var centroids = start
        var iterations = 0
        for _ in 0..<maxIterations {
            iterations += 1
            let assignment = (0..<features.rows).map { nearestCentroid(features.row($0), centroids) }
            var sums = Matrix(rows: centroids.rows, columns: centroids.columns)
            var counts = [Int](repeating: 0, count: centroids.rows)
            for (row, (cluster, _)) in assignment.enumerated() {
                counts[cluster] += 1
                for column in 0..<features.columns {
                    sums[cluster, column] += features[row, column]
                }
            }
            var updated = sums
            var farthest = assignment.indices.sorted { assignment[$0].distance > assignment[$1].distance }.makeIterator()
            for cluster in 0..<centroids.rows {
                if counts[cluster] == 0, let donor = farthest.next() {
                    for column in 0..<features.columns {
                        updated[cluster, column] = features[donor, column]
                    }
                    continue
                }
                for column in 0..<features.columns {
                    updated[cluster, column] /= Double(counts[cluster])
                }
            }
            try requireRepresentable(updated.values)
            let shift = (0..<centroids.rows).reduce(0) { $0 + squaredDistance(centroids.row($1), updated.row($1)) }
            centroids = updated
            if shift <= threshold { break }
        }
        let inertia = (0..<features.rows).reduce(0) { $0 + nearestCentroid(features.row($1), centroids).distance }
        try requireRepresentable([inertia])
        return KMeans(centroids: centroids, inertia: inertia, iterations: iterations)
    }
}

/// The closest centroid and the squared distance to it; ties go to the lower index.
func nearestCentroid(_ sample: [Double], _ centroids: Matrix) -> (cluster: Int, distance: Double) {
    var best = (cluster: 0, distance: Double.infinity)
    for cluster in 0..<centroids.rows {
        let distance = squaredDistance(sample, centroids.row(cluster))
        if distance < best.distance {
            best = (cluster, distance)
        }
    }
    return best
}

func squaredDistance(_ lhs: [Double], _ rhs: [Double]) -> Double {
    var sum = 0.0
    for index in lhs.indices {
        let difference = lhs[index] - rhs[index]
        sum += difference * difference
    }
    return sum
}
