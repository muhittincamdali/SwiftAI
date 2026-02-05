# SwiftAI

<p align="center">
  <img src="https://img.shields.io/badge/Swift-5.9+-FA7343?style=for-the-badge&logo=swift&logoColor=white" alt="Swift 5.9+"/>
  <img src="https://img.shields.io/badge/Platform-iOS%2016%2B%20%7C%20macOS%2013%2B-007AFF?style=for-the-badge&logo=apple&logoColor=white" alt="Platform"/>
  <img src="https://img.shields.io/badge/License-MIT-green?style=for-the-badge" alt="License"/>
  <img src="https://img.shields.io/github/stars/muhittinc/SwiftAI?style=for-the-badge" alt="Stars"/>
</p>

<p align="center">
  <strong>Pure Swift Machine Learning Framework</strong><br>
  No Python. No External Dependencies. Just Swift.
</p>

---

## 🌟 Why SwiftAI?

SwiftAI is the most comprehensive **pure Swift** machine learning framework. Built from scratch with Accelerate-optimized operations, it brings the power of scikit-learn and PyTorch to iOS and macOS development.

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
│                        │  • Gradient Boost    │             │
└─────────────────────────────────────────────────────────────┘
```

## 🚀 Quick Start

### Installation

**Swift Package Manager**

```swift
dependencies: [
    .package(url: "https://github.com/muhittinc/SwiftAI.git", from: "1.0.0")
]
```

### Neural Network Example

```swift
import SwiftAI

// Create a neural network
let network = NeuralNetwork()
    .dense(784, 256, activation: .relu)
    .batchNorm(256)
    .dropout(0.3)
    .dense(256, 128, activation: .relu)
    .dropout(0.2)
    .dense(128, 10, activation: .softmax)

// Compile with optimizer and loss
network.compile(
    optimizer: .adam,
    loss: .crossEntropy,
    learningRate: 0.001
)

// Train
let history = network.train(
    x: trainData,
    y: trainLabels,
    epochs: 50,
    batchSize: 32,
    validationSplit: 0.2
)

// Predict
let predictions = network.predict(testData)
```

### Linear Regression

```swift
import SwiftAI

let model = LinearRegression()
model.fit(x: features, y: targets)

let predictions = model.predict(newData)
let r2 = model.score(x: testX, y: testY)
print("R² Score: \(r2)")
```

### Classification with Random Forest

```swift
import SwiftAI

let forest = RandomForestClassifier(
    nEstimators: 100,
    maxDepth: 10,
    maxFeatures: .sqrt
)

forest.fit(x: trainX, y: trainY)

let accuracy = forest.score(x: testX, y: testY)
print("Accuracy: \(accuracy * 100)%")

// Feature importance
if let importances = forest.featureImportances {
    for (i, imp) in importances.enumerated() {
        print("Feature \(i): \(imp)")
    }
}
```

### Clustering with K-Means

```swift
import SwiftAI

let kmeans = KMeans(nClusters: 5, initMethod: .kmeanspp)
kmeans.fit(data)

let labels = kmeans.predict(newData)
let silhouette = kmeans.silhouetteScore(data)
print("Silhouette Score: \(silhouette)")
```

## 📚 API Reference

### Neural Network Layers

| Layer | Description | Parameters |
|-------|-------------|------------|
| `Dense` | Fully connected layer | inputSize, outputSize, useBias |
| `ActivationLayer` | Activation function | activation |
| `Dropout` | Regularization | rate |
| `BatchNorm` | Batch normalization | numFeatures, epsilon, momentum |
| `LayerNorm` | Layer normalization | normalizedShape, epsilon |
| `Embedding` | Token embedding | numEmbeddings, embeddingDim |
| `Flatten` | Flatten tensor | - |

### Activation Functions

```swift
// Available activations
ActivationType.relu       // ReLU
ActivationType.leakyRelu  // Leaky ReLU (α=0.01)
ActivationType.elu        // ELU
ActivationType.selu       // SELU
ActivationType.sigmoid    // Sigmoid
ActivationType.tanh       // Tanh
ActivationType.softmax    // Softmax
ActivationType.swish      // Swish (SiLU)
ActivationType.gelu       // GELU
ActivationType.softplus   // Softplus
```

### Loss Functions

```swift
// Regression
LossType.mse             // Mean Squared Error
LossType.mae             // Mean Absolute Error
LossType.huber           // Huber Loss

// Classification
LossType.bce             // Binary Cross Entropy
LossType.bceWithLogits   // BCE with Logits
LossType.crossEntropy    // Cross Entropy
LossType.nll             // Negative Log Likelihood
LossType.hinge           // Hinge Loss (SVM)
```

### Optimizers

```swift
// Available optimizers
OptimizerType.sgd        // SGD with momentum
OptimizerType.adam       // Adam
OptimizerType.adamw      // AdamW (decoupled weight decay)
OptimizerType.rmsprop    // RMSprop
OptimizerType.adagrad    // Adagrad
```

### Classic ML Algorithms

| Algorithm | Type | Key Features |
|-----------|------|--------------|
| `LinearRegression` | Regression | OLS, L1/L2 regularization |
| `RidgeRegression` | Regression | L2 regularization |
| `LassoRegression` | Regression | L1 regularization |
| `ElasticNet` | Regression | L1 + L2 regularization |
| `LogisticRegression` | Classification | Binary/Multinomial |
| `DecisionTreeClassifier` | Classification | Gini/Entropy |
| `DecisionTreeRegressor` | Regression | MSE/MAE |
| `RandomForestClassifier` | Classification | Bootstrap, OOB |
| `RandomForestRegressor` | Regression | Feature importance |
| `GradientBoostingClassifier` | Classification | Boosting |
| `KMeans` | Clustering | K-means++ |
| `MiniBatchKMeans` | Clustering | Online learning |
| `DBSCAN` | Clustering | Density-based |
| `KNeighborsClassifier` | Classification | KD-tree |
| `KNeighborsRegressor` | Regression | Distance weighted |
| `SVC` | Classification | RBF/Linear/Poly |
| `SVR` | Regression | Epsilon-insensitive |

### Preprocessing

```swift
// Scalers
let scaler = StandardScaler()
let scaled = scaler.fitTransform(data)

let minmax = MinMaxScaler(featureRange: (0, 1))
let normalized = minmax.fitTransform(data)

let robust = RobustScaler()
let scaled = robust.fitTransform(data)

// Encoders
let encoder = OneHotEncoder()
let encoded = encoder.fitTransform(categories)

let labelEncoder = LabelEncoder()
let labels = labelEncoder.fitTransform(classes)

// Imputation
let imputer = SimpleImputer(strategy: .mean)
let filled = imputer.fitTransform(dataWithMissing)
```

### Metrics

```swift
// Classification
let accuracy = accuracyScore(yTrue: actual, yPred: predicted)
let (precision, recall, f1) = precisionRecallF1(yTrue: actual, yPred: predicted)
let confMatrix = confusionMatrix(yTrue: actual, yPred: predicted)
let auc = rocAucScore(yTrue: actual, yScore: probabilities)

// Regression
let mse = meanSquaredError(yTrue: actual, yPred: predicted)
let rmse = rootMeanSquaredError(yTrue: actual, yPred: predicted)
let mae = meanAbsoluteError(yTrue: actual, yPred: predicted)
let r2 = r2Score(yTrue: actual, yPred: predicted)

// Clustering
let silhouette = silhouetteScore(x: data, labels: clusters)
let db = daviesBouldinScore(x: data, labels: clusters)
```

### Model Export

```swift
// Export to JSON (cross-platform)
try network.exportToCoreML(
    url: URL(fileURLWithPath: "model.json"),
    inputName: "features",
    outputName: "predictions"
)

// Model compression
let (quantized, scale, zeroPoint) = ModelCompressor.quantize(
    weights: network.collectParameters().flatMap { $0.data },
    bits: 8
)
```

## 🏗️ Architecture

```
SwiftAI/
├── ML/
│   ├── Core/
│   │   ├── Tensor.swift          # SIMD-optimized tensors
│   │   ├── Activations.swift     # 10+ activation functions
│   │   ├── LossFunctions.swift   # 9+ loss functions
│   │   └── Optimizers.swift      # SGD, Adam, AdamW, RMSprop, Adagrad
│   │
│   ├── Neural/
│   │   ├── Layers.swift          # Dense, Dropout, BatchNorm, etc.
│   │   └── NeuralNetwork.swift   # Network builder & trainer
│   │
│   ├── Algorithms/
│   │   ├── LinearRegression.swift
│   │   ├── LogisticRegression.swift
│   │   ├── DecisionTree.swift
│   │   ├── RandomForest.swift
│   │   ├── KMeans.swift
│   │   ├── KNN.swift
│   │   └── SVM.swift
│   │
│   ├── Preprocessing/
│   │   └── DataPreprocessing.swift
│   │
│   ├── Evaluation/
│   │   └── Metrics.swift
│   │
│   └── Export/
│       └── CoreMLExport.swift
```

## ⚡ Performance

SwiftAI uses Apple's **Accelerate** framework for SIMD-optimized operations:

- **vDSP** for vector operations
- **cblas** for matrix multiplication
- **vvexp/vvlog/vvsqrt** for transcendental functions

| Operation | SwiftAI | Pure Swift |
|-----------|---------|------------|
| Matrix Multiply (1000×1000) | 12ms | 850ms |
| Vector Addition (1M) | 0.8ms | 15ms |
| Softmax (10K classes) | 0.3ms | 8ms |

## 🎯 Comparison

| Feature | SwiftAI | CreateML | Core ML | TensorFlow |
|---------|---------|----------|---------|------------|
| Pure Swift | ✅ | ✅ | ❌ | ❌ |
| Custom Models | ✅ | ❌ | ❌ | ✅ |
| Training | ✅ | ✅ | ❌ | ✅ |
| Classic ML | ✅ | Partial | ❌ | ✅ |
| Neural Networks | ✅ | ❌ | Inference | ✅ |
| No Dependencies | ✅ | ✅ | ✅ | ❌ |
| iOS Support | ✅ | ✅ | ✅ | Partial |
| Open Source | ✅ | ❌ | ❌ | ✅ |

## 📖 Tutorials

### Binary Classification

```swift
import SwiftAI

// Load data
let (trainX, testX, trainY, testY) = trainTestSplit(
    x: features,
    y: labels,
    testSize: 0.2,
    shuffle: true
)

// Preprocess
let scaler = StandardScaler()
let trainXScaled = scaler.fitTransform(trainX)
let testXScaled = scaler.transform(testX)

// Train
let model = LogisticRegression(regularization: .l2(strength: 0.1))
model.fit(x: trainXScaled, y: trainY, learningRate: 0.01)

// Evaluate
let accuracy = model.score(x: testXScaled, y: testY)
print("Accuracy: \(accuracy * 100)%")
print(model.classificationReport(x: testXScaled, y: testY))
```

### Cross-Validation

```swift
import SwiftAI

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

let meanScore = scores.reduce(0, +) / Float(scores.count)
print("CV Score: \(meanScore) ± \(standardDeviation(scores))")
```

## 🤝 Contributing

Contributions welcome! Please read our [Contributing Guide](CONTRIBUTING.md).

```bash
# Clone
git clone https://github.com/muhittinc/SwiftAI.git

# Build
swift build

# Test
swift test
```

## 📄 License

MIT License - see [LICENSE](LICENSE) for details.

---

<p align="center">
  <strong>Built with ❤️ in Swift</strong><br>
  <a href="https://github.com/muhittinc/SwiftAI/issues">Report Bug</a> •
  <a href="https://github.com/muhittinc/SwiftAI/issues">Request Feature</a>
</p>
