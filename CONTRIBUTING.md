# Contributing

Thanks for taking the time to improve SwiftAI.

## Reporting bugs

Open an issue with:

- the model or function and the arguments you used,
- a small dataset (or how to generate one) that shows the problem,
- what you expected and what happened, including the error message,
- platform, OS version and Xcode version.

For wrong numbers, a comparison with another library (for example scikit-learn with the same
settings) helps a lot.

## Pull requests

1. Fork the repository and branch from `master`.
2. Keep each pull request focused on one change.
3. Run the tests on macOS and an iOS simulator:

    ```sh
    swift test
    xcodebuild test -scheme SwiftAI -destination 'platform=iOS Simulator,name=iPhone 17'
    ```

4. Add a test for every change in behaviour in `Tests/SwiftAITests`. For a numerical algorithm,
   compare with reference values (say where they come from in a comment) and cover the edge
   cases: empty or single-sample data, constant features, NaN and infinite values, values near
   `Double.greatestFiniteMagnitude`, and invalid settings.
5. Public functions validate their input and throw `SwiftAIError`; they do not crash on bad
   data. A `Codable` type validates what it decodes, because model files can come from outside
   the app. Loops whose length depends on input or settings must be bounded.
6. If you change a README code sample, change the copy in
   `Examples/ModelLab/ModelLab/ReadmeSamples.swift` as well. That file is what gets compiled: by
   the example app, and by `swift test` through the symlink
   `Tests/SwiftAITests/ReadmeExamples.swift`, which also runs each sample. Build the app with:

    ```sh
    cd Examples/ModelLab
    xcodebuild build -scheme ModelLab -destination 'generic/platform=iOS Simulator'
    ```

7. If a change affects the README images, regenerate them with `scripts/generate-images.sh`.
8. `README.md` has translations (`README.<language>.md`). Each one records the version of
   `README.md` it follows, and CI fails while a translation is behind. If you change `README.md`
   and cannot update the translations, say so in the pull request and they will be updated
   before it is merged.

## Code style

- Follow the [Swift API Design Guidelines](https://www.swift.org/documentation/api-design-guidelines/).
- The package builds in the Swift 6 language mode; new code should not add warnings, and
  `xcodebuild docbuild` should stay free of documentation warnings.
- Models are immutable value types created by a static `fit` function.
- Document public API with DocC comments (`///`), including every parameter and what it throws.
- Commit messages follow [Conventional Commits](https://www.conventionalcommits.org/)
  (`feat:`, `fix:`, `docs:`, `test:`, `refactor:`, `ci:`, `chore:`).

## License

By contributing you agree that your contributions are licensed under the MIT License.
