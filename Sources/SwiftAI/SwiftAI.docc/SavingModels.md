# Saving and loading models

Train once, ship the model as a JSON file and load it in your app.

## Save

Every model, scaler and pipeline is `Codable` (classifiers when their label type is `Codable`).
Encode it with `JSONEncoder` or any other encoder:

```swift
let model = try RandomForestClassifier.fit(training, treeCount: 100, seed: 1)
let data = try JSONEncoder().encode(model)
try data.write(to: fileURL)
```

A ``Pipeline`` saves its transformer together with the model, so the app scales samples
exactly as during training.

## Load

Decode with the same type:

```swift
let data = try Data(contentsOf: Bundle.main.url(forResource: "flowers-forest", withExtension: "json")!)
let model = try JSONDecoder().decode(RandomForestClassifier<String>.self, from: data)
let species = try model.predict(sample)
```

To bundle a model with an app, train it in a test, a command-line tool or a playground, write
the JSON file, and add it to the app target's resources.

## What loading checks

A model file can come from a download, a cache or an older app version, so decoding checks it
before any prediction runs. Loading throws ``SwiftAIError/unreadableModel(reason:)`` (or a
`DecodingError` for malformed JSON) when, for example:

- a matrix's value count does not match its shape, including shapes whose product overflows;
- a value is NaN or infinite, a variance or scale is not positive, or a prior is outside 0...1;
- the class list is empty or repeats a class, or a target refers to a class that does not exist;
- a decision tree refers to a missing feature, or a child node that does not come after its
  parent (which could make prediction loop forever);
- the layers of a neural network do not fit together, or the parts of a pipeline disagree on
  the number of features.

A model that loads without an error is safe to predict with.

## Compatibility

The JSON layout of each type is part of the package's public API. A change to it is a breaking
change and is listed in the changelog.
