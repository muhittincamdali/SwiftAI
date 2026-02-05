# SwiftAI

<p align="center">
  <img src="https://img.shields.io/badge/Swift-5.9+-FA7343?style=for-the-badge&logo=swift&logoColor=white" alt="Swift 5.9+"/>
  <img src="https://img.shields.io/badge/Platform-iOS%2015%2B%20%7C%20macOS%2012%2B-007AFF?style=for-the-badge&logo=apple&logoColor=white" alt="Platform"/>
  <img src="https://img.shields.io/badge/License-MIT-green?style=for-the-badge" alt="License"/>
  <img src="https://img.shields.io/github/stars/muhittincamdali/SwiftAI?style=for-the-badge" alt="Stars"/>
</p>

<p align="center">
  <strong>Pure Swift Machine Learning Framework</strong><br>
  Neural networks, classic ML algorithms, on-device training. No Python. No CoreML dependency. Just Swift + Accelerate.
</p>

---

## Why SwiftAI?

Most ML frameworks for Apple platforms are either wrappers around Python (slow, bloated) or limited to CoreML inference (no training). SwiftAI is different:

- **Pure Swift** — every algorithm implemented from scratch
- **On-device training** — train models directly on iPhone/iPad/Mac
- **Accelerate-optimized** — SIMD vector ops via vDSP/BLAS for real performance
- **Zero heavy dependencies** — just swift-numerics, that's it
- **scikit-learn API** — familiar `.fit()` / `.predict()` / `.score()` interface

```
┌─────────────────────────────────────────────────────────────┐
│                         SwiftAI                              │
├─────────────────────────────────────────────────────────────┤
│  🧠 Neural Networks    │  📊 Classic ML       │  🔧 Tools   │
│  ─────────────────     │  ─────────────       │  ────────   │
│  • Dense Layers        │  • Linear Regression │  • Scalers  │
│  • Batch/Layer Norm    │  • Logistic Reg.     │  • Encoders │
│  • Dropout             │  • Decision Trees    │  • Imputers │
│  • Embedding           │  • Random Forests    │  • Metrics  │
│  • 10+ Activations     │  • K-Means           │  • CV Split │
│  • 9+ Loss Functions   │  • KNN               │  • Export   │
│  • 5+ Optimizers       │  • SVM               │  • CoreML   │
└─────────────────────────────────────────────────────────────┘
```

## Quick Start

### Installation

**Swift Package Manager**

```swift
dependencies: [
    .package(url: "https://github.com/muhittincamdali/SwiftAI.git", from: "2.0.0")
]
```

### Neural Network — MNIST-style Classifier

```swift
import SwiftAI

let network = NeuralNetwork()
    .dense(784, 256, activation: .relu)
    .batchNorm(256)
    .dropout(0.3)
    .dense(256, 128, activation: .relu)
    .dropout(0.2)
    .dense(128, 10, activation: .softmax)

network.compile(
    optimizer: .adam,
    loss: .crossEntropy,
    learningRate: 0.001
)

let history = network.train(
    x: trainData, y: trainLabels,
    epochs: 50, batchSize: 32,
    validationSplit: 0.2
)

let predictions = network.predict(testData)
```

### Linear Regression

```swift
let model = LinearRegression()
model.fit(x: features, y: targets)

let predictions = model.predict(newData)
let r2 = model.score(x: testX, y: testY)
print("R² Score: \(r2)")  // 0.97
```

### Random Forest Classification

```swift
let forest = RandomForestClassifier(
    nEstimators: 100,
    maxDepth: 10,
    maxFeatures: .sqrt
)
forest.fit(x: trainX, y: trainY)

let accuracy = forest.score(x: testX, y: testY)
print("Accuracy: \(accuracy * 100)%")

// Feature importance
for (i, imp) in forest.featureImportances!.enumerated() {
    print("Feature \(i): \(imp)")
}
```

### K-Means Clustering

```swift
let kmeans = KMeans(nClusters: 5, initMethod: .kmeanspp)
kmeans.fit(data)

let labels = kmeans.predict(newData)
let score = silhouetteScore(x: data, labels: kmeans.labels!)
print("Silhouette: \(score)")
```

### Cross-Validation

```swift
let kfold = KFold(nSplits: 5, shuffle: true)
var scores = [Float]()

for (trainIdx, testIdx) in kfold.split(nSamples: data.count) {
    let trainX = trainIdx.map { data[$0] }
    let trainY = trainIdx.map { labels[$0] }
    let testX = testIdx.map { data[$0] }
    let testY = testIdx.map { labels[$0] }
    
    let model = RandomForestClassifier(nEstimators: 50)
    model.fit(x: trainX, y: trainY)
    scores.append(model.score(x: testX, y: testY))
}

print("CV: \(scores.reduce(0,+) / Float(scores.count)) ± \(standardDeviation(scores))")
```

## API Reference

### Neural Network Layers

| Layer | Description | Parameters |
|-------|-------------|------------|
| `Dense` | Fully connected | inputSize, outputSize, useBias |
| `ActivationLayer` | Activation function | activation |
| `Dropout` | Regularization | rate |
| `BatchNorm` | Batch normalization | numFeatures, epsilon, momentum |
| `LayerNorm` | Layer normalization | normalizedShape, epsilon |
| `Embedding` | Token embedding | numEmbeddings, embeddingDim |
| `Flatten` | Flatten tensor | — |

### Activations

`relu` · `leakyRelu` · `elu` · `selu` · `sigmoid` · `tanh` · `softmax` · `swish` · `gelu` · `softplus`

### Loss Functions

| Loss | Use Case |
|------|----------|
| `mse` | Regression |
| `mae` | Regression (robust) |
| `huber` | Regression (outlier-resistant) |
| `bce` | Binary classification |
| `bceWithLogits` | Binary with raw logits |
| `crossEntropy` | Multi-class classification |
| `nll` | Negative log likelihood |
| `hinge` | SVM-style |
| `cosineEmbedding` | Similarity learning |

### Optimizers

`sgd` (with momentum/nesterov) · `adam` · `adamw` · `rmsprop` · `adagrad`

### Classic ML Algorithms

| Algorithm | Type | Key Features |
|-----------|------|--------------|
| `LinearRegression` | Regression | OLS, L1/L2 regularization, SGD |
| `RidgeRegression` | Regression | L2 regularization |
| `LassoRegression` | Regression | L1 regularization |
| `ElasticNet` | Regression | L1 + L2 combined |
| `LogisticRegression` | Classification | Binary/Multinomial |
| `DecisionTreeClassifier` | Classification | Gini/Entropy splitting |
| `DecisionTreeRegressor` | Regression | MSE/MAE splitting |
| `RandomForestClassifier` | Classification | Bootstrap aggregating, OOB |
| `RandomForestRegressor` | Regression | Feature importance |
| `KMeans` | Clustering | K-means++ initialization |
| `KNeighborsClassifier` | Classification | KD-tree, distance weighting |
| `KNeighborsRegressor` | Regression | Distance-based |
| `SVC` | Classification | RBF/Linear/Poly/Sigmoid kernels |
| `SVR` | Regression | Epsilon-insensitive |

### Preprocessing

```swift
// Scalers
StandardScaler().fitTransform(data)
MinMaxScaler(featureRange: (0, 1)).fitTransform(data)
RobustScaler().fitTransform(data)
Normalizer(norm: .l2).transform(data)

// Encoders
LabelEncoder().fitTransform(labels)
OneHotEncoder().fitTransform(categories)

// Imputation
SimpleImputer(strategy: .mean).fitTransform(data)

// Splitting
let (trainX, testX, trainY, testY) = trainTestSplit(x: x, y: y, testSize: 0.2)
```

### Metrics

```swift
// Classification
accuracyScore(yTrue: actual, yPred: predicted)
precisionRecallF1(yTrue: actual, yPred: predicted)
confusionMatrix(yTrue: actual, yPred: predicted)
rocAucScore(yTrue: actual, yScore: probabilities)

// Regression
meanSquaredError(yTrue: actual, yPred: predicted)
rootMeanSquaredError(yTrue: actual, yPred: predicted)
meanAbsoluteError(yTrue: actual, yPred: predicted)
r2Score(yTrue: actual, yPred: predicted)

// Clustering
silhouetteScore(x: data, labels: clusters)
daviesBouldinScore(x: data, labels: clusters)
adjustedRandScore(labelsTrue: true, labelsPred: pred)
```

### Model Export

```swift
// Save/Load neural networks
try network.save(to: modelURL)
try network.load(from: modelURL)

// Export to CoreML-compatible JSON
try network.exportToCoreML(url: outputURL)

// Model quantization (8-bit)
let (quantized, scale, zp) = ModelCompressor.quantize(weights: params, bits: 8)
```

## Architecture

```
Sources/SwiftAI/
├── ML/
│   ├── Core/
│   │   ├── Tensor.swift            # SIMD-optimized via Accelerate
│   │   ├── Activations.swift       # 10 activation functions + derivatives
│   │   ├── LossFunctions.swift     # 9 loss functions + gradients
│   │   └── Optimizers.swift        # SGD, Adam, AdamW, RMSprop, Adagrad
│   ├── Neural/
│   │   ├── Layers.swift            # Dense, Dropout, BatchNorm, LayerNorm, Embedding
│   │   └── NeuralNetwork.swift     # Network builder, trainer, serialization
│   ├── Algorithms/
│   │   ├── LinearRegression.swift  # OLS + Ridge + Lasso + ElasticNet
│   │   ├── LogisticRegression.swift
│   │   ├── DecisionTree.swift      # Classifier + Regressor
│   │   ├── RandomForest.swift      # Classifier + Regressor
│   │   ├── KMeans.swift            # K-Means + MiniBatch
│   │   ├── KNN.swift               # Classifier + Regressor + KD-Tree
│   │   └── SVM.swift               # SVC + SVR (SMO algorithm)
│   ├── Preprocessing/
│   │   └── DataPreprocessing.swift # Scalers, encoders, imputers, CV
│   ├── Evaluation/
│   │   └── Metrics.swift           # Classification, regression, clustering metrics
│   └── Export/
│       └── CoreMLExport.swift      # JSON export, ONNX info, quantization
└── SwiftAI.swift                   # Framework entry point
```

## Performance

SwiftAI uses Apple's **Accelerate** framework under the hood:

| Operation | Method | Speedup vs Pure Swift |
|-----------|--------|----------------------|
| Matrix Multiply (1000×1000) | `cblas_sgemm` | ~70× |
| Vector Addition (1M) | `vDSP_vadd` | ~18× |
| Softmax (10K) | `vvexpf` | ~26× |
| Dot Product (1M) | `vDSP_dotpr` | ~15× |

## Comparison

| Feature | SwiftAI | CreateML | CoreML | TensorFlow |
|---------|---------|----------|--------|------------|
| Pure Swift | ✅ | ✅ | ❌ | ❌ |
| Custom Neural Nets | ✅ | ❌ | ❌ | ✅ |
| On-Device Training | ✅ | ✅ | ❌ | ✅ |
| Classic ML (7 algos) | ✅ | Partial | ❌ | ✅ |
| No Heavy Dependencies | ✅ | ✅ | ✅ | ❌ |
| Open Source | ✅ | ❌ | ❌ | ✅ |
| Preprocessing Pipeline | ✅ | Limited | ❌ | ✅ |
| Model Serialization | ✅ | ✅ | ✅ | ✅ |

## Requirements

- Swift 5.9+
- iOS 15+ / macOS 12+ / tvOS 15+ / watchOS 8+
- Xcode 15+

## Contributing

Contributions welcome! Please read our [Contributing Guide](CONTRIBUTING.md).

```bash
git clone https://github.com/muhittincamdali/SwiftAI.git
cd SwiftAI
swift build
swift test
```

## License

MIT License — see [LICENSE](LICENSE) for details.

---

<p align="center">
  <strong>Built with ❤️ in Swift</strong><br>
  <a href="https://github.com/muhittincamdali/SwiftAI/issues">Report Bug</a> · <a href="https://github.com/muhittincamdali/SwiftAI/issues">Request Feature</a>
</p>
