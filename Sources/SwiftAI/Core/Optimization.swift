import Foundation

/// The result of minimizing a smooth function.
struct Minimum {
    let point: [Double]
    let value: Double
    let iterations: Int
    let converged: Bool
}

/// Minimizes a smooth convex function with limited-memory BFGS and a backtracking line search.
///
/// Every loop is bounded: at most `maxIterations` steps of at most `maxLineSearchSteps` function
/// evaluations each.
///
/// - Parameters:
///   - start: The starting point.
///   - maxIterations: The most steps to take.
///   - tolerance: Stop when no gradient component is larger than this.
///   - objective: Returns the function value and gradient at a point.
/// - Throws: ``SwiftAIError/invalidParameter(name:reason:)`` when the value or gradient at the
///   starting point is not finite, which happens when the features are too large.
func minimizeLBFGS(
    start: [Double], maxIterations: Int, tolerance: Double, objective: ([Double]) -> (value: Double, gradient: [Double])
) throws -> Minimum {
    let historySize = 10
    let maxLineSearchSteps = 40
    var point = start
    var (value, gradient) = objective(point)
    let tooLargeToCompute = SwiftAIError.invalidParameter(
        name: "features", reason: "the values are too large to compute with; rescale them first"
    )
    guard value.isFinite, gradient.allSatisfy(\.isFinite) else { throw tooLargeToCompute }
    var steps: [[Double]] = []
    var gradientChanges: [[Double]] = []

    for iteration in 0..<maxIterations {
        if maxMagnitude(gradient) <= tolerance {
            return Minimum(point: point, value: value, iterations: iteration, converged: true)
        }
        var direction = searchDirection(gradient: gradient, steps: steps, gradientChanges: gradientChanges)
        var slope = dot(direction, gradient)
        if slope >= 0 || !slope.isFinite {
            // The curvature history no longer gives a descent direction; restart from steepest descent.
            steps.removeAll()
            gradientChanges.removeAll()
            direction = gradient.map { -$0 }
            slope = dot(direction, gradient)
            // The squared gradient overflows when the features are near the largest Double.
            guard slope.isFinite else { throw tooLargeToCompute }
        }
        var stepLength = steps.isEmpty ? min(1, 1 / max(euclideanNorm(gradient), .leastNormalMagnitude)) : 1
        var accepted: (point: [Double], value: Double, gradient: [Double])?
        var anyFiniteCandidate = false
        for _ in 0..<maxLineSearchSteps {
            let candidate = zip(point, direction).map { $0 + stepLength * $1 }
            let (candidateValue, candidateGradient) = objective(candidate)
            anyFiniteCandidate = anyFiniteCandidate || candidateValue.isFinite
            // Armijo condition: the value must drop by a fraction of what the slope promises.
            if candidateValue.isFinite, candidateGradient.allSatisfy(\.isFinite),
               candidateValue <= value + 1e-4 * stepLength * slope {
                accepted = (candidate, candidateValue, candidateGradient)
                break
            }
            stepLength /= 2
        }
        guard let accepted else {
            // Every step overflowed: the features are too large for the scores to be computed.
            guard anyFiniteCandidate else { throw tooLargeToCompute }
            // No step makes progress: the point is a minimum up to rounding.
            return Minimum(point: point, value: value, iterations: iteration, converged: maxMagnitude(gradient) <= tolerance * 100)
        }
        let step = zip(accepted.point, point).map { $0 - $1 }
        let change = zip(accepted.gradient, gradient).map { $0 - $1 }
        if dot(step, change) > 1e-12 * dot(change, change) {
            steps.append(step)
            gradientChanges.append(change)
            if steps.count > historySize {
                steps.removeFirst()
                gradientChanges.removeFirst()
            }
        }
        let improvement = value - accepted.value
        (point, value, gradient) = accepted
        if improvement <= 1e-15 * max(abs(value), 1) {
            return Minimum(point: point, value: value, iterations: iteration + 1, converged: true)
        }
    }
    return Minimum(point: point, value: value, iterations: maxIterations, converged: maxMagnitude(gradient) <= tolerance)
}

/// The L-BFGS two-loop recursion: an approximation of −H⁻¹·gradient.
private func searchDirection(gradient: [Double], steps: [[Double]], gradientChanges: [[Double]]) -> [Double] {
    var direction = gradient
    var alphas = [Double](repeating: 0, count: steps.count)
    for index in steps.indices.reversed() {
        let rho = 1 / dot(gradientChanges[index], steps[index])
        alphas[index] = rho * dot(steps[index], direction)
        for component in direction.indices {
            direction[component] -= alphas[index] * gradientChanges[index][component]
        }
    }
    if let lastStep = steps.last, let lastChange = gradientChanges.last {
        let scale = dot(lastStep, lastChange) / dot(lastChange, lastChange)
        direction = direction.map { $0 * scale }
    }
    for index in steps.indices {
        let rho = 1 / dot(gradientChanges[index], steps[index])
        let beta = rho * dot(gradientChanges[index], direction)
        for component in direction.indices {
            direction[component] += (alphas[index] - beta) * steps[index][component]
        }
    }
    return direction.map { -$0 }
}

private func maxMagnitude(_ values: [Double]) -> Double {
    values.lazy.map(abs).max() ?? 0
}

/// Turns scores into probabilities that add up to 1 (softmax), stable for large scores.
///
/// - Throws: ``SwiftAIError/invalidParameter(name:reason:)`` when no score is finite, which
///   happens when the features are too large to compute with.
func softmax(_ scores: [Double]) throws -> [Double] {
    guard let largest = scores.max(), largest.isFinite, !scores.contains(where: \.isNaN) else {
        throw SwiftAIError.invalidParameter(name: "sample", reason: "the values are too large to compute with; rescale the features")
    }
    let exponentials = scores.map { exp($0 - largest) }
    let total = exponentials.reduce(0, +)
    return exponentials.map { $0 / total }
}
