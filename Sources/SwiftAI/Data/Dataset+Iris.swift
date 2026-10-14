extension Dataset where Target == String {
    /// Fisher's iris data: 150 flowers of three species, 50 each, with four measurements.
    ///
    /// The features are, in order, sepal length, sepal width, petal length and petal width in
    /// centimetres (see ``irisFeatureNames``). The targets are `"setosa"`, `"versicolor"` and
    /// `"virginica"`. Samples are sorted by species, so shuffle or split before training.
    ///
    /// ```swift
    /// let iris = Dataset<String>.iris
    /// iris.count          // 150
    /// iris.featureCount   // 4
    /// ```
    ///
    /// Source: R. A. Fisher, "The use of multiple measurements in taxonomic problems",
    /// Annals of Eugenics 7 (1936), measurements by Edgar Anderson.
    public static var iris: Dataset<String> {
        let species = ["setosa", "versicolor", "virginica"].flatMap { Array(repeating: $0, count: 50) }
        let features = Matrix(rows: 150, columns: 4, values: irisMeasurements)
        return Dataset(validFeatures: features, targets: species)
    }

    /// The names of the four columns of ``iris``.
    public static var irisFeatureNames: [String] {
        ["sepal length (cm)", "sepal width (cm)", "petal length (cm)", "petal width (cm)"]
    }
}
