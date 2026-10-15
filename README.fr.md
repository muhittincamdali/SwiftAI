<!-- i18n-source: README.md@e0c55bc21df63f9a2618b00bda59aa525f4235d2 status=reviewed -->
<!-- brand:start -->

<p align="center"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/banner-fr-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/banner-fr-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/banner-fr-light.svg" alt="SwiftAI: L’apprentissage automatique en Swift pur : entraînez, évaluez et enregistrez des modèles sur l’appareil."></picture></p>

<!-- lang-selector:start -->
<p align="center"><a href="README.md">English</a> · <a href="README.tr.md">Türkçe</a> · <a href="README.zh-CN.md">简体中文</a> · <a href="README.ja.md">日本語</a> · <a href="README.ko.md">한국어</a> · <a href="README.es.md">Español</a> · <a href="README.de.md">Deutsch</a> · <a href="README.fr.md">Français</a> · <a href="README.pt-BR.md">Português (Brasil)</a> · <a href="README.ru.md">Русский</a></p>
<!-- lang-selector:end -->

<p align="center">
<a href="https://github.com/muhittincamdali/SwiftAI/actions/workflows/ci.yml"><img src="https://github.com/muhittincamdali/SwiftAI/actions/workflows/ci.yml/badge.svg" alt="État de la CI"></a>
<a href="https://github.com/muhittincamdali/SwiftAI/releases"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/badge-version-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/badge-version-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/badge-version-light.svg" alt="Dernière version: v2.0.0"></picture></a>
<a href="https://github.com/muhittincamdali/SwiftAI/blob/master/Package.swift"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/badge-platforms-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/badge-platforms-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/badge-platforms-light.svg" alt="Plateformes prises en charge: iOS 15+ · macOS 12+ · tvOS 15+ · watchOS 8+ · visionOS 1+"></picture></a>
<a href="https://github.com/muhittincamdali/SwiftAI/blob/master/Package.swift"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/badge-language-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/badge-language-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/badge-language-light.svg" alt="Version du langage: Swift 6.2+"></picture></a>
<a href="https://github.com/muhittincamdali/SwiftAI/blob/master/LICENSE"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/badge-license-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/badge-license-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/badge-license-light.svg" alt="Licence: MIT"></picture></a>
</p>

<p align="center">
<a href="#démarrage-rapide"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/button-start-fr-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/button-start-fr-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/button-start-fr-light.svg" alt="Commencer"></picture></a>
<a href="https://muhittincamdali.github.io/SwiftAI/documentation/swiftai/"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/button-docs-fr-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/button-docs-fr-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/button-docs-fr-light.svg" alt="Documentation"></picture></a>
<a href="https://github.com/muhittincamdali/SwiftAI/tree/master/Examples"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/button-examples-fr-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/button-examples-fr-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/button-examples-fr-light.svg" alt="Exemples"></picture></a>
</p>

> Ceci est une traduction du README anglais. En cas de différence, la version anglaise fait foi.

<!-- brand:end -->

SwiftAI est un package Swift pour l’apprentissage automatique classique sur les plateformes Apple :
classification, régression, clustering et réduction de dimension sur des tableaux de nombres. Il
s’adresse aux développeurs d’apps qui veulent entraîner ou exécuter un modèle sur l’appareil, en Swift,
sans chaîne d’outils Python ni serveur. Vous chargez les données depuis un CSV ou des tableaux, vous les
séparez, vous entraînez un modèle en un seul appel de fonction, vous le mesurez, puis vous
l’enregistrez en JSON pour le charger dans votre app. Le package n’a aucune dépendance.

## Points forts

- **Onze modèles supervisés** — régression linéaire et ridge, régression logistique, k plus proches
  voisins, Bayes naïf gaussien, arbres de décision, forêts aléatoires et réseaux de neurones
  (classifieur et régresseur lorsque c’est pertinent), ainsi que le clustering k-means et l’analyse en composantes principales.
- **Vérifié face à scikit-learn** — lorsque scikit-learn propose le même modèle, SwiftAI utilise le même
  objectif et les mêmes valeurs par défaut, et les tests comparent coefficients, probabilités et clusters
  avec scikit-learn 1.9.1 (par exemple les probabilités de la régression logistique à 1e-5, l’ACP à 1e-10).
- **Des erreurs plutôt que des plantages** — chaque fonction qui reçoit des données ou des réglages les
  valide et lève une `SwiftAIError` qui indique quoi corriger : valeurs NaN, nombre de caractéristiques
  incorrect, sommes qui débordent, réglages hors limites, lignes CSV qui ne sont pas des nombres.
- **Chargement sûr** — les modèles, les scalers et les pipelines sont `Codable` ; le décodage vérifie les
  formes, les valeurs, les listes de classes et la structure des arbres, si bien qu’un fichier endommagé
  ou forgé ne peut pas faire planter une prédiction.
- **Reproductible** — chaque étape aléatoire (séparations, forêts, k-means++, poids du réseau) prend un
  `seed` ; le même seed donne le même modèle sur toutes les plateformes, y compris pour les forêts entraînées en parallèle.
- **Swift 6, testé** — compile en mode de langage Swift 6 avec vérification stricte de la concurrence et
  sans avertissement ; 133 tests Swift Testing s’exécutent sur macOS et dans un simulateur d’iPhone.

## Démarrage rapide

**1. Ajouter le paquet**

Dans Xcode, choisissez **File › Add Package Dependencies…** et saisissez l’URL du dépôt :

```text
https://github.com/muhittincamdali/SwiftAI.git
```

**2. Importer le module**

```swift
import SwiftAI
```

**3. L’utiliser**

Dans une nouvelle app Xcode (**File › New › Project… › App**), remplacez tout le contenu de
`ContentView.swift` par :

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

Appuyez sur **Run** (⌘R). L’app entraîne une forêt aléatoire sur les 150 fleurs d’iris livrées avec
le package, puis affiche la part des fleurs de test classées correctement et l’espèce d’une nouvelle
fleur : `virginica`.

## Installation

### Swift Package Manager

Dans Xcode, choisissez **File › Add Package Dependencies…** et saisissez l’URL du dépôt :

```text
https://github.com/muhittincamdali/SwiftAI.git
```

Ou ajoutez-le aux `dependencies` de votre `Package.swift` :

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

La version 2.0.0 (octobre 2026) est la première version de la bibliothèque actuelle. La version
précédente, 1.0.0 (février 2026), lui est antérieure : trois jours après sa publication, les modules
d'architecture applicative ont été supprimés et un noyau d'apprentissage automatique plus petit a été
écrit ; en juin 2026, ce noyau a été refactorisé, ses tests ont été réduits à un seul test factice et
quelques petites couches stub ont été ajoutées ; en octobre 2026, la bibliothèque a été reconstruite
de zéro autour de données validées, de modèles testés et de fichiers de modèle sûrs. Les API ne sont
pas compatibles ; [CHANGELOG.md](CHANGELOG.md) liste les changements.

## Utilisation

Les exemples ci-dessous sont copiés depuis
[`Examples/ModelLab/ModelLab/ReadmeSamples.swift`](Examples/ModelLab/ModelLab/ReadmeSamples.swift).
L’app d’exemple compile ce fichier, et la suite de tests le compile et exécute chaque exemple.

### Charger vos propres données

Un fichier CSV avec une ligne d’en-tête devient un jeu de données ; chaque colonne autre que la cible doit contenir des nombres.

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

### Normaliser les caractéristiques et entraîner un classifieur

Un `Pipeline` ajuste le scaler sur les données d’entraînement uniquement et normalise tous les échantillons suivants de la même façon.

```swift
let (training, test) = try Dataset.iris.stratifiedSplit(testFraction: 0.3, seed: 1)
let model = try Pipeline.fit(training, transformer: StandardScaler.fit) { scaled in
    try LogisticRegression.fit(scaled)
}
let report = try model.evaluate(on: test)
print(report)                       // precision, recall and F1 per class
print(report.confusionMatrix)
```

### Prédire un nombre

Écrivez `Dataset<Double>` pour des cibles de régression ; des littéraux entiers donneraient un `Dataset<Int>`.

```swift
// Size in square metres and number of rooms → price.
let houses = try Dataset<Double>(
    features: [[50, 1], [65, 2], [80, 2], [95, 3], [120, 3], [140, 4]],
    targets: [150_000, 190_000, 236_000, 280_000, 350_000, 405_000]
)
let model = try LinearRegression.fit(houses, regularization: 0.1)
let price = try model.predict([100, 3])
```

### Comparer des modèles par validation croisée

```swift
let data = Dataset.iris
let results = [
    "k-nearest neighbours": try data.crossValidate(folds: 5) { try KNearestNeighborsClassifier.fit($0, k: 7) },
    "naive Bayes": try data.crossValidate(folds: 5) { try GaussianNaiveBayes.fit($0) },
    "decision tree": try data.crossValidate(folds: 5) { try DecisionTreeClassifier.fit($0, maxDepth: 3) },
]
```

### Enregistrer un modèle et le charger dans l’app

```swift
let model = try RandomForestClassifier.fit(Dataset.iris, treeCount: 50, seed: 7)
let file = FileManager.default.temporaryDirectory.appendingPathComponent("iris-forest.json")

try JSONEncoder().encode(model).write(to: file)
let data = try Data(contentsOf: file)
let loaded = try JSONDecoder().decode(RandomForestClassifier<String>.self, from: data)
// `loaded` predicts exactly like `model`
```

### Trouver des groupes sans étiquettes

```swift
let features = Dataset.iris.features
let pca = try PrincipalComponentAnalysis.fit(features, componentCount: 2)
let points = try pca.transform(features)          // 150 × 2, for a scatter plot
let kMeans = try KMeans.fit(points, clusterCount: 3, seed: 1)
let clusters = try kMeans.predict(points)          // 0, 1 or 2 per flower
```

## Démo

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="docs/images/decision-boundaries-dark.png">
  <img src="docs/images/decision-boundaries-light.png" alt="Quatre classifieurs entraînés sur les mesures des pétales d’iris, avec l’espèce que chacun prédit sur le plan et leur précision en validation croisée (k plus proches voisins 96,0 %, régression logistique 95,3 %, arbre de décision 94,0 %, réseau de neurones 96,0 %)" width="780">
</picture>

Chaque cellule colorée est une prédiction du modèle entraîné sur les 150 fleurs d’iris ; les points
sont les fleurs. L’image est générée à partir de
[`Examples/ModelLab/ModelLab/DecisionBoundaries.swift`](Examples/ModelLab/ModelLab/DecisionBoundaries.swift)
par [`scripts/generate-images.sh`](scripts/generate-images.sh), qui exécute le test entraînant les
quatre modèles.

Pour essayer les modèles vous-même, ouvrez `ModelLab.xcodeproj` dans [`Examples/ModelLab`](Examples/ModelLab)
avec Xcode, choisissez un simulateur d’iPhone ou **My Mac**, puis appuyez sur **Run**. L’app comporte un
onglet de démarrage rapide, un écran avec des curseurs qui classe une fleur avec le modèle que vous
choisissez, et cette image ; [Examples/README.md](Examples/README.md) donne les détails.

## Documentation

Référence de l’API et articles :

- [Référence de l’API](https://muhittincamdali.github.io/SwiftAI/documentation/swiftai/)
  (DocC, publiée sur GitHub Pages depuis `master`)
- Générez-la en local dans Xcode avec **Product › Build Documentation**, ou en ligne de commande :

```sh
xcodebuild docbuild -scheme SwiftAI -destination 'generic/platform=macOS'
```

## Guides

- [Getting Started](https://muhittincamdali.github.io/SwiftAI/documentation/swiftai/gettingstarted)
  — ajouter le package, entraîner un classifieur, le mesurer et prédire
  ([source](Sources/SwiftAI/SwiftAI.docc/GettingStarted.md)).
- [Choosing a Model](https://muhittincamdali.github.io/SwiftAI/documentation/swiftai/choosingamodel)
  — les points forts de chaque modèle, s’il exige des caractéristiques normalisées, et les réglages qui comptent
  ([source](Sources/SwiftAI/SwiftAI.docc/ChoosingAModel.md)).
- [Preparing Data](https://muhittincamdali.github.io/SwiftAI/documentation/swiftai/preparingdata)
  — fichiers CSV, séparations, normalisation avec un pipeline et ACP
  ([source](Sources/SwiftAI/SwiftAI.docc/PreparingData.md)).
- [Saving and Loading Models](https://muhittincamdali.github.io/SwiftAI/documentation/swiftai/savingmodels)
  — livrer un modèle entraîné en JSON, et ce que vérifie le chargement
  ([source](Sources/SwiftAI/SwiftAI.docc/SavingModels.md)).

## Prérequis

| Plateforme | Version minimale |
| ------------------- | ------------------ |
| iOS | 15 |
| macOS | 12 |
| tvOS | 15 |
| watchOS | 8 |
| visionOS | 1 |
| Chaîne d’outils | Swift 6.2 · Xcode 26+ |

L’app d’exemple ModelLab requiert iOS 17 ou macOS 14.

## Architecture

- `Sources/SwiftAI/Core/` contient `Matrix` (une grille de `Double` rangée par lignes ; les produits
  utilisent Accelerate), les vérifications d’entrée, `SeededGenerator` (SplitMix64), le solveur des
  moindres carrés par QR de Householder et l’optimiseur L-BFGS.
- `Data/` contient `Dataset` (caractéristiques et cibles, validées une seule fois à la création), la
  séparation et les plis, `CSVTable` et les données iris. `Preprocessing/`, `Models/`, `Trees/`,
  `NeuralNetwork/`, `Clustering/` et `Evaluation/` contiennent le reste, avec une famille de modèles par fichier.
- Les modèles sont des types valeur immuables créés par une fonction statique `fit` ; une valeur de
  modèle est donc toujours entraînée. Les classifieurs se conforment à `Classifier` (et
  `ProbabilisticClassifier`), les régresseurs à `Regressor` ; les comportements partagés, comme
  `accuracy(on:)`, `evaluate(on:)` et la prédiction par lots, vivent dans des extensions de protocole.
- La validation a lieu à la frontière publique (création d’un jeu de données, ajustement, prédiction,
  décodage) ; le code interne s’appuie sur ces vérifications. Toute boucle sur des tailles contrôlées par l’utilisateur est bornée.
- Les arbres de décision sont stockés sous forme de tableaux où les enfants viennent toujours après leur
  parent ; le décodage l’impose, donc le parcours d’un arbre se termine toujours.

Lancez les tests en local :

```sh
swift test                                    # macOS
xcodebuild test -scheme SwiftAI -destination 'platform=iOS Simulator,name=iPhone 17'
```

## Feuille de route

- Machines à vecteurs de support linéaires, régression lasso et elastic-net, et un transformateur de
  caractéristiques polynomiales.
- Arbres à gradient boosting.
- Export des modèles linéaires et des arbres vers Core ML.
- Ajouter le package au Swift Package Index ; `.spi.yml` est déjà dans le dépôt.

## Contribuer

Les contributions sont les bienvenues. Lisez le [guide de contribution](https://github.com/muhittincamdali/SwiftAI/blob/master/CONTRIBUTING.md) et le [code de conduite](https://github.com/muhittincamdali/.github/blob/main/CODE_OF_CONDUCT.md) avant d’ouvrir une pull request. Signalez les problèmes de sécurité en privé, comme indiqué dans la [politique de sécurité](https://github.com/muhittincamdali/SwiftAI/blob/master/SECURITY.md).

## Licence

Publié sous licence MIT. Voir [LICENSE](LICENSE).
