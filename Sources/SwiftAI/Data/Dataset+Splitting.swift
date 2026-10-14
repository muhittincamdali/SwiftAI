extension Dataset {
    /// Splits the samples at random into a training set and a test set.
    ///
    /// Train a model on `training` and measure it on `test`, which it has never seen.
    ///
    /// ```swift
    /// let (training, test) = try data.split(testFraction: 0.25, seed: 1)
    /// ```
    ///
    /// - Parameters:
    ///   - testFraction: The share of samples that go into the test set, between 0 and 1
    ///     (exclusive). The test set gets at least one sample and leaves at least one for training.
    ///   - seed: Determines the random order; the same seed gives the same split.
    /// - Throws: ``SwiftAIError/invalidParameter(name:reason:)`` for a fraction outside (0, 1),
    ///   ``SwiftAIError/insufficientSamples(required:actual:)`` with fewer than two samples.
    public func split(testFraction: Double = 0.2, seed: UInt64 = 0) throws -> (training: Dataset, test: Dataset) {
        let testCount = try Self.testCount(fraction: testFraction, total: count)
        var generator = SeededGenerator(seed: seed)
        let order = generator.permutation(of: count)
        return (subset(Array(order[testCount...])), subset(Array(order[..<testCount])))
    }

    /// Divides the samples into `k` folds for cross-validation.
    ///
    /// Each element pairs one fold (`validation`) with all other samples (`training`). Every
    /// sample is in exactly one validation fold. Fold sizes differ by at most one.
    ///
    /// - Throws: ``SwiftAIError/invalidParameter(name:reason:)`` when `k` is less than 2, and
    ///   ``SwiftAIError/insufficientSamples(required:actual:)`` when there are fewer samples than folds.
    public func folds(_ k: Int, seed: UInt64 = 0) throws -> [(training: Dataset, validation: Dataset)] {
        try Self.checkFoldCount(k, total: count)
        var generator = SeededGenerator(seed: seed)
        let order = generator.permutation(of: count)
        var assignment = [Int](repeating: 0, count: count)
        for (position, index) in order.enumerated() {
            assignment[index] = position % k
        }
        return makeFolds(assignment: assignment, k: k)
    }

    func makeFolds(assignment: [Int], k: Int) -> [(training: Dataset, validation: Dataset)] {
        (0..<k).map { fold in
            let validation = (0..<count).filter { assignment[$0] == fold }
            let training = (0..<count).filter { assignment[$0] != fold }
            return (subset(training), subset(validation))
        }
    }

    static func testCount(fraction: Double, total: Int) throws -> Int {
        guard fraction > 0, fraction < 1 else {
            throw SwiftAIError.invalidParameter(name: "testFraction", reason: "must be between 0 and 1, got \(fraction)")
        }
        guard total >= 2 else {
            throw SwiftAIError.insufficientSamples(required: 2, actual: total)
        }
        let rounded = Int((Double(total) * fraction).rounded())
        return min(max(rounded, 1), total - 1)
    }

    static func checkFoldCount(_ k: Int, total: Int) throws {
        guard k >= 2 else {
            throw SwiftAIError.invalidParameter(name: "k", reason: "needs at least 2 folds, got \(k)")
        }
        guard total >= k else {
            throw SwiftAIError.insufficientSamples(required: k, actual: total)
        }
    }
}

extension Dataset where Target: Hashable {
    /// Splits the samples at random so that each class keeps its share in both sets.
    ///
    /// Use this for classification: with a plain ``split(testFraction:seed:)`` a small class can
    /// end up missing from the test set by chance.
    ///
    /// - Throws: The same errors as ``split(testFraction:seed:)``.
    public func stratifiedSplit(testFraction: Double = 0.2, seed: UInt64 = 0) throws -> (training: Dataset, test: Dataset) {
        let testTotal = try Self.testCount(fraction: testFraction, total: count)
        var generator = SeededGenerator(seed: seed)
        let groups = indicesByClass()
        let quotas = Self.proportionalQuotas(groupSizes: groups.map(\.count), total: testTotal)
        var trainingIndices: [Int] = []
        var testIndices: [Int] = []
        for (group, quota) in zip(groups, quotas) {
            var members = group
            generator.shuffle(&members)
            testIndices += members[..<quota]
            trainingIndices += members[quota...]
        }
        generator.shuffle(&trainingIndices)
        generator.shuffle(&testIndices)
        return (subset(trainingIndices), subset(testIndices))
    }

    /// Divides the samples into `k` folds that each keep the class proportions of the whole set.
    ///
    /// - Throws: The same errors as ``folds(_:seed:)``.
    public func stratifiedFolds(_ k: Int, seed: UInt64 = 0) throws -> [(training: Dataset, validation: Dataset)] {
        try Self.checkFoldCount(k, total: count)
        var generator = SeededGenerator(seed: seed)
        var assignment = [Int](repeating: 0, count: count)
        var position = 0
        for group in indicesByClass() {
            var members = group
            generator.shuffle(&members)
            for index in members {
                assignment[index] = position % k
                position += 1
            }
        }
        return makeFolds(assignment: assignment, k: k)
    }

    /// Sample indices grouped by target, groups in order of first appearance.
    func indicesByClass() -> [[Int]] {
        var groupOf: [Target: Int] = [:]
        var groups: [[Int]] = []
        for (index, target) in targets.enumerated() {
            if let group = groupOf[target] {
                groups[group].append(index)
            } else {
                groupOf[target] = groups.count
                groups.append([index])
            }
        }
        return groups
    }

    /// Distributes `total` over groups in proportion to their sizes (largest remainder method).
    static func proportionalQuotas(groupSizes: [Int], total: Int) -> [Int] {
        let population = Double(groupSizes.reduce(0, +))
        let exact = groupSizes.map { Double($0) * Double(total) / population }
        var quotas = exact.map { Int($0.rounded(.down)) }
        let byRemainder = exact.indices.sorted { lhs, rhs in
            let left = exact[lhs] - Double(quotas[lhs])
            let right = exact[rhs] - Double(quotas[rhs])
            return left == right ? lhs < rhs : left > right
        }
        var missing = total - quotas.reduce(0, +)
        for group in byRemainder where missing > 0 {
            quotas[group] += 1
            missing -= 1
        }
        return quotas
    }
}
