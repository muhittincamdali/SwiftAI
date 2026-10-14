import Foundation

/// A random number generator that always produces the same sequence for the same seed.
///
/// Every SwiftAI function that uses randomness (shuffling, splitting, weight initialization,
/// bootstrap sampling, k-means++ seeding) takes a `seed` and draws from this generator, so a
/// result can be reproduced exactly on any platform. The algorithm is SplitMix64.
///
/// ```swift
/// var generator = SeededGenerator(seed: 7)
/// let roll = Int.random(in: 1...6, using: &generator)
/// ```
public struct SeededGenerator: RandomNumberGenerator, Sendable {
    private var state: UInt64

    /// Creates a generator. Generators with the same seed produce the same numbers.
    public init(seed: UInt64) {
        state = seed
    }

    /// Returns the next 64 random bits.
    public mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var mixed = state
        mixed = (mixed ^ (mixed >> 30)) &* 0xBF58_476D_1CE4_E5B9
        mixed = (mixed ^ (mixed >> 27)) &* 0x94D0_49BB_1331_11EB
        return mixed ^ (mixed >> 31)
    }

    // The helpers below do not rely on the standard library's `random(in:using:)` or
    // `shuffle(using:)`, whose algorithms may change between Swift releases; seeded results
    // stay the same across toolchains.

    /// A uniformly distributed value in `0..<1` with 53 random bits.
    mutating func nextUnitInterval() -> Double {
        Double(next() >> 11) * 0x1.0p-53
    }

    /// A uniformly distributed integer in `0..<upperBound`, without modulo bias.
    mutating func nextIndex(below upperBound: Int) -> Int {
        precondition(upperBound > 0, "upperBound must be positive")
        let bound = UInt64(upperBound)
        let threshold = (0 &- bound) % bound
        while true {
            let value = next()
            if value >= threshold {
                return Int(value % bound)
            }
        }
    }

    /// A normally distributed value (Box–Muller transform).
    mutating func nextGaussian(mean: Double = 0, standardDeviation: Double = 1) -> Double {
        let u1 = 1 - nextUnitInterval()
        let u2 = nextUnitInterval()
        let radius = (-2 * log(u1)).squareRoot()
        return mean + standardDeviation * radius * cos(2 * Double.pi * u2)
    }

    /// Shuffles `array` in place (Fisher–Yates).
    mutating func shuffle<Element>(_ array: inout [Element]) {
        guard array.count > 1 else { return }
        for index in stride(from: array.count - 1, to: 0, by: -1) {
            let other = nextIndex(below: index + 1)
            array.swapAt(index, other)
        }
    }

    /// The integers `0..<count` in random order.
    mutating func permutation(of count: Int) -> [Int] {
        var indices = Array(0..<count)
        shuffle(&indices)
        return indices
    }
}
