# Examples

## ModelLab

A small iOS and macOS app built on SwiftAI. It uses the package from this checkout (a local
package reference to `../..`), so it always runs the current code. It has three tabs:

- **Quick start** — the README's quick start: trains a random forest on the iris flowers and
  shows its test accuracy and the species of a new flower.
- **Classify** — four sliders for the petal and sepal measurements, a model picker (random
  forest, logistic regression, k-nearest neighbours, naive Bayes) and the probability of each
  species.
- **Boundaries** — four classifiers trained on the petal measurements, with the species each
  one predicts across the plane: the image in the README.

Run it:

1. Open `Examples/ModelLab/ModelLab.xcodeproj` in Xcode 26 or later.
2. Choose the **ModelLab** scheme and an iPhone simulator or **My Mac** as the run destination.
3. Press **Run** (⌘R).

From the command line:

```sh
cd Examples/ModelLab
xcodebuild build -scheme ModelLab -destination 'generic/platform=iOS Simulator'
xcodebuild build -scheme ModelLab -destination 'platform=macOS'
```

The README's code samples live in
[`ModelLab/ReadmeSamples.swift`](ModelLab/ModelLab/ReadmeSamples.swift). The app and the
package's test target both compile that file (through the symlink
`Tests/SwiftAITests/ReadmeExamples.swift`), and the tests run every sample and check its result.
[`ModelLab/DecisionBoundaries.swift`](ModelLab/ModelLab/DecisionBoundaries.swift) is shared the
same way; [`scripts/generate-images.sh`](../scripts/generate-images.sh) renders it into the
README images.

The project file is made with [XcodeGen](https://github.com/yonaskolb/XcodeGen) from
[`project.yml`](ModelLab/project.yml) and committed, so you only need XcodeGen after editing
`project.yml`.
