/// The scores of a model trained and tested on each fold of a cross-validation.
public struct CrossValidationResult: Sendable, Equatable {
    /// One score per fold: accuracy for classifiers, R² for regressors.
    public let scores: [Double]

    /// The mean score.
    public var mean: Double {
        scores.reduce(0, +) / Double(scores.count)
    }

    /// The population standard deviation of the scores: how much the result depends on the split.
    public var standardDeviation: Double {
        let mean = mean
        let variance = scores.map { ($0 - mean) * ($0 - mean) }.reduce(0, +) / Double(scores.count)
        return variance.squareRoot()
    }
}

extension Dataset where Target: Hashable {
    /// Estimates how well a classifier generalizes by training it `folds` times.
    ///
    /// The samples are divided into stratified folds. Each round fits a model on all folds but one
    /// and scores its accuracy on the remaining fold.
    ///
    /// ```swift
    /// let result = try Dataset.iris.crossValidate(folds: 5) { training in
    ///     try KNearestNeighborsClassifier.fit(training, k: 5)
    /// }
    /// result.mean   // mean accuracy over the 5 folds
    /// ```
    ///
    /// - Parameters:
    ///   - folds: The number of folds, at least 2.
    ///   - seed: Determines how samples are assigned to folds.
    ///   - fit: Trains a model on the training part of a fold.
    public func crossValidate<Model: Classifier>(
        folds: Int = 5,
        seed: UInt64 = 0,
        fit: (Dataset<Target>) throws -> Model
    ) throws -> CrossValidationResult where Model.Label == Target {
        let scores = try stratifiedFolds(folds, seed: seed).map { fold in
            try fit(fold.training).accuracy(on: fold.validation)
        }
        return CrossValidationResult(scores: scores)
    }
}

extension Dataset where Target == Double {
    /// Estimates how well a regressor generalizes by training it `folds` times.
    ///
    /// Each round fits a model on all folds but one and scores its R² on the remaining fold.
    ///
    /// - Parameters:
    ///   - folds: The number of folds, at least 2.
    ///   - seed: Determines how samples are assigned to folds.
    ///   - fit: Trains a model on the training part of a fold.
    public func crossValidate<Model: Regressor>(
        folds: Int = 5,
        seed: UInt64 = 0,
        fit: (Dataset<Double>) throws -> Model
    ) throws -> CrossValidationResult {
        let scores = try self.folds(folds, seed: seed).map { fold in
            try fit(fold.training).r2Score(on: fold.validation)
        }
        return CrossValidationResult(scores: scores)
    }
}
