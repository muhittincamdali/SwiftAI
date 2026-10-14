# Preparing data

Load your own data, split it fairly and scale features without leaking test data.

## Load a CSV file

The first row names the columns. Every column except the target must hold numbers.

```swift
let table = try CSVTable(contentsOf: Bundle.main.url(forResource: "flowers", withExtension: "csv")!)
let flowers = try table.classificationDataset(target: "species")   // Dataset<String>
let names = table.featureNames(excluding: "species")
```

Use ``CSVTable/regressionDataset(target:)`` when the target is a number. Quoted fields,
`\r\n` line endings and other separators (`CSVTable(text, separator: ";")`) are supported. A
value that is not a number, such as `"n/a"`, throws ``SwiftAIError/invalidCSV(line:reason:)``
with the line and column, so you can fix the file.

## Build a dataset in code

```swift
let houses = try Dataset<Double>(
    features: [[50, 1], [80, 2], [120, 3]],     // size in m², rooms
    targets: [150_000, 240_000, 360_000]
)
```

Write `Dataset<Double>` for regression: integer literals would otherwise make `Dataset<Int>`.
Creating a dataset checks that rows have the same length, that every value is finite and that
there is one target per row.

## Split

- ``Dataset/split(testFraction:seed:)`` for regression.
- ``Dataset/stratifiedSplit(testFraction:seed:)`` for classification; it keeps class shares.
- ``Dataset/folds(_:seed:)`` and ``Dataset/stratifiedFolds(_:seed:)`` for cross-validation.

The same seed always gives the same split.

## Scale features

Models that measure distances or follow gradients (k-nearest neighbours, logistic regression,
neural networks, k-means) work best when features have similar ranges. ``StandardScaler``
gives each feature mean 0 and standard deviation 1; ``MinMaxScaler`` maps it to 0...1.

Fit the scaler on the training data only. ``Pipeline`` does this for you and applies the same
scaling to every later sample:

```swift
let model = try Pipeline.fit(training, transformer: StandardScaler.fit) { scaled in
    try KNearestNeighborsClassifier.fit(scaled, k: 5)
}
let label = try model.predict(rawSample)   // scaled inside the pipeline
```

## Reduce dimensions

```swift
let pca = try PrincipalComponentAnalysis.fit(training.features, componentCount: 2)
print(pca.explainedVarianceRatio)
let points = try pca.transform(training.features)
```

``PrincipalComponentAnalysis`` is a ``FeatureTransformer``, so it can be the transformer of a
``Pipeline`` too.
