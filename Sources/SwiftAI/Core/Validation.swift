// Checks for values that come from the caller. Internal code trusts its own invariants; these
// functions run once at the public boundary (fitting, predicting, decoding).

func checkFinite(_ matrix: Matrix) throws {
    for (offset, value) in matrix.values.enumerated() where !value.isFinite {
        throw SwiftAIError.nonFiniteValue(row: offset / matrix.columns, column: offset % matrix.columns)
    }
}

func checkSample(_ sample: [Double], featureCount: Int) throws {
    guard sample.count == featureCount else {
        throw SwiftAIError.featureCountMismatch(expected: featureCount, actual: sample.count)
    }
    for (column, value) in sample.enumerated() where !value.isFinite {
        throw SwiftAIError.nonFiniteValue(row: 0, column: column)
    }
}

func checkFeatures(_ matrix: Matrix, featureCount: Int) throws {
    guard matrix.columns == featureCount || matrix.rows == 0 else {
        throw SwiftAIError.featureCountMismatch(expected: featureCount, actual: matrix.columns)
    }
    try checkFinite(matrix)
}

func requirePositive(_ value: Int, _ name: String) throws {
    guard value > 0 else {
        throw SwiftAIError.invalidParameter(name: name, reason: "must be greater than 0, got \(value)")
    }
}

func requireNonNegative(_ value: Double, _ name: String) throws {
    guard value >= 0, value.isFinite else {
        throw SwiftAIError.invalidParameter(name: name, reason: "must be a finite number of at least 0, got \(value)")
    }
}

func requirePositive(_ value: Double, _ name: String) throws {
    guard value > 0, value.isFinite else {
        throw SwiftAIError.invalidParameter(name: name, reason: "must be a finite number greater than 0, got \(value)")
    }
}

func requireConsistent(_ condition: Bool, _ reason: @autoclosure () -> String) throws {
    guard condition else {
        throw SwiftAIError.unreadableModel(reason: reason())
    }
}
