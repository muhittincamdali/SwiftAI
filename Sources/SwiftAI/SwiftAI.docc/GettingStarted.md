# Getting started

Add SwiftAI to an app, train a first classifier and check how well it works.

## Add the package

In Xcode, choose **File › Add Package Dependencies…**, enter
`https://github.com/muhittincamdali/SwiftAI.git`, keep **Up to Next Major Version** from
`2.0.0`, and add the **SwiftAI** library to your app target.

In a `Package.swift`:

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

## Train a classifier

A ``Dataset`` pairs a feature matrix (one row per sample) with one target per row. The package
ships Fisher's iris flowers as ``Dataset/iris``: 150 flowers, four measurements each, three
species.

```swift
import SwiftAI

let (training, test) = try Dataset.iris.stratifiedSplit(testFraction: 0.2, seed: 42)
let model = try RandomForestClassifier.fit(training, seed: 42)
```

``Dataset/stratifiedSplit(testFraction:seed:)`` keeps the share of each species the same in
both parts. The model never sees the test samples, so they show how it does on new data.

## Measure it

```swift
let accuracy = try model.accuracy(on: test)      // share of correct predictions
let report = try model.evaluate(on: test)        // precision, recall and F1 per class
print(report)
print(report.confusionMatrix)
```

One split can be lucky. ``Dataset/crossValidate(folds:seed:fit:)-(_,_,(Dataset<Target>)->Model)``
trains on several splits and reports the mean and spread of the scores:

```swift
let result = try Dataset.iris.crossValidate(folds: 5) { training in
    try RandomForestClassifier.fit(training, treeCount: 50)
}
print(result.mean, result.standardDeviation)
```

## Predict

```swift
let species = try model.predict([6.3, 2.8, 5.1, 1.5])          // "virginica"
let odds = try model.probabilities([6.3, 2.8, 5.1, 1.5])       // ["virginica": 0.9, ...]
```

A sample with the wrong number of features, or with NaN, throws
``SwiftAIError/featureCountMismatch(expected:actual:)`` or
``SwiftAIError/nonFiniteValue(row:column:)``.

## Next steps

- <doc:ChoosingAModel> compares the models.
- <doc:PreparingData> loads your own CSV data and scales features.
- <doc:SavingModels> trains once and ships the model in your app.
