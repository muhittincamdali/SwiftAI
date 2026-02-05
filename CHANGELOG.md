# Changelog

All notable changes to SwiftAI will be documented in this file.

## [2.0.0] - 2025-02-05

### Changed
- **Major architecture overhaul** — focused purely on ML, removed enterprise boilerplate
- Simplified Package.swift — only swift-numerics as dependency
- Tensor `data` property is now publicly mutable for direct manipulation
- Minimum platform: iOS 15+, macOS 12+, tvOS 15+, watchOS 8+

### Added
- Comprehensive test suite: Tensor, Neural Network, Algorithms, Preprocessing, Metrics
- Framework entry point with version info (`SwiftAIFramework.version`)
- `standardDeviation()` utility function
- Type aliases: `FloatTensor`, `DoubleTensor`

### Fixed
- Build failures on macOS (removed UIKit dependencies)
- Tensor `randn` disambiguation with Foundation math functions
- KMeans `InitMethod` pattern matching (no longer requires Equatable)
- KNN `DistanceMetric` disambiguation with BNNS.Norm
- LinearRegression swap access exclusivity violation
- All Swift 5.9+ strict concurrency warnings resolved

### Removed
- Heavy dependencies: Alamofire, CryptoSwift, KeychainAccess, swift-log, swift-metrics, Quick, Nimble
- Enterprise architecture layers (Application, Infrastructure, Presentation, Data, Domain)
- iOS-only code that prevented macOS builds
- Unused podspec file

## [1.0.0] - 2024-08-17

### Added
- Initial release
- Tensor with Accelerate-optimized operations (vDSP, BLAS)
- Neural network builder with Dense, Dropout, BatchNorm, LayerNorm, Embedding, Flatten
- 10 activation functions (ReLU, LeakyReLU, ELU, SELU, Sigmoid, Tanh, Softmax, Swish, GELU, Softplus)
- 9 loss functions (MSE, MAE, Huber, BCE, CrossEntropy, NLL, Hinge, Cosine)
- 5 optimizers (SGD, Adam, AdamW, RMSprop, Adagrad)
- Linear/Ridge/Lasso/ElasticNet regression
- Logistic regression (binary/multinomial)
- Decision tree classifier and regressor
- Random forest classifier and regressor
- K-Means clustering with K-Means++ initialization
- KNN classifier and regressor with KD-tree
- SVM classifier and regressor (SMO algorithm)
- Preprocessing: StandardScaler, MinMaxScaler, RobustScaler, Normalizer
- Encoders: LabelEncoder, OneHotEncoder
- Imputation: SimpleImputer
- Metrics: accuracy, precision/recall/F1, confusion matrix, ROC AUC, MSE, RMSE, MAE, R², silhouette score
- Cross-validation: KFold, train/test split
- Model export: JSON, CoreML-compatible, ONNX info
- Model compression: quantization, pruning
