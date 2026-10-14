import Testing
@testable import SwiftAI

/// Compares two probability vectors component by component.
func expectClose(_ actual: [Double], _ expected: [Double], tolerance: Double, sourceLocation: SourceLocation = #_sourceLocation) {
    #expect(actual.count == expected.count, sourceLocation: sourceLocation)
    for (lhs, rhs) in zip(actual, expected) {
        #expect(abs(lhs - rhs) <= tolerance, "\(actual) is not close to \(expected)", sourceLocation: sourceLocation)
    }
}

// Reference values from scikit-learn 1.9.1, trained on all 150 iris samples.
let irisQueries: [[Double]] = [[5.9, 3.0, 4.2, 1.5], [6.3, 2.8, 5.1, 1.5], [5.0, 3.6, 1.4, 0.2]]
