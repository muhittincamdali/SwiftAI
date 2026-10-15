<!-- i18n-source: README.md@e0c55bc21df63f9a2618b00bda59aa525f4235d2 status=reviewed -->
<!-- brand:start -->

<p align="center"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/banner-es-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/banner-es-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/banner-es-light.svg" alt="SwiftAI: Aprendizaje automático en Swift puro: entrena, evalúa y guarda modelos en el dispositivo."></picture></p>

<!-- lang-selector:start -->
<p align="center"><a href="README.md">English</a> · <a href="README.tr.md">Türkçe</a> · <a href="README.zh-CN.md">简体中文</a> · <a href="README.ja.md">日本語</a> · <a href="README.ko.md">한국어</a> · <a href="README.es.md">Español</a> · <a href="README.de.md">Deutsch</a> · <a href="README.fr.md">Français</a> · <a href="README.pt-BR.md">Português (Brasil)</a> · <a href="README.ru.md">Русский</a></p>
<!-- lang-selector:end -->

<p align="center">
<a href="https://github.com/muhittincamdali/SwiftAI/actions/workflows/ci.yml"><img src="https://github.com/muhittincamdali/SwiftAI/actions/workflows/ci.yml/badge.svg" alt="Estado de CI"></a>
<a href="https://github.com/muhittincamdali/SwiftAI/releases"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/badge-version-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/badge-version-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/badge-version-light.svg" alt="Última versión: v2.0.0"></picture></a>
<a href="https://github.com/muhittincamdali/SwiftAI/blob/master/Package.swift"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/badge-platforms-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/badge-platforms-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/badge-platforms-light.svg" alt="Plataformas compatibles: iOS 15+ · macOS 12+ · tvOS 15+ · watchOS 8+ · visionOS 1+"></picture></a>
<a href="https://github.com/muhittincamdali/SwiftAI/blob/master/Package.swift"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/badge-language-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/badge-language-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/badge-language-light.svg" alt="Versión del lenguaje: Swift 6.2+"></picture></a>
<a href="https://github.com/muhittincamdali/SwiftAI/blob/master/LICENSE"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/badge-license-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/badge-license-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/badge-license-light.svg" alt="Licencia: MIT"></picture></a>
</p>

<p align="center">
<a href="#inicio-rápido"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/button-start-es-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/button-start-es-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/button-start-es-light.svg" alt="Empezar"></picture></a>
<a href="https://muhittincamdali.github.io/SwiftAI/documentation/swiftai/"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/button-docs-es-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/button-docs-es-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/button-docs-es-light.svg" alt="Documentación"></picture></a>
<a href="https://github.com/muhittincamdali/SwiftAI/tree/master/Examples"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/button-examples-es-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/button-examples-es-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/button-examples-es-light.svg" alt="Ejemplos"></picture></a>
</p>

> Esta es una traducción del README en inglés. Si hay diferencias, la versión en inglés es la vigente.

<!-- brand:end -->

SwiftAI es un paquete de Swift para aprendizaje automático clásico en las plataformas de Apple:
clasificación, regresión, clustering y reducción de dimensionalidad sobre tablas de números. Está
pensado para desarrolladores de apps que quieren entrenar o ejecutar un modelo en el dispositivo,
con Swift, sin una cadena de herramientas de Python ni un servidor. Cargas los datos desde CSV o
desde arrays, los divides, entrenas un modelo con una sola llamada a una función, lo evalúas y lo
guardas como JSON para cargarlo en tu app. El paquete no tiene dependencias.

## Lo más destacado

- **Once modelos supervisados** — regresión lineal y ridge, regresión logística, k vecinos más cercanos,
  Naive Bayes gaussiano, árboles de decisión, bosques aleatorios y redes neuronales (clasificador y
  regresor cuando corresponde), además de clustering k-means y análisis de componentes principales.
- **Contrastado con scikit-learn** — cuando scikit-learn tiene el mismo modelo, SwiftAI usa el mismo
  objetivo y los mismos valores por defecto, y las pruebas comparan coeficientes, probabilidades y
  clústeres con scikit-learn 1.9.1 (por ejemplo, probabilidades de regresión logística hasta 1e-5 y PCA hasta 1e-10).
- **Errores en lugar de fallos** — toda función que recibe datos o ajustes los valida y lanza un
  `SwiftAIError` que indica qué cambiar: valores NaN, número de características incorrecto, sumas que
  se desbordan, ajustes fuera de rango, líneas de CSV que no son números.
- **Carga segura** — los modelos, los escaladores y los pipelines son `Codable`; la decodificación
  comprueba formas, valores, listas de clases y estructura de los árboles, de modo que un archivo
  dañado o manipulado no puede hacer fallar una predicción.
- **Reproducible** — cada paso aleatorio (divisiones, bosques, k-means++, pesos de la red) recibe un
  `seed`; el mismo seed da el mismo modelo en todas las plataformas, también en bosques entrenados en paralelo.
- **Swift 6, probado** — compila en el modo de lenguaje Swift 6 con comprobación estricta de
  concurrencia y sin advertencias; 133 pruebas de Swift Testing se ejecutan en macOS y en un simulador de iPhone.

## Inicio rápido

**1. Añade el paquete**

En Xcode, elige **File › Add Package Dependencies…** e introduce la URL del repositorio:

```text
https://github.com/muhittincamdali/SwiftAI.git
```

**2. Importa el módulo**

```swift
import SwiftAI
```

**3. Úsalo**

En una app nueva de Xcode (**File › New › Project… › App**), sustituye todo el contenido de
`ContentView.swift` por:

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

Pulsa **Run** (⌘R). La app entrena un bosque aleatorio con las 150 flores iris incluidas en el
paquete y muestra el porcentaje de flores de prueba que clasificó correctamente y la especie de una
flor nueva: `virginica`.

## Instalación

### Swift Package Manager

En Xcode, elige **File › Add Package Dependencies…** e introduce la URL del repositorio:

```text
https://github.com/muhittincamdali/SwiftAI.git
```

O añádelo a las `dependencies` de tu `Package.swift`:

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

La versión 2.0.0 (octubre de 2026) es la primera versión de la biblioteca actual. La versión anterior,
1.0.0 (febrero de 2026), es previa: tres días después de su publicación se eliminaron los módulos de
arquitectura de aplicación y se escribió un núcleo de aprendizaje automático más pequeño; en junio de
2026 ese núcleo se refactorizó, sus pruebas se redujeron a una única prueba de relleno y se añadieron
algunas capas stub pequeñas; en octubre de 2026 la biblioteca se reconstruyó desde cero en torno a
datos validados, modelos probados y archivos de modelo seguros. Las API no son compatibles;
[CHANGELOG.md](CHANGELOG.md) enumera los cambios.

## Uso

Los ejemplos de abajo están copiados de
[`Examples/ModelLab/ModelLab/ReadmeSamples.swift`](Examples/ModelLab/ModelLab/ReadmeSamples.swift).
La app de ejemplo compila ese archivo, y el conjunto de pruebas lo compila y ejecuta cada ejemplo.

### Carga tus propios datos

Un archivo CSV con fila de encabezado se convierte en un conjunto de datos; todas las columnas excepto el objetivo deben contener números.

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

### Escala las características y entrena un clasificador

Un `Pipeline` ajusta el escalador solo con los datos de entrenamiento y escala todas las muestras posteriores del mismo modo.

```swift
let (training, test) = try Dataset.iris.stratifiedSplit(testFraction: 0.3, seed: 1)
let model = try Pipeline.fit(training, transformer: StandardScaler.fit) { scaled in
    try LogisticRegression.fit(scaled)
}
let report = try model.evaluate(on: test)
print(report)                       // precision, recall and F1 per class
print(report.confusionMatrix)
```

### Predice un número

Escribe `Dataset<Double>` para objetivos de regresión; los literales enteros darían un `Dataset<Int>`.

```swift
// Size in square metres and number of rooms → price.
let houses = try Dataset<Double>(
    features: [[50, 1], [65, 2], [80, 2], [95, 3], [120, 3], [140, 4]],
    targets: [150_000, 190_000, 236_000, 280_000, 350_000, 405_000]
)
let model = try LinearRegression.fit(houses, regularization: 0.1)
let price = try model.predict([100, 3])
```

### Compara modelos con validación cruzada

```swift
let data = Dataset.iris
let results = [
    "k-nearest neighbours": try data.crossValidate(folds: 5) { try KNearestNeighborsClassifier.fit($0, k: 7) },
    "naive Bayes": try data.crossValidate(folds: 5) { try GaussianNaiveBayes.fit($0) },
    "decision tree": try data.crossValidate(folds: 5) { try DecisionTreeClassifier.fit($0, maxDepth: 3) },
]
```

### Guarda un modelo y cárgalo en la app

```swift
let model = try RandomForestClassifier.fit(Dataset.iris, treeCount: 50, seed: 7)
let file = FileManager.default.temporaryDirectory.appendingPathComponent("iris-forest.json")

try JSONEncoder().encode(model).write(to: file)
let data = try Data(contentsOf: file)
let loaded = try JSONDecoder().decode(RandomForestClassifier<String>.self, from: data)
// `loaded` predicts exactly like `model`
```

### Encuentra grupos sin etiquetas

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
  <img src="docs/images/decision-boundaries-light.png" alt="Cuatro clasificadores entrenados con las medidas de los pétalos del iris, con la especie que cada uno predice en el plano y su precisión con validación cruzada (k vecinos más cercanos 96,0 %, regresión logística 95,3 %, árbol de decisión 94,0 %, red neuronal 96,0 %)" width="780">
</picture>

Cada celda de color es una predicción del modelo entrenado con las 150 flores iris; los puntos son
las flores. La imagen se genera a partir de
[`Examples/ModelLab/ModelLab/DecisionBoundaries.swift`](Examples/ModelLab/ModelLab/DecisionBoundaries.swift)
con [`scripts/generate-images.sh`](scripts/generate-images.sh), que ejecuta la prueba que entrena
los cuatro modelos.

Para probar los modelos tú mismo, abre `ModelLab.xcodeproj` en [`Examples/ModelLab`](Examples/ModelLab)
con Xcode, elige un simulador de iPhone o **My Mac** y pulsa **Run**. La app tiene una pestaña de
inicio rápido, una pantalla con controles deslizantes que clasifica una flor con el modelo que elijas
y esta imagen; [Examples/README.md](Examples/README.md) tiene los detalles.

## Documentación

Referencia de la API y artículos:

- [Referencia de la API](https://muhittincamdali.github.io/SwiftAI/documentation/swiftai/)
  (DocC, publicada en GitHub Pages desde `master`)
- Compílala en local desde Xcode con **Product › Build Documentation**, o desde la línea de comandos:

```sh
xcodebuild docbuild -scheme SwiftAI -destination 'generic/platform=macOS'
```

## Guías

- [Getting Started](https://muhittincamdali.github.io/SwiftAI/documentation/swiftai/gettingstarted)
  — añade el paquete, entrena un clasificador, evalúalo y predice
  ([código fuente](Sources/SwiftAI/SwiftAI.docc/GettingStarted.md)).
- [Choosing a Model](https://muhittincamdali.github.io/SwiftAI/documentation/swiftai/choosingamodel)
  — en qué es bueno cada modelo, si necesita características escaladas y los ajustes que importan
  ([código fuente](Sources/SwiftAI/SwiftAI.docc/ChoosingAModel.md)).
- [Preparing Data](https://muhittincamdali.github.io/SwiftAI/documentation/swiftai/preparingdata)
  — archivos CSV, divisiones, escalado con un pipeline y PCA
  ([código fuente](Sources/SwiftAI/SwiftAI.docc/PreparingData.md)).
- [Saving and Loading Models](https://muhittincamdali.github.io/SwiftAI/documentation/swiftai/savingmodels)
  — distribuye un modelo entrenado como JSON y qué se comprueba al cargarlo
  ([código fuente](Sources/SwiftAI/SwiftAI.docc/SavingModels.md)).

## Requisitos

| Plataforma | Versión mínima |
| ------------------- | ------------------ |
| iOS | 15 |
| macOS | 12 |
| tvOS | 15 |
| watchOS | 8 |
| visionOS | 1 |
| Herramientas | Swift 6.2 · Xcode 26+ |

La app de ejemplo ModelLab requiere iOS 17 o macOS 14.

## Arquitectura

- `Sources/SwiftAI/Core/` contiene `Matrix` (una cuadrícula de `Double` por filas; los productos usan
  Accelerate), las comprobaciones de entrada, `SeededGenerator` (SplitMix64), el solucionador de
  mínimos cuadrados con QR de Householder y el optimizador L-BFGS.
- `Data/` tiene `Dataset` (características y objetivos, validados una sola vez al crearlo), la división
  y los pliegues, `CSVTable` y los datos del iris. `Preprocessing/`, `Models/`, `Trees/`,
  `NeuralNetwork/`, `Clustering/` y `Evaluation/` contienen el resto, con una familia de modelos por archivo.
- Los modelos son tipos de valor inmutables creados por una función estática `fit`, así que un valor de
  modelo siempre está entrenado. Los clasificadores cumplen `Classifier` (y `ProbabilisticClassifier`)
  y los regresores `Regressor`; el comportamiento compartido, como `accuracy(on:)`, `evaluate(on:)` y
  la predicción por lotes, vive en extensiones de protocolo.
- La validación ocurre en el límite público (crear un conjunto de datos, ajustar, predecir, decodificar);
  el código interno confía en esas comprobaciones. Todo bucle sobre tamaños controlados por el usuario está acotado.
- Los árboles de decisión se guardan como arrays en los que los hijos siempre van después de su padre;
  la decodificación lo exige, por lo que recorrer un árbol siempre termina.

Ejecuta las pruebas en local:

```sh
swift test                                    # macOS
xcodebuild test -scheme SwiftAI -destination 'platform=iOS Simulator,name=iPhone 17'
```

## Hoja de ruta

- Máquinas de vectores de soporte lineales, regresión lasso y elastic-net, y un transformador de
  características polinómicas.
- Árboles con gradient boosting.
- Exportación de modelos lineales y árboles a Core ML.
- Añadir el paquete al Swift Package Index; `.spi.yml` ya está en el repositorio.

## Contribuir

Las contribuciones son bienvenidas. Lee la [guía de contribución](https://github.com/muhittincamdali/SwiftAI/blob/master/CONTRIBUTING.md) y el [código de conducta](https://github.com/muhittincamdali/.github/blob/main/CODE_OF_CONDUCT.md) antes de abrir una pull request. Informa de los problemas de seguridad de forma privada, como se describe en la [política de seguridad](https://github.com/muhittincamdali/SwiftAI/blob/master/SECURITY.md).

## Licencia

Publicado bajo la licencia MIT. Consulta [LICENSE](LICENSE).
