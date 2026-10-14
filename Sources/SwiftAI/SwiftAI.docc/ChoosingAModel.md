# Choosing a model

Pick a model from what your data looks like and what the app needs.

## Classification: predict a label

| Model                         | Good at                                                                | Needs scaled features | Probabilities |
| ----------------------------- | ---------------------------------------------------------------------- | --------------------- | ------------- |
| ``LogisticRegression``          | A fast, explainable baseline; classes separated by straight boundaries | Recommended           | Yes           |
| ``GaussianNaiveBayes``          | Very little training data; trains in one pass                          | No                    | Yes           |
| ``KNearestNeighborsClassifier`` | Irregular boundaries with few features; no training step               | Yes                   | Vote shares   |
| ``DecisionTreeClassifier``      | Rules you can read; mixed feature ranges                               | No                    | Leaf shares   |
| ``RandomForestClassifier``      | A strong default for tabular data; robust to noise                     | No                    | Tree average  |
| ``NeuralNetworkClassifier``     | Complex boundaries with enough data                                    | Yes                   | Yes           |

Start with ``RandomForestClassifier`` or ``LogisticRegression``, then compare candidates with
``Dataset/crossValidate(folds:seed:fit:)-(_,_,(Dataset<Target>)->Model)`` on your own data:

```swift
let candidates: [String: (Dataset<String>) throws -> any Classifier<String>] = [
    "forest": { try RandomForestClassifier.fit($0, treeCount: 100) },
    "bayes": { try GaussianNaiveBayes.fit($0) },
]
for (name, fit) in candidates {
    let scores = try data.stratifiedFolds(5).map { fold in
        try fit(fold.training).accuracy(on: fold.validation)
    }
    print(name, scores.reduce(0, +) / Double(scores.count))
}
```

## Regression: predict a number

| Model                        | Good at                                                                                            |
| ---------------------------- | -------------------------------------------------------------------------------------------------- |
| ``LinearRegression``           | Effects that add up; coefficients you can read. Use `regularization` when features are correlated. |
| ``KNearestNeighborsRegressor`` | Smooth, local patterns with few features                                                           |
| ``DecisionTreeRegressor``      | Step-like patterns and readable rules                                                              |
| ``RandomForestRegressor``      | Non-linear patterns in tabular data                                                                |
| ``NeuralNetworkRegressor``     | Smooth non-linear patterns with enough data                                                        |

Measure regressors with ``Regressor/evaluate(on:)``, which reports the mean squared error, its
root, the mean absolute error and R².

## Without labels

``KMeans`` groups samples into a given number of clusters. ``PrincipalComponentAnalysis``
projects samples onto fewer dimensions, for plotting or as a preprocessing step.

## Settings that matter most

- Trees and forests: `maxDepth` and `minSamplesLeaf` limit how closely a tree follows the
  training data. A tree without limits memorizes noise; a forest averages that out.
- k-nearest neighbours: a larger `k` gives smoother boundaries.
- Logistic regression: a larger `regularization` keeps the weights small; `converged` tells you
  whether training reached its tolerance.
- Neural networks: `hiddenLayers`, `learningRate` and `epochs`. Check `lossCurve` to see whether
  the loss is still falling.
