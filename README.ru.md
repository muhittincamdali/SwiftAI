<!-- i18n-source: README.md@f259cb6cdf7b9b545881d4d6ec8eef1e0f111f95 status=reviewed -->
<!-- brand:start -->

<p align="center"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/banner-ru-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/banner-ru-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/banner-ru-light.svg" alt="SwiftAI: Машинное обучение на чистом Swift: обучайте, оценивайте и сохраняйте модели на устройстве."></picture></p>

<!-- lang-selector:start -->
<p align="center"><a href="README.md">English</a> · <a href="README.tr.md">Türkçe</a> · <a href="README.zh-CN.md">简体中文</a> · <a href="README.ja.md">日本語</a> · <a href="README.ko.md">한국어</a> · <a href="README.es.md">Español</a> · <a href="README.de.md">Deutsch</a> · <a href="README.fr.md">Français</a> · <a href="README.pt-BR.md">Português (Brasil)</a> · <a href="README.ru.md">Русский</a></p>
<!-- lang-selector:end -->

<p align="center">
<a href="https://github.com/muhittincamdali/SwiftAI/actions/workflows/ci.yml"><img src="https://github.com/muhittincamdali/SwiftAI/actions/workflows/ci.yml/badge.svg" alt="Статус CI"></a>
<a href="https://github.com/muhittincamdali/SwiftAI/releases"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/badge-version-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/badge-version-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/badge-version-light.svg" alt="Последняя версия: v2.0.0"></picture></a>
<a href="https://github.com/muhittincamdali/SwiftAI/blob/master/Package.swift"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/badge-platforms-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/badge-platforms-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/badge-platforms-light.svg" alt="Поддерживаемые платформы: iOS 15+ · macOS 12+ · tvOS 15+ · watchOS 8+ · visionOS 1+"></picture></a>
<a href="https://github.com/muhittincamdali/SwiftAI/blob/master/Package.swift"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/badge-language-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/badge-language-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/badge-language-light.svg" alt="Версия языка: Swift 6.2+"></picture></a>
<a href="https://github.com/muhittincamdali/SwiftAI/blob/master/LICENSE"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/badge-license-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/badge-license-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/badge-license-light.svg" alt="Лицензия: MIT"></picture></a>
</p>

<p align="center">
<a href="#быстрый-старт"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/button-start-ru-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/button-start-ru-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/button-start-ru-light.svg" alt="Начать"></picture></a>
<a href="https://muhittincamdali.github.io/SwiftAI/documentation/swiftai/"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/button-docs-ru-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/button-docs-ru-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/button-docs-ru-light.svg" alt="Документация"></picture></a>
<a href="https://github.com/muhittincamdali/SwiftAI/tree/master/Examples"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/button-examples-ru-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/button-examples-ru-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/button-examples-ru-light.svg" alt="Примеры"></picture></a>
</p>

> Это перевод README на английском языке. Если они расходятся, актуальна английская версия.

<!-- brand:end -->

SwiftAI — это Swift-пакет для классического машинного обучения на платформах Apple: классификация,
регрессия, кластеризация и снижение размерности на таблицах чисел. Он предназначен для разработчиков
приложений, которые хотят обучать или запускать модель на устройстве, на Swift, без инструментов
Python и без сервера. Вы загружаете данные из CSV или массивов, делите их, обучаете модель одним
вызовом функции, оцениваете её и сохраняете в JSON, чтобы загрузить в приложении. У пакета нет зависимостей.

## Основные возможности

- **Одиннадцать моделей с учителем** — линейная и ридж-регрессия, логистическая регрессия, k ближайших
  соседей, гауссовский наивный байесовский классификатор, деревья решений, случайные леса и нейронные
  сети (классификатор и регрессор там, где это применимо), а также кластеризация k-means и метод главных компонент.
- **Сверено со scikit-learn** — если в scikit-learn есть такая же модель, SwiftAI использует ту же
  целевую функцию и те же значения по умолчанию, а тесты сравнивают коэффициенты, вероятности и кластеры
  со scikit-learn 1.9.1 (например, вероятности логистической регрессии до 1e-5, PCA до 1e-10).
- **Ошибки вместо сбоев** — каждая функция, принимающая данные или настройки, проверяет их и выбрасывает
  `SwiftAIError` с подсказкой, что изменить: значения NaN, неверное число признаков, переполняющиеся
  суммы, настройки вне допустимого диапазона, строки CSV, которые не являются числами.
- **Безопасная загрузка** — модели, скейлеры и конвейеры реализуют `Codable`; при декодировании
  проверяются формы, значения, списки классов и структура деревьев, поэтому повреждённый или
  специально подготовленный файл не может привести к сбою предсказания.
- **Воспроизводимость** — каждый случайный шаг (разбиения, леса, k-means++, веса сети) принимает
  `seed`; один и тот же seed даёт одну и ту же модель на любой платформе, в том числе для лесов,
  обучаемых параллельно.
- **Swift 6, протестировано** — собирается в языковом режиме Swift 6 со строгой проверкой
  конкурентности и без предупреждений; 133 теста Swift Testing запускаются на macOS и в симуляторе iPhone.

## Быстрый старт

**1. Добавьте пакет**

В Xcode выберите **File › Add Package Dependencies…** и введите адрес репозитория:

```text
https://github.com/muhittincamdali/SwiftAI.git
```

**2. Импортируйте модуль**

```swift
import SwiftAI
```

**3. Используйте**

В новом приложении Xcode (**File › New › Project… › App**) замените всё содержимое
`ContentView.swift` на:

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

Нажмите **Run** (⌘R). Приложение обучает случайный лес на 150 ирисах, которые входят в пакет, и
показывает долю тестовых цветков, классифицированных верно, а также вид нового цветка: `virginica`.

## Установка

### Swift Package Manager

В Xcode выберите **File › Add Package Dependencies…** и введите адрес репозитория:

```text
https://github.com/muhittincamdali/SwiftAI.git
```

Или добавьте его в `dependencies` вашего `Package.swift`:

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

Версия 2.0.0 (октябрь 2026) — первый релиз нынешней библиотеки. Предыдущий релиз, 1.0.0
(февраль 2026), был до неё: в июне 2026 его исходный код заменили кодом-заглушкой, а в октябре 2026
библиотеку заново создали с нуля на основе проверенных данных, протестированных моделей и безопасных
файлов моделей. API несовместимы; изменения перечислены в [CHANGELOG.md](CHANGELOG.md).

## Использование

Примеры ниже скопированы из
[`Examples/ModelLab/ModelLab/ReadmeSamples.swift`](Examples/ModelLab/ModelLab/ReadmeSamples.swift).
Приложение-пример компилирует этот файл, а набор тестов компилирует его и выполняет каждый пример.

### Загрузите свои данные

CSV-файл со строкой заголовка становится набором данных; все столбцы, кроме целевого, должны содержать числа.

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

### Масштабируйте признаки и обучите классификатор

`Pipeline` подгоняет скейлер только по обучающим данным и масштабирует все последующие образцы так же.

```swift
let (training, test) = try Dataset.iris.stratifiedSplit(testFraction: 0.3, seed: 1)
let model = try Pipeline.fit(training, transformer: StandardScaler.fit) { scaled in
    try LogisticRegression.fit(scaled)
}
let report = try model.evaluate(on: test)
print(report)                       // precision, recall and F1 per class
print(report.confusionMatrix)
```

### Предскажите число

Для целевых значений регрессии пишите `Dataset<Double>`; целочисленные литералы дали бы `Dataset<Int>`.

```swift
// Size in square metres and number of rooms → price.
let houses = try Dataset<Double>(
    features: [[50, 1], [65, 2], [80, 2], [95, 3], [120, 3], [140, 4]],
    targets: [150_000, 190_000, 236_000, 280_000, 350_000, 405_000]
)
let model = try LinearRegression.fit(houses, regularization: 0.1)
let price = try model.predict([100, 3])
```

### Сравните модели с помощью кросс-валидации

```swift
let data = Dataset.iris
let results = [
    "k-nearest neighbours": try data.crossValidate(folds: 5) { try KNearestNeighborsClassifier.fit($0, k: 7) },
    "naive Bayes": try data.crossValidate(folds: 5) { try GaussianNaiveBayes.fit($0) },
    "decision tree": try data.crossValidate(folds: 5) { try DecisionTreeClassifier.fit($0, maxDepth: 3) },
]
```

### Сохраните модель и загрузите её в приложении

```swift
let model = try RandomForestClassifier.fit(Dataset.iris, treeCount: 50, seed: 7)
let file = FileManager.default.temporaryDirectory.appendingPathComponent("iris-forest.json")

try JSONEncoder().encode(model).write(to: file)
let data = try Data(contentsOf: file)
let loaded = try JSONDecoder().decode(RandomForestClassifier<String>.self, from: data)
// `loaded` predicts exactly like `model`
```

### Найдите группы без меток

```swift
let features = Dataset.iris.features
let pca = try PrincipalComponentAnalysis.fit(features, componentCount: 2)
let points = try pca.transform(features)          // 150 × 2, for a scatter plot
let kMeans = try KMeans.fit(points, clusterCount: 3, seed: 1)
let clusters = try kMeans.predict(points)          // 0, 1 or 2 per flower
```

## Демо

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="docs/images/decision-boundaries-dark.png">
  <img src="docs/images/decision-boundaries-light.png" alt="Четыре классификатора, обученные на измерениях лепестков ириса, с видом, который каждый из них предсказывает на плоскости, и их точностью по кросс-валидации (k ближайших соседей 96,0 %, логистическая регрессия 95,3 %, дерево решений 94,0 %, нейронная сеть 96,0 %)" width="780">
</picture>

Каждая цветная ячейка — это предсказание модели, обученной на 150 ирисах; точки — сами цветки.
Изображение создаётся на основе
[`Examples/ModelLab/ModelLab/DecisionBoundaries.swift`](Examples/ModelLab/ModelLab/DecisionBoundaries.swift)
скриптом [`scripts/generate-images.sh`](scripts/generate-images.sh), который запускает тест,
обучающий четыре модели.

Чтобы попробовать модели самостоятельно, откройте `ModelLab.xcodeproj` из [`Examples/ModelLab`](Examples/ModelLab)
в Xcode, выберите симулятор iPhone или **My Mac** и нажмите **Run**. В приложении есть вкладка быстрого
старта, экран с ползунками, который классифицирует цветок выбранной вами моделью, и это изображение;
подробности — в [Examples/README.md](Examples/README.md).

## Документация

Справочник API и статьи:

- [Справочник по API](https://muhittincamdali.github.io/SwiftAI/documentation/swiftai/)
  (DocC, публикуется в GitHub Pages из `master`)
- Соберите её локально в Xcode через **Product › Build Documentation** или из командной строки:

```sh
xcodebuild docbuild -scheme SwiftAI -destination 'generic/platform=macOS'
```

## Руководства

- [Getting Started](https://muhittincamdali.github.io/SwiftAI/documentation/swiftai/gettingstarted)
  — добавьте пакет, обучите классификатор, оцените его и сделайте предсказание
  ([исходник](Sources/SwiftAI/SwiftAI.docc/GettingStarted.md)).
- [Choosing a Model](https://muhittincamdali.github.io/SwiftAI/documentation/swiftai/choosingamodel)
  — в чём сильна каждая модель, нужны ли ей масштабированные признаки и какие настройки важны
  ([исходник](Sources/SwiftAI/SwiftAI.docc/ChoosingAModel.md)).
- [Preparing Data](https://muhittincamdali.github.io/SwiftAI/documentation/swiftai/preparingdata)
  — CSV-файлы, разбиения, масштабирование с помощью конвейера и PCA
  ([исходник](Sources/SwiftAI/SwiftAI.docc/PreparingData.md)).
- [Saving and Loading Models](https://muhittincamdali.github.io/SwiftAI/documentation/swiftai/savingmodels)
  — как поставлять обученную модель в виде JSON и что проверяется при загрузке
  ([исходник](Sources/SwiftAI/SwiftAI.docc/SavingModels.md)).

## Требования

| Платформа | Минимальная версия |
| ------------------- | ------------------ |
| iOS | 15 |
| macOS | 12 |
| tvOS | 15 |
| watchOS | 8 |
| visionOS | 1 |
| Инструменты | Swift 6.2 · Xcode 26+ |

Приложению-примеру ModelLab нужен iOS 17 или macOS 14.

## Архитектура

- В `Sources/SwiftAI/Core/` находятся `Matrix` (построчная сетка `Double`; произведения используют
  Accelerate), проверки входных данных, `SeededGenerator` (SplitMix64), решатель задачи наименьших
  квадратов на основе QR-разложения Хаусхолдера и оптимизатор L-BFGS.
- В `Data/` лежат `Dataset` (признаки и целевые значения, проверяются один раз при создании),
  разбиения и фолды, `CSVTable` и данные ирисов. Остальное находится в `Preprocessing/`, `Models/`,
  `Trees/`, `NeuralNetwork/`, `Clustering/` и `Evaluation/`: одно семейство моделей — один файл.
- Модели — неизменяемые типы-значения, создаваемые статической функцией `fit`, поэтому значение модели
  всегда обучено. Классификаторы соответствуют `Classifier` (и `ProbabilisticClassifier`), регрессоры —
  `Regressor`; общее поведение, например `accuracy(on:)`, `evaluate(on:)` и пакетное предсказание,
  находится в расширениях протоколов.
- Проверка выполняется на публичной границе (создание набора данных, обучение, предсказание,
  декодирование); внутренний код полагается на эти проверки. Каждый цикл по размерам, которые задаёт пользователь, ограничен.
- Деревья решений хранятся в виде массивов, где потомки всегда идут после родителя; декодирование
  это гарантирует, поэтому обход дерева всегда завершается.

Запустите тесты локально:

```sh
swift test                                    # macOS
xcodebuild test -scheme SwiftAI -destination 'platform=iOS Simulator,name=iPhone 17'
```

## План развития

- Линейные машины опорных векторов, регрессия lasso и elastic-net, а также преобразователь
  полиномиальных признаков.
- Деревья с градиентным бустингом.
- Экспорт линейных моделей и деревьев в Core ML.
- Добавить пакет в Swift Package Index; `.spi.yml` уже есть в репозитории.

## Участие в разработке

Мы рады вашему участию. Перед открытием pull request прочитайте [руководство для участников](https://github.com/muhittincamdali/SwiftAI/blob/master/CONTRIBUTING.md) и [кодекс поведения](https://github.com/muhittincamdali/.github/blob/main/CODE_OF_CONDUCT.md). О проблемах безопасности сообщайте конфиденциально, как описано в [политике безопасности](https://github.com/muhittincamdali/SwiftAI/blob/master/SECURITY.md).

## Лицензия

Распространяется по лицензии MIT. Подробнее — в файле [LICENSE](LICENSE).
