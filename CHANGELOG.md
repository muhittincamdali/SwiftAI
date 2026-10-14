# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [2.0.0] - 2026-10-14

A new library. In June 2026 the 1.0.0 sources were replaced with placeholder code; this release
rebuilds SwiftAI from scratch as a dependency-free package for classical machine learning. No
1.0.0 API remains.

### Added

- Data: `Matrix` (row-major `Double` grid, Accelerate products, checked shapes), `Dataset`
  (validated features and targets, subsets, shuffling), random and stratified splits, k-fold and
  stratified folds, `CSVTable` (RFC 4180 CSV text and files), the iris data and
  `SeededGenerator` (SplitMix64).
- Regression: `LinearRegression` with an optional ridge penalty (Householder QR),
  `KNearestNeighborsRegressor`, `DecisionTreeRegressor`, `RandomForestRegressor` and
  `NeuralNetworkRegressor`.
- Classification: `LogisticRegression` (softmax, L-BFGS), `KNearestNeighborsClassifier`,
  `GaussianNaiveBayes`, `DecisionTreeClassifier`, `RandomForestClassifier` (trees trained in
  parallel, deterministic for a seed) and `NeuralNetworkClassifier` (Adam, early stopping).
- Clustering and preprocessing: `KMeans` (k-means++, restarts), `StandardScaler`,
  `MinMaxScaler`, `PrincipalComponentAnalysis` and `Pipeline`.
- Evaluation: `Metrics` (accuracy, MSE, MAE, R², log loss), `ConfusionMatrix`,
  `ClassificationReport`, `RegressionReport` and cross-validation with `CrossValidationResult`.
- `SwiftAIError` with a description of what to change for every invalid input.
- `Codable` conformance for every model, transformer and pipeline, with validation on decoding.
- DocC catalog with four articles, the ModelLab example app for iOS and macOS, README images
  rendered from model predictions, and CI through the shared workflows of
  muhittincamdali/.github.

### Changed

- Minimum platforms: iOS 15, macOS 12, tvOS 15, watchOS 8, visionOS 1; swift-tools-version 6.2
  and the Swift 6 language mode.

### Removed

- All 1.0.0 modules (the app-architecture layers, networking, analytics, speech, vision and NLP
  wrappers) and their dependencies, including Alamofire.

### Security

- Model files are validated before use: matrix shapes whose value count overflows, NaN or
  infinite parameters, unknown classes, decision trees whose child links point backwards (which
  could make prediction loop forever) and neural network layers that do not fit together are
  rejected with an error instead of crashing or hanging.
- Values near the largest `Double` no longer overflow silently in scaling, regression, distances
  or metrics; the functions throw instead of returning infinity or NaN.

## [1.0.0] - 2026-02-02

First tagged release: an app-architecture framework with networking, analytics and wrappers
around Apple's Vision, Speech and Natural Language frameworks. Replaced by 2.0.0.

[Unreleased]: https://github.com/muhittincamdali/SwiftAI/compare/v2.0.0...HEAD
[2.0.0]: https://github.com/muhittincamdali/SwiftAI/compare/v1.0.0...v2.0.0
[1.0.0]: https://github.com/muhittincamdali/SwiftAI/releases/tag/v1.0.0
