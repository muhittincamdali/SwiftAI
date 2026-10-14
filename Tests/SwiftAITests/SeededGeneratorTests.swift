import Testing
@testable import SwiftAI

@Suite("SeededGenerator")
struct SeededGeneratorTests {
    @Test("Matches the SplitMix64 reference output")
    func referenceValues() {
        // First outputs of the reference splitmix64.c for seed 1234567.
        var generator = SeededGenerator(seed: 1_234_567)
        let expected: [UInt64] = [
            6_457_827_717_110_365_317, 3_203_168_211_198_807_973, 9_817_491_932_198_370_423,
            4_593_380_528_125_082_431, 16_408_922_859_458_223_821,
        ]
        #expect((0..<5).map { _ in generator.next() } == expected)
    }

    @Test("Same seed, same sequence; different seed, different sequence")
    func reproducible() {
        var first = SeededGenerator(seed: 42)
        var second = SeededGenerator(seed: 42)
        var other = SeededGenerator(seed: 43)
        let a = (0..<10).map { _ in first.next() }
        let b = (0..<10).map { _ in second.next() }
        let c = (0..<10).map { _ in other.next() }
        #expect(a == b)
        #expect(a != c)
    }

    @Test("Unit interval values stay in [0, 1)")
    func unitInterval() {
        var generator = SeededGenerator(seed: 3)
        let values = (0..<10_000).map { _ in generator.nextUnitInterval() }
        #expect(values.allSatisfy { $0 >= 0 && $0 < 1 })
        let mean = values.reduce(0, +) / Double(values.count)
        #expect(abs(mean - 0.5) < 0.02)
    }

    @Test("Indices cover the whole range and nothing outside it")
    func indexRange() {
        var generator = SeededGenerator(seed: 5)
        var counts = [Int](repeating: 0, count: 7)
        for _ in 0..<7_000 {
            counts[generator.nextIndex(below: 7)] += 1
        }
        // Each bucket expects 1000; a fair generator stays far inside these bounds.
        #expect(counts.allSatisfy { $0 > 850 && $0 < 1_150 })
    }

    @Test("Gaussian samples have the requested mean and spread")
    func gaussian() {
        var generator = SeededGenerator(seed: 9)
        let samples = (0..<20_000).map { _ in generator.nextGaussian(mean: 3, standardDeviation: 2) }
        let mean = samples.reduce(0, +) / Double(samples.count)
        let variance = samples.map { ($0 - mean) * ($0 - mean) }.reduce(0, +) / Double(samples.count)
        #expect(abs(mean - 3) < 0.05)
        #expect(abs(variance.squareRoot() - 2) < 0.05)
    }

    @Test("A permutation contains every index exactly once")
    func permutation() {
        var generator = SeededGenerator(seed: 1)
        let order = generator.permutation(of: 100)
        #expect(order.sorted() == Array(0..<100))
        #expect(order != Array(0..<100))
    }

    @Test("Works with the standard library's random APIs")
    func standardLibrary() {
        var first = SeededGenerator(seed: 8)
        var second = SeededGenerator(seed: 8)
        #expect(Int.random(in: 0..<1_000, using: &first) == Int.random(in: 0..<1_000, using: &second))
    }
}
