import Foundation

/// The errors that SwiftAI throws for invalid input.
///
/// Every public function that takes data or parameters from you validates them and throws one of
/// these cases instead of crashing. The ``errorDescription`` says what to change.
public enum SwiftAIError: Error, Equatable, Sendable {
    /// The data has no samples.
    case emptyDataset
    /// A row has a different number of values than the first row.
    case raggedRows(row: Int, expectedColumns: Int, actualColumns: Int)
    /// The number of feature rows and the number of targets differ.
    case sampleCountMismatch(features: Int, targets: Int)
    /// A sample has a different number of features than the data the model was trained on.
    case featureCountMismatch(expected: Int, actual: Int)
    /// A feature value is NaN or infinite.
    case nonFiniteValue(row: Int, column: Int)
    /// A parameter is outside its valid range.
    case invalidParameter(name: String, reason: String)
    /// The operation needs more samples than the data has.
    case insufficientSamples(required: Int, actual: Int)
    /// A classifier was given training data with only one class.
    case singleClass
    /// A system of equations has no unique solution, usually because two features are copies or
    /// multiples of each other.
    case singularMatrix
    /// A saved model was written by an incompatible version of SwiftAI or its values do not fit
    /// together.
    case unreadableModel(reason: String)
}

extension SwiftAIError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .emptyDataset:
            "The data has no samples."
        case let .raggedRows(row, expected, actual):
            "Row \(row) has \(actual) values, but the first row has \(expected)."
        case let .sampleCountMismatch(features, targets):
            "There are \(features) feature rows but \(targets) targets; each sample needs exactly one target."
        case let .featureCountMismatch(expected, actual):
            "The model expects \(expected) features per sample, but got \(actual)."
        case let .nonFiniteValue(row, column):
            "The value in row \(row), column \(column) is NaN or infinite."
        case let .invalidParameter(name, reason):
            "Invalid \(name): \(reason)"
        case let .insufficientSamples(required, actual):
            "This needs at least \(required) samples, but the data has \(actual)."
        case .singleClass:
            "The training data contains only one class; a classifier needs at least two."
        case .singularMatrix:
            "The equations have no unique solution. Remove duplicated or constant features, or add regularization."
        case let .unreadableModel(reason):
            "The saved model cannot be read: \(reason)"
        }
    }
}
