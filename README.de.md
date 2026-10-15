<!-- i18n-source: README.md@e0c55bc21df63f9a2618b00bda59aa525f4235d2 status=reviewed -->
<!-- brand:start -->

<p align="center"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/banner-de-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/banner-de-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/banner-de-light.svg" alt="SwiftAI: Maschinelles Lernen in reinem Swift: Modelle auf dem Gerät trainieren, bewerten und speichern."></picture></p>

<!-- lang-selector:start -->
<p align="center"><a href="README.md">English</a> · <a href="README.tr.md">Türkçe</a> · <a href="README.zh-CN.md">简体中文</a> · <a href="README.ja.md">日本語</a> · <a href="README.ko.md">한국어</a> · <a href="README.es.md">Español</a> · <a href="README.de.md">Deutsch</a> · <a href="README.fr.md">Français</a> · <a href="README.pt-BR.md">Português (Brasil)</a> · <a href="README.ru.md">Русский</a></p>
<!-- lang-selector:end -->

<p align="center">
<a href="https://github.com/muhittincamdali/SwiftAI/actions/workflows/ci.yml"><img src="https://github.com/muhittincamdali/SwiftAI/actions/workflows/ci.yml/badge.svg" alt="CI-Status"></a>
<a href="https://github.com/muhittincamdali/SwiftAI/releases"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/badge-version-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/badge-version-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/badge-version-light.svg" alt="Aktuelle Version: v2.0.0"></picture></a>
<a href="https://github.com/muhittincamdali/SwiftAI/blob/master/Package.swift"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/badge-platforms-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/badge-platforms-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/badge-platforms-light.svg" alt="Unterstützte Plattformen: iOS 15+ · macOS 12+ · tvOS 15+ · watchOS 8+ · visionOS 1+"></picture></a>
<a href="https://github.com/muhittincamdali/SwiftAI/blob/master/Package.swift"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/badge-language-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/badge-language-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/badge-language-light.svg" alt="Sprachversion: Swift 6.2+"></picture></a>
<a href="https://github.com/muhittincamdali/SwiftAI/blob/master/LICENSE"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/badge-license-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/badge-license-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/badge-license-light.svg" alt="Lizenz: MIT"></picture></a>
</p>

<p align="center">
<a href="#schnellstart"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/button-start-de-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/button-start-de-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/button-start-de-light.svg" alt="Loslegen"></picture></a>
<a href="https://muhittincamdali.github.io/SwiftAI/documentation/swiftai/"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/button-docs-de-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/button-docs-de-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/button-docs-de-light.svg" alt="Dokumentation"></picture></a>
<a href="https://github.com/muhittincamdali/SwiftAI/tree/master/Examples"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/button-examples-de-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/button-examples-de-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/button-examples-de-light.svg" alt="Beispiele"></picture></a>
</p>

> Dies ist eine Übersetzung der englischen README. Bei Abweichungen gilt die englische Fassung.

<!-- brand:end -->

SwiftAI ist ein Swift-Paket für klassisches maschinelles Lernen auf Apple-Plattformen: Klassifikation,
Regression, Clustering und Dimensionsreduktion auf Zahlentabellen. Es richtet sich an App-Entwickler,
die ein Modell mit Swift direkt auf dem Gerät trainieren oder ausführen wollen, ohne Python-Toolchain
und ohne Server. Du lädst Daten aus CSV oder Arrays, teilst sie auf, trainierst ein Modell mit einem
einzigen Funktionsaufruf, bewertest es und speicherst es als JSON, um es in deiner App zu laden.
Das Paket hat keine Abhängigkeiten.

## Highlights

- **Elf überwachte Modelle** — lineare Regression und Ridge-Regression, logistische Regression,
  k-nächste Nachbarn, Gaußscher Naive Bayes, Entscheidungsbäume, Random Forests und neuronale Netze
  (Klassifikator und Regressor, wo es passt), dazu k-Means-Clustering und Hauptkomponentenanalyse.
- **Gegen scikit-learn geprüft** — wo scikit-learn dasselbe Modell hat, verwendet SwiftAI dieselbe
  Zielfunktion und dieselben Standardwerte, und die Tests vergleichen Koeffizienten, Wahrscheinlichkeiten
  und Cluster mit scikit-learn 1.9.1 (zum Beispiel Wahrscheinlichkeiten der logistischen Regression auf 1e-5, PCA auf 1e-10).
- **Fehler statt Abstürze** — jede Funktion, die Daten oder Einstellungen entgegennimmt, validiert sie
  und wirft einen `SwiftAIError`, der sagt, was zu ändern ist: NaN-Werte, falsche Feature-Anzahl,
  überlaufende Summen, Einstellungen außerhalb des Bereichs, CSV-Zeilen, die keine Zahlen sind.
- **Sicher zu laden** — Modelle, Scaler und Pipelines sind `Codable`; beim Dekodieren werden Formen,
  Werte, Klassenlisten und Baumstruktur geprüft, sodass eine beschädigte oder manipulierte Datei keine
  Vorhersage zum Absturz bringen kann.
- **Reproduzierbar** — jeder Zufallsschritt (Aufteilungen, Forests, k-means++, Netzgewichte) nimmt einen
  `seed` entgegen; derselbe Seed liefert auf jeder Plattform dasselbe Modell, auch bei parallel trainierten Forests.
- **Swift 6, getestet** — baut im Swift-6-Sprachmodus mit strikter Concurrency-Prüfung und ohne
  Warnungen; 133 Swift-Testing-Tests laufen auf macOS und in einem iPhone-Simulator.

## Schnellstart

**1. Paket hinzufügen**

Wähle in Xcode **File › Add Package Dependencies…** und gib die Repository-URL ein:

```text
https://github.com/muhittincamdali/SwiftAI.git
```

**2. Modul importieren**

```swift
import SwiftAI
```

**3. Verwenden**

Ersetze in einer neuen Xcode-App (**File › New › Project… › App**) den gesamten Inhalt von
`ContentView.swift` durch:

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

Drücke **Run** (⌘R). Die App trainiert einen Random Forest mit den 150 im Paket enthaltenen
Iris-Blüten und zeigt den Anteil der Testblüten, die sie richtig klassifiziert hat, sowie die Art einer
neuen Blüte: `virginica`.

## Installation

### Swift Package Manager

Wähle in Xcode **File › Add Package Dependencies…** und gib die Repository-URL ein:

```text
https://github.com/muhittincamdali/SwiftAI.git
```

Oder füge es zu den `dependencies` in deiner `Package.swift` hinzu:

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

Version 2.0.0 (Oktober 2026) ist das erste Release der aktuellen Bibliothek. Das frühere Release,
1.0.0 (Februar 2026), liegt davor: Drei Tage nach seiner Veröffentlichung wurden die Module der
App-Architektur entfernt und ein kleinerer Machine-Learning-Kern geschrieben; im Juni 2026 wurde
dieser Kern umgebaut, seine Tests wurden auf einen einzigen Platzhaltertest reduziert und einige
kleine Stub-Layer kamen hinzu; im Oktober 2026 wurde die Bibliothek von Grund auf neu aufgebaut –
rund um validierte Daten, getestete Modelle und sichere Modelldateien. Die APIs sind nicht
kompatibel; [CHANGELOG.md](CHANGELOG.md) listet die Änderungen auf.

## Verwendung

Die folgenden Beispiele sind kopiert aus
[`Examples/ModelLab/ModelLab/ReadmeSamples.swift`](Examples/ModelLab/ModelLab/ReadmeSamples.swift).
Die Beispiel-App kompiliert diese Datei, und die Test-Suite kompiliert sie und führt jedes Beispiel aus.

### Eigene Daten laden

Eine CSV-Datei mit Kopfzeile wird zu einem Datensatz; jede Spalte außer dem Ziel muss Zahlen enthalten.

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

### Features skalieren und einen Klassifikator trainieren

Eine `Pipeline` passt den Scaler nur an die Trainingsdaten an und skaliert jedes spätere Sample auf dieselbe Weise.

```swift
let (training, test) = try Dataset.iris.stratifiedSplit(testFraction: 0.3, seed: 1)
let model = try Pipeline.fit(training, transformer: StandardScaler.fit) { scaled in
    try LogisticRegression.fit(scaled)
}
let report = try model.evaluate(on: test)
print(report)                       // precision, recall and F1 per class
print(report.confusionMatrix)
```

### Eine Zahl vorhersagen

Schreibe `Dataset<Double>` für Regressionsziele; ganzzahlige Literale würden ein `Dataset<Int>` ergeben.

```swift
// Size in square metres and number of rooms → price.
let houses = try Dataset<Double>(
    features: [[50, 1], [65, 2], [80, 2], [95, 3], [120, 3], [140, 4]],
    targets: [150_000, 190_000, 236_000, 280_000, 350_000, 405_000]
)
let model = try LinearRegression.fit(houses, regularization: 0.1)
let price = try model.predict([100, 3])
```

### Modelle per Kreuzvalidierung vergleichen

```swift
let data = Dataset.iris
let results = [
    "k-nearest neighbours": try data.crossValidate(folds: 5) { try KNearestNeighborsClassifier.fit($0, k: 7) },
    "naive Bayes": try data.crossValidate(folds: 5) { try GaussianNaiveBayes.fit($0) },
    "decision tree": try data.crossValidate(folds: 5) { try DecisionTreeClassifier.fit($0, maxDepth: 3) },
]
```

### Ein Modell speichern und in der App laden

```swift
let model = try RandomForestClassifier.fit(Dataset.iris, treeCount: 50, seed: 7)
let file = FileManager.default.temporaryDirectory.appendingPathComponent("iris-forest.json")

try JSONEncoder().encode(model).write(to: file)
let data = try Data(contentsOf: file)
let loaded = try JSONDecoder().decode(RandomForestClassifier<String>.self, from: data)
// `loaded` predicts exactly like `model`
```

### Gruppen ohne Labels finden

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
  <img src="docs/images/decision-boundaries-light.png" alt="Vier Klassifikatoren, trainiert auf den Blütenblatt-Maßen der Iris, mit der Art, die jeder über die Ebene hinweg vorhersagt, und ihrer kreuzvalidierten Genauigkeit (k-nächste Nachbarn 96,0 %, logistische Regression 95,3 %, Entscheidungsbaum 94,0 %, neuronales Netz 96,0 %)" width="780">
</picture>

Jede farbige Zelle ist eine Vorhersage des Modells, das auf den 150 Iris-Blüten trainiert wurde; die
Punkte sind die Blüten. Das Bild wird aus
[`Examples/ModelLab/ModelLab/DecisionBoundaries.swift`](Examples/ModelLab/ModelLab/DecisionBoundaries.swift)
mit [`scripts/generate-images.sh`](scripts/generate-images.sh) erzeugt; das Skript führt den Test aus,
der die vier Modelle trainiert.

Um die Modelle selbst auszuprobieren, öffne `ModelLab.xcodeproj` in [`Examples/ModelLab`](Examples/ModelLab)
mit Xcode, wähle einen iPhone-Simulator oder **My Mac** und drücke **Run**. Die App hat einen
Schnellstart-Tab, einen Bildschirm mit Schiebereglern, der eine Blüte mit dem gewählten Modell
klassifiziert, und dieses Bild; [Examples/README.md](Examples/README.md) enthält die Details.

## Dokumentation

API-Referenz und Artikel:

- [API-Referenz](https://muhittincamdali.github.io/SwiftAI/documentation/swiftai/)
  (DocC, von `master` auf GitHub Pages veröffentlicht)
- Baue sie lokal in Xcode mit **Product › Build Documentation** oder über die Kommandozeile:

```sh
xcodebuild docbuild -scheme SwiftAI -destination 'generic/platform=macOS'
```

## Anleitungen

- [Getting Started](https://muhittincamdali.github.io/SwiftAI/documentation/swiftai/gettingstarted)
  — das Paket hinzufügen, einen Klassifikator trainieren, bewerten und vorhersagen
  ([Quelle](Sources/SwiftAI/SwiftAI.docc/GettingStarted.md)).
- [Choosing a Model](https://muhittincamdali.github.io/SwiftAI/documentation/swiftai/choosingamodel)
  — wofür sich jedes Modell eignet, ob es skalierte Features braucht und welche Einstellungen zählen
  ([Quelle](Sources/SwiftAI/SwiftAI.docc/ChoosingAModel.md)).
- [Preparing Data](https://muhittincamdali.github.io/SwiftAI/documentation/swiftai/preparingdata)
  — CSV-Dateien, Aufteilungen, Skalieren mit einer Pipeline und PCA
  ([Quelle](Sources/SwiftAI/SwiftAI.docc/PreparingData.md)).
- [Saving and Loading Models](https://muhittincamdali.github.io/SwiftAI/documentation/swiftai/savingmodels)
  — ein trainiertes Modell als JSON ausliefern und was beim Laden geprüft wird
  ([Quelle](Sources/SwiftAI/SwiftAI.docc/SavingModels.md)).

## Voraussetzungen

| Plattform | Mindestversion |
| ------------------- | ------------------ |
| iOS | 15 |
| macOS | 12 |
| tvOS | 15 |
| watchOS | 8 |
| visionOS | 1 |
| Toolchain | Swift 6.2 · Xcode 26+ |

Die ModelLab-Beispiel-App benötigt iOS 17 oder macOS 14.

## Architektur

- `Sources/SwiftAI/Core/` enthält `Matrix` (ein zeilenweise gespeichertes `Double`-Raster; Produkte
  nutzen Accelerate), die Eingabeprüfungen, `SeededGenerator` (SplitMix64), den Kleinste-Quadrate-Löser
  mit Householder-QR und den L-BFGS-Optimierer.
- `Data/` enthält `Dataset` (Features plus Ziele, einmal beim Erstellen validiert), Aufteilung und
  Folds, `CSVTable` und die Iris-Daten. `Preprocessing/`, `Models/`, `Trees/`, `NeuralNetwork/`,
  `Clustering/` und `Evaluation/` enthalten den Rest, eine Modellfamilie pro Datei.
- Modelle sind unveränderliche Werttypen, die von einer statischen `fit`-Funktion erzeugt werden; ein
  Modellwert ist also immer trainiert. Klassifikatoren erfüllen `Classifier` (und `ProbabilisticClassifier`),
  Regressoren `Regressor`; gemeinsames Verhalten wie `accuracy(on:)`, `evaluate(on:)` und Batch-Vorhersage
  steckt in Protokoll-Extensions.
- Die Validierung findet an der öffentlichen Grenze statt (Datensatz erstellen, Fitten, Vorhersagen,
  Dekodieren); interner Code verlässt sich auf diese Prüfungen. Jede Schleife über vom Nutzer bestimmte Größen ist begrenzt.
- Entscheidungsbäume werden als Arrays gespeichert, in denen Kindknoten immer nach ihrem Elternknoten
  stehen; das Dekodieren erzwingt dies, sodass das Durchlaufen eines Baums immer endet.

Führe die Tests lokal aus:

```sh
swift test                                    # macOS
xcodebuild test -scheme SwiftAI -destination 'platform=iOS Simulator,name=iPhone 17'
```

## Roadmap

- Lineare Support Vector Machines, Lasso- und Elastic-Net-Regression sowie ein Transformer für
  polynomiale Features.
- Gradient-Boosted Trees.
- Export linearer Modelle und Bäume nach Core ML.
- Das Paket zum Swift Package Index hinzufügen; `.spi.yml` liegt bereits im Repository.

## Mitwirken

Beiträge sind willkommen. Lies vor einem Pull Request den [Leitfaden für Beiträge](https://github.com/muhittincamdali/SwiftAI/blob/master/CONTRIBUTING.md) und den [Verhaltenskodex](https://github.com/muhittincamdali/.github/blob/main/CODE_OF_CONDUCT.md). Sicherheitsprobleme meldest du vertraulich, wie in der [Sicherheitsrichtlinie](https://github.com/muhittincamdali/SwiftAI/blob/master/SECURITY.md) beschrieben.

## Lizenz

Veröffentlicht unter der MIT-Lizenz. Siehe [LICENSE](LICENSE).
