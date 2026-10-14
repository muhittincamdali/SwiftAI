# ``SwiftAI``

Train, evaluate and save machine learning models in pure Swift, on device.

## Overview

SwiftAI is a dependency-free Swift package for classical machine learning on Apple platforms:
classification, regression, clustering and dimensionality reduction on tables of numbers. You
load data from CSV or arrays, split it, train a model with one function call, measure it, and
save it as JSON to load in your app.

```swift
import SwiftAI

let (training, test) = try Dataset.iris.stratifiedSplit(testFraction: 0.2, seed: 42)
let model = try RandomForestClassifier.fit(training, seed: 42)
let accuracy = try model.accuracy(on: test)
let species = try model.predict([6.3, 2.8, 5.1, 1.5])
```

Every model is a value type that is `Sendable` and `Codable`. Every function that takes data or
settings validates them and throws a ``SwiftAIError`` that says what to change, instead of
crashing or returning NaN. Training that involves randomness takes a `seed`, so results are
reproducible on every platform.

Where scikit-learn has the same model, SwiftAI uses the same objective and defaults, and the
tests compare results with scikit-learn's.

## Topics

### Essentials

- <doc:GettingStarted>
- <doc:ChoosingAModel>
- <doc:PreparingData>
- <doc:SavingModels>

### Data

- ``Dataset``
- ``Matrix``
- ``CSVTable``
- ``SeededGenerator``

### Classification

- ``Classifier``
- ``ProbabilisticClassifier``
- ``LogisticRegression``
- ``KNearestNeighborsClassifier``
- ``GaussianNaiveBayes``
- ``DecisionTreeClassifier``
- ``RandomForestClassifier``
- ``NeuralNetworkClassifier``
- ``NeighborWeighting``

### Regression

- ``Regressor``
- ``LinearRegression``
- ``KNearestNeighborsRegressor``
- ``DecisionTreeRegressor``
- ``RandomForestRegressor``
- ``NeuralNetworkRegressor``

### Clustering

- ``KMeans``

### Preprocessing

- ``FeatureTransformer``
- ``StandardScaler``
- ``MinMaxScaler``
- ``PrincipalComponentAnalysis``
- ``Pipeline``

### Evaluation

- ``Metrics``
- ``ClassificationReport``
- ``ClassMetrics``
- ``ConfusionMatrix``
- ``RegressionReport``
- ``CrossValidationResult``

### Errors

- ``SwiftAIError``
