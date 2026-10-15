<!-- brand:start -->

<p align="center"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/banner-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/banner-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/banner-light.svg" alt="SwiftAI: Machine learning in pure Swift: train, evaluate and save models on device."></picture></p>

<!-- lang-selector:start -->
<p align="center"><a href="README.md">English</a> · <a href="README.tr.md">Türkçe</a> · <a href="README.zh-CN.md">简体中文</a> · <a href="README.ja.md">日本語</a> · <a href="README.ko.md">한국어</a> · <a href="README.es.md">Español</a> · <a href="README.de.md">Deutsch</a> · <a href="README.fr.md">Français</a> · <a href="README.pt-BR.md">Português (Brasil)</a> · <a href="README.ru.md">Русский</a></p>
<!-- lang-selector:end -->

<p align="center">
<a href="https://github.com/muhittincamdali/SwiftAI/actions/workflows/ci.yml"><img src="https://github.com/muhittincamdali/SwiftAI/actions/workflows/ci.yml/badge.svg" alt="CI status"></a>
<a href="https://github.com/muhittincamdali/SwiftAI/releases"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/badge-version-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/badge-version-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/badge-version-light.svg" alt="Latest version: v2.0.0"></picture></a>
<a href="https://github.com/muhittincamdali/SwiftAI/blob/master/Package.swift"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/badge-platforms-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/badge-platforms-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/badge-platforms-light.svg" alt="Supported platforms: iOS 15+ · macOS 12+ · tvOS 15+ · watchOS 8+ · visionOS 1+"></picture></a>
<a href="https://github.com/muhittincamdali/SwiftAI/blob/master/Package.swift"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/badge-language-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/badge-language-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/badge-language-light.svg" alt="Language version: Swift 6.2+"></picture></a>
<a href="https://github.com/muhittincamdali/SwiftAI/blob/master/LICENSE"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/badge-license-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/badge-license-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/badge-license-light.svg" alt="License: MIT"></picture></a>
</p>

<p align="center">
<a href="#quick-start"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/button-start-en-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/button-start-en-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/button-start-en-light.svg" alt="Get started"></picture></a>
<a href="https://muhittincamdali.github.io/SwiftAI/documentation/swiftai/"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/button-docs-en-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/button-docs-en-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/button-docs-en-light.svg" alt="Documentation"></picture></a>
<a href="https://github.com/muhittincamdali/SwiftAI/tree/master/Examples"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/button-examples-en-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/button-examples-en-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/button-examples-en-light.svg" alt="Examples"></picture></a>
</p>

<!-- brand:end -->

SwiftAI is a Swift package for classical machine learning on Apple platforms: classification,
regression, clustering and dimensionality reduction on tables of numbers. It is for app
developers who want to train or run a model on device, in Swift, without a Python toolchain or a
server. You load data from CSV or arrays, split it, train a model with one function call,
measure it, and save it as JSON to load in your app. The package has no dependencies.

## Highlights

- **Eleven supervised models** — linear and ridge regression, logistic regression, k-nearest neighbours,
  Gaussian naive Bayes, decision trees, random forests and neural networks (classifier and
  regressor where it applies), plus k-means clustering and principal component analysis.
- **Checked against scikit-learn** — where scikit-learn has the same model, SwiftAI uses the same
  objective and defaults, and the tests compare coefficients, probabilities and clusters with
  scikit-learn 1.9.1 (for example logistic regression probabilities to 1e-5, PCA to 1e-10).
- **Errors instead of crashes** — every function that takes data or settings validates it and
  throws a `SwiftAIError` that says what to change: NaN values, wrong feature counts, sums that
  overflow, settings out of range, CSV lines that are not numbers.
- **Safe to load** — models, scalers and pipelines are `Codable`; decoding checks shapes, values,
  class lists and tree structure, so a damaged or crafted file cannot crash a prediction.
- **Reproducible** — every random step (splits, forests, k-means++, network weights) takes a
  `seed`; the same seed gives the same model on every platform, also for forests trained in
  parallel.
- **Swift 6, tested** — builds in the Swift 6 language mode with strict concurrency checking and
  no warnings; 133 Swift Testing tests run on macOS and an iPhone simulator.

## Quick start

**1. Add the package**

In Xcode, choose **File › Add Package Dependencies…** and enter the repository URL:

```text
https://github.com/muhittincamdali/SwiftAI.git
```

**2. Import the module**

```swift
import SwiftAI
```

**3. Use it**

In a new Xcode app (**File › New › Project… › App**), replace everything in `ContentView.swift`
with:

```swift
import SwiftUI
import SwiftAI

struct ContentView: View {
    var body: some View {
        Text(irisSummary())
            .padding()
    }

    func irisSummary() -> String {
        do {
            // 1. Split the built-in iris flowers into training and test samples.
            let (training, test) = try Dataset.iris.stratifiedSplit(testFraction: 0.2, seed: 42)
            // 2. Train a random forest on the training samples.
            let model = try RandomForestClassifier.fit(training, seed: 42)
            // 3. Measure it on the test samples and classify a new flower.
            let accuracy = try model.accuracy(on: test)
            let species = try model.predict([6.3, 2.8, 5.1, 1.5])
            return "Test accuracy: \(accuracy.formatted(.percent))\nNew flower: \(species)"
        } catch {
            return error.localizedDescription
        }
    }
}
```

Press **Run** (⌘R). The app trains a random forest on the 150 iris flowers that ship with the
package and shows the share of test flowers it classified correctly and the species of a new
flower: `virginica`.

## Installation

### Swift Package Manager

In Xcode, choose **File › Add Package Dependencies…** and enter the repository URL:

```text
https://github.com/muhittincamdali/SwiftAI.git
```

Or add it to the `dependencies` in your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/muhittincamdali/SwiftAI.git", from: "2.0.0")
],
targets: [
    .target(name: "YourApp", dependencies: [
        .product(name: "SwiftAI", package: "SwiftAI")
    ])
]
```

Version 2.0.0 (October 2026) is the first release of the current library. The earlier release,
1.0.0 (February 2026), predates it: three days after its release the app-architecture modules were
removed and a smaller machine learning core was written; in June 2026 that core was refactored, its
tests were reduced to a single placeholder test and a few small stub layers were added; in October
2026 the library was rebuilt from scratch around validated data, tested models and safe model files.
The APIs are not compatible; [CHANGELOG.md](CHANGELOG.md) lists the changes.

## Usage

The samples below are copied from
[`Examples/ModelLab/ModelLab/ReadmeSamples.swift`](Examples/ModelLab/ModelLab/ReadmeSamples.swift).
The example app compiles that file, and the test suite compiles it and runs every sample.

### Load your own data

A CSV file with a header row becomes a dataset; every column except the target must hold numbers.

```swift
let csv = """
    petal_length,petal_width,species
    1.4,0.2,setosa
    4.7,1.4,versicolor
    6.0,2.5,virginica
    1.3,0.2,setosa
    4.5,1.5,versicolor
    5.1,1.9,virginica
    """
let table = try CSVTable(csv)   // or CSVTable(contentsOf: fileURL)
let data = try table.classificationDataset(target: "species")
```

### Scale features and train a classifier

A `Pipeline` fits the scaler on the training data only and scales every later sample the same way.

```swift
let (training, test) = try Dataset.iris.stratifiedSplit(testFraction: 0.3, seed: 1)
let model = try Pipeline.fit(training, transformer: StandardScaler.fit) { scaled in
    try LogisticRegression.fit(scaled)
}
let report = try model.evaluate(on: test)
print(report)                       // precision, recall and F1 per class
print(report.confusionMatrix)
```

### Predict a number

Write `Dataset<Double>` for regression targets; integer literals would make a `Dataset<Int>`.

```swift
// Size in square metres and number of rooms → price.
let houses = try Dataset<Double>(
    features: [[50, 1], [65, 2], [80, 2], [95, 3], [120, 3], [140, 4]],
    targets: [150_000, 190_000, 236_000, 280_000, 350_000, 405_000]
)
let model = try LinearRegression.fit(houses, regularization: 0.1)
let price = try model.predict([100, 3])
```

### Compare models with cross-validation

```swift
let data = Dataset.iris
let results = [
    "k-nearest neighbours": try data.crossValidate(folds: 5) { try KNearestNeighborsClassifier.fit($0, k: 7) },
    "naive Bayes": try data.crossValidate(folds: 5) { try GaussianNaiveBayes.fit($0) },
    "decision tree": try data.crossValidate(folds: 5) { try DecisionTreeClassifier.fit($0, maxDepth: 3) },
]
```

### Save a model and load it in the app

```swift
let model = try RandomForestClassifier.fit(Dataset.iris, treeCount: 50, seed: 7)
let file = FileManager.default.temporaryDirectory.appendingPathComponent("iris-forest.json")

try JSONEncoder().encode(model).write(to: file)
let data = try Data(contentsOf: file)
let loaded = try JSONDecoder().decode(RandomForestClassifier<String>.self, from: data)
// `loaded` predicts exactly like `model`
```

### Find groups without labels

```swift
let features = Dataset.iris.features
let pca = try PrincipalComponentAnalysis.fit(features, componentCount: 2)
let points = try pca.transform(features)          // 150 × 2, for a scatter plot
let kMeans = try KMeans.fit(points, clusterCount: 3, seed: 1)
let clusters = try kMeans.predict(points)          // 0, 1 or 2 per flower
```

## Demo

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="docs/images/decision-boundaries-dark.png">
  <img src="docs/images/decision-boundaries-light.png" alt="Four classifiers trained on the iris petal measurements, with the species each predicts across the plane and their cross-validated accuracy (k-nearest neighbours 96.0%, logistic regression 95.3%, decision tree 94.0%, neural network 96.0%)" width="780">
</picture>

Each coloured cell is a prediction of the model trained on the 150 iris flowers; the dots are
the flowers. The image is rendered from
[`Examples/ModelLab/ModelLab/DecisionBoundaries.swift`](Examples/ModelLab/ModelLab/DecisionBoundaries.swift)
by [`scripts/generate-images.sh`](scripts/generate-images.sh), which runs the test that trains
the four models.

To try the models yourself, open `ModelLab.xcodeproj` in [`Examples/ModelLab`](Examples/ModelLab)
with Xcode, choose an iPhone simulator or **My Mac**, and press **Run**. The app has a quick start
tab, a screen with sliders that classifies a flower with the model you pick, and this image;
[Examples/README.md](Examples/README.md) has the details.

## Documentation

Reference documentation and articles:

- [API reference](https://muhittincamdali.github.io/SwiftAI/documentation/swiftai/)
  (DocC, published to GitHub Pages from `master`)
- Build it locally in Xcode with **Product › Build Documentation**, or from the command line:

```sh
xcodebuild docbuild -scheme SwiftAI -destination 'generic/platform=macOS'
```

## Guides

- [Getting Started](https://muhittincamdali.github.io/SwiftAI/documentation/swiftai/gettingstarted)
  — add the package, train a classifier, measure it and predict
  ([source](Sources/SwiftAI/SwiftAI.docc/GettingStarted.md)).
- [Choosing a Model](https://muhittincamdali.github.io/SwiftAI/documentation/swiftai/choosingamodel)
  — what each model is good at, whether it needs scaled features, and the settings that matter
  ([source](Sources/SwiftAI/SwiftAI.docc/ChoosingAModel.md)).
- [Preparing Data](https://muhittincamdali.github.io/SwiftAI/documentation/swiftai/preparingdata)
  — CSV files, splits, scaling with a pipeline and PCA
  ([source](Sources/SwiftAI/SwiftAI.docc/PreparingData.md)).
- [Saving and Loading Models](https://muhittincamdali.github.io/SwiftAI/documentation/swiftai/savingmodels)
  — ship a trained model as JSON, and what loading checks
  ([source](Sources/SwiftAI/SwiftAI.docc/SavingModels.md)).

## Requirements

| Platform | Minimum version |
| ------------------- | ------------------ |
| iOS | 15 |
| macOS | 12 |
| tvOS | 15 |
| watchOS | 8 |
| visionOS | 1 |
| Toolchain | Swift 6.2 · Xcode 26+ |

The ModelLab example app needs iOS 17 or macOS 14.

## Architecture

- `Sources/SwiftAI/Core/` holds `Matrix` (a row-major `Double` grid; products use Accelerate),
  the input checks, `SeededGenerator` (SplitMix64), the Householder QR least-squares solver and
  the L-BFGS optimizer.
- `Data/` has `Dataset` (features plus targets, validated once at creation), splitting and
  folds, `CSVTable` and the iris data. `Preprocessing/`, `Models/`, `Trees/`, `NeuralNetwork/`,
  `Clustering/` and `Evaluation/` hold the rest, one model family per file.
- Models are immutable value types made by a static `fit` function, so a model value is always
  trained. Classifiers conform to `Classifier` (and `ProbabilisticClassifier`), regressors to
  `Regressor`; shared behaviour such as `accuracy(on:)`, `evaluate(on:)` and batch prediction
  lives in protocol extensions.
- Validation happens at the public boundary (creating a dataset, fitting, predicting, decoding);
  internal code relies on those checks. Every loop over user-controlled sizes is bounded.
- Decision trees are stored as arrays in which children always come after their parent; decoding
  enforces this, so walking a tree always ends.

Run the tests locally:

```sh
swift test                                    # macOS
xcodebuild test -scheme SwiftAI -destination 'platform=iOS Simulator,name=iPhone 17'
```

## Roadmap

- Linear support vector machines, lasso and elastic-net regression, and a polynomial-features
  transformer.
- Gradient-boosted trees.
- Export of linear models and trees to Core ML.
- Add the package to the Swift Package Index; `.spi.yml` is already in the repository.

## Contributing

Contributions are welcome. Read the [contributing guide](https://github.com/muhittincamdali/SwiftAI/blob/master/CONTRIBUTING.md) and the [code of conduct](https://github.com/muhittincamdali/.github/blob/main/CODE_OF_CONDUCT.md) before opening a pull request. Report security issues privately as described in the [security policy](https://github.com/muhittincamdali/SwiftAI/blob/master/SECURITY.md).

## License

Released under the MIT license. See [LICENSE](LICENSE).
