import Testing
@testable import SwiftAI

@Suite("Dataset")
struct DatasetTests {
    let letters = try! Dataset(
        features: (0..<10).map { [Double($0)] },
        targets: ["a", "a", "a", "a", "a", "a", "b", "b", "b", "b"]
    )

    @Test("Validation rejects empty, mismatched and non-finite input")
    func validation() {
        #expect(throws: SwiftAIError.emptyDataset) {
            try Dataset<Double>(features: [], targets: [])
        }
        #expect(throws: SwiftAIError.sampleCountMismatch(features: 2, targets: 1)) {
            try Dataset(features: [[1], [2]], targets: [1.0])
        }
        #expect(throws: SwiftAIError.nonFiniteValue(row: 1, column: 0)) {
            try Dataset(features: [[1], [.nan]], targets: [1.0, 2.0])
        }
        #expect(throws: SwiftAIError.raggedRows(row: 1, expectedColumns: 2, actualColumns: 1)) {
            try Dataset(features: [[1, 2], [3]], targets: [1.0, 2.0])
        }
    }

    @Test("Split sizes follow the fraction, and the parts cover the data once")
    func split() throws {
        let (training, test) = try letters.split(testFraction: 0.3, seed: 4)
        #expect(training.count == 7)
        #expect(test.count == 3)
        let all = (training.features.values + test.features.values).sorted()
        #expect(all == (0..<10).map(Double.init))
    }

    @Test("The same seed gives the same split; another seed a different one")
    func splitIsSeeded() throws {
        let first = try letters.split(seed: 1)
        let again = try letters.split(seed: 1)
        let other = try letters.split(seed: 2)
        #expect(first.test == again.test)
        #expect(first.test != other.test)
    }

    @Test("Test sets keep at least one sample on each side")
    func splitBounds() throws {
        let pair = try Dataset(features: [[1], [2]], targets: [1.0, 2.0])
        let (training, test) = try pair.split(testFraction: 0.01)
        #expect(training.count == 1)
        #expect(test.count == 1)
        #expect(throws: SwiftAIError.self) { try pair.split(testFraction: 1) }
        let single = try Dataset(features: [[1]], targets: [1.0])
        #expect(throws: SwiftAIError.insufficientSamples(required: 2, actual: 1)) {
            try single.split()
        }
    }

    @Test("Stratified split keeps the class proportions")
    func stratifiedSplit() throws {
        let (training, test) = try letters.stratifiedSplit(testFraction: 0.5, seed: 3)
        #expect(test.targets.filter { $0 == "a" }.count == 3)
        #expect(test.targets.filter { $0 == "b" }.count == 2)
        #expect(training.count == 5)
    }

    @Test("Stratified split of iris puts 10 of each species in a 20% test set")
    func stratifiedIris() throws {
        let (training, test) = try Dataset.iris.stratifiedSplit(testFraction: 0.2, seed: 0)
        for species in ["setosa", "versicolor", "virginica"] {
            #expect(test.targets.filter { $0 == species }.count == 10)
            #expect(training.targets.filter { $0 == species }.count == 40)
        }
    }

    @Test("Quotas use the largest remainder and add up to the total")
    func quotas() {
        #expect(Dataset<String>.proportionalQuotas(groupSizes: [6, 4], total: 5) == [3, 2])
        #expect(Dataset<String>.proportionalQuotas(groupSizes: [1, 1, 1], total: 2) == [1, 1, 0])
        #expect(Dataset<String>.proportionalQuotas(groupSizes: [50, 30, 20], total: 7).reduce(0, +) == 7)
    }

    @Test("Folds partition the samples and differ in size by at most one")
    func folds() throws {
        let folds = try letters.folds(3, seed: 2)
        #expect(folds.count == 3)
        #expect(folds.map(\.validation.count).sorted() == [3, 3, 4])
        let validationValues = folds.flatMap(\.validation.features.values).sorted()
        #expect(validationValues == (0..<10).map(Double.init))
        for fold in folds {
            #expect(fold.training.count + fold.validation.count == 10)
            #expect(Set(fold.training.features.values).isDisjoint(with: fold.validation.features.values))
        }
    }

    @Test("Stratified folds spread every class over all folds")
    func stratifiedFolds() throws {
        let folds = try letters.stratifiedFolds(2, seed: 5)
        for fold in folds {
            #expect(fold.validation.targets.filter { $0 == "a" }.count == 3)
            #expect(fold.validation.targets.filter { $0 == "b" }.count == 2)
        }
    }

    @Test("Fold count must be between 2 and the sample count")
    func foldBounds() {
        #expect(throws: SwiftAIError.self) { try letters.folds(1) }
        #expect(throws: SwiftAIError.insufficientSamples(required: 11, actual: 10)) {
            try letters.folds(11)
        }
    }

    @Test("Shuffling is a seeded permutation")
    func shuffled() {
        let shuffled = letters.shuffled(seed: 6)
        #expect(shuffled.count == letters.count)
        #expect(shuffled.features.values.sorted() == letters.features.values)
        #expect(shuffled == letters.shuffled(seed: 6))
        // Targets travel with their rows.
        for (row, target) in shuffled.targets.enumerated() {
            #expect(target == (shuffled.features[row, 0] < 6 ? "a" : "b"))
        }
    }

    @Test("Iris has 150 samples, 4 features and 50 per species")
    func iris() {
        let iris = Dataset.iris
        #expect(iris.count == 150)
        #expect(iris.featureCount == 4)
        #expect(iris.features.row(0) == [5.1, 3.5, 1.4, 0.2])
        #expect(iris.features.row(149) == [5.9, 3.0, 5.1, 1.8])
        // Samples 35 and 38 follow Fisher's paper, not the UCI transcription.
        #expect(iris.features.row(34) == [4.9, 3.1, 1.5, 0.2])
        #expect(iris.features.row(37) == [4.9, 3.6, 1.4, 0.1])
        for species in ["setosa", "versicolor", "virginica"] {
            #expect(iris.targets.filter { $0 == species }.count == 50)
        }
        #expect(Dataset.irisFeatureNames.count == 4)
    }

    @Test("Mapping features keeps the targets and validates the result")
    func mapFeatures() throws {
        let doubled = try letters.mapFeatures { 2 * $0 }
        #expect(doubled.targets == letters.targets)
        #expect(doubled.features.values == letters.features.values.map { $0 * 2 })
        #expect(throws: SwiftAIError.self) {
            try letters.mapFeatures { $0.map { _ in .infinity } }
        }
    }
}
