<!-- i18n-source: README.md@e0c55bc21df63f9a2618b00bda59aa525f4235d2 status=reviewed -->
<!-- brand:start -->

<p align="center"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/banner-zh-CN-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/banner-zh-CN-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/banner-zh-CN-light.svg" alt="SwiftAI: 纯 Swift 机器学习：在设备上训练、评估和保存模型。"></picture></p>

<!-- lang-selector:start -->
<p align="center"><a href="README.md">English</a> · <a href="README.tr.md">Türkçe</a> · <a href="README.zh-CN.md">简体中文</a> · <a href="README.ja.md">日本語</a> · <a href="README.ko.md">한국어</a> · <a href="README.es.md">Español</a> · <a href="README.de.md">Deutsch</a> · <a href="README.fr.md">Français</a> · <a href="README.pt-BR.md">Português (Brasil)</a> · <a href="README.ru.md">Русский</a></p>
<!-- lang-selector:end -->

<p align="center">
<a href="https://github.com/muhittincamdali/SwiftAI/actions/workflows/ci.yml"><img src="https://github.com/muhittincamdali/SwiftAI/actions/workflows/ci.yml/badge.svg" alt="CI 状态"></a>
<a href="https://github.com/muhittincamdali/SwiftAI/releases"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/badge-version-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/badge-version-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/badge-version-light.svg" alt="最新版本: v2.0.0"></picture></a>
<a href="https://github.com/muhittincamdali/SwiftAI/blob/master/Package.swift"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/badge-platforms-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/badge-platforms-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/badge-platforms-light.svg" alt="支持的平台: iOS 15+ · macOS 12+ · tvOS 15+ · watchOS 8+ · visionOS 1+"></picture></a>
<a href="https://github.com/muhittincamdali/SwiftAI/blob/master/Package.swift"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/badge-language-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/badge-language-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/badge-language-light.svg" alt="语言版本: Swift 6.2+"></picture></a>
<a href="https://github.com/muhittincamdali/SwiftAI/blob/master/LICENSE"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/badge-license-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/badge-license-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/badge-license-light.svg" alt="许可证: MIT"></picture></a>
</p>

<p align="center">
<a href="#快速开始"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/button-start-zh-CN-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/button-start-zh-CN-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/button-start-zh-CN-light.svg" alt="开始使用"></picture></a>
<a href="https://muhittincamdali.github.io/SwiftAI/documentation/swiftai/"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/button-docs-zh-CN-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/button-docs-zh-CN-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/button-docs-zh-CN-light.svg" alt="文档"></picture></a>
<a href="https://github.com/muhittincamdali/SwiftAI/tree/master/Examples"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/button-examples-zh-CN-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/button-examples-zh-CN-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/button-examples-zh-CN-light.svg" alt="示例"></picture></a>
</p>

> 本文是英文 README 的译文。如两者内容不一致，以英文版为准。

<!-- brand:end -->

SwiftAI 是一个面向 Apple 平台的 Swift 包，用于经典机器学习：对数值表格进行分类、回归、聚类和降维。它适合希望在设备上用 Swift 训练或运行模型的 App 开发者，无需 Python 工具链，也无需服务器。你可以从 CSV 或数组加载数据并划分，用一次函数调用训练模型、评估模型，再把它保存为 JSON，在 App 中加载。该包没有任何依赖。

## 亮点

- **十一种监督学习模型** — 线性回归与岭回归、逻辑回归、k 近邻、高斯朴素贝叶斯、决策树、随机森林和神经网络（在适用的情况下分别提供分类器和回归器），另有 k-means 聚类和主成分分析。
- **与 scikit-learn 对照验证** — 凡 scikit-learn 中有相同模型的，SwiftAI 采用相同的目标函数和默认值，测试会将系数、概率和聚类结果与 scikit-learn 1.9.1 比对（例如逻辑回归的概率精确到 1e-5，PCA 精确到 1e-10）。
- **报错而不是崩溃** — 每个接收数据或设置的函数都会先校验，并抛出说明应如何修改的 `SwiftAIError`：NaN 值、特征数量错误、溢出的求和、超出范围的设置、不是数字的 CSV 行。
- **加载安全** — 模型、缩放器和流水线都遵循 `Codable`；解码时会检查形状、数值、类别列表和树结构，因此损坏或恶意构造的文件不会导致预测崩溃。
- **可复现** — 每个随机步骤（划分、森林、k-means++、网络权重）都接受 `seed`；相同的 seed 在所有平台上得到相同的模型，并行训练的森林也是如此。
- **Swift 6，经过测试** — 以 Swift 6 语言模式构建，启用严格并发检查，没有警告；133 个 Swift Testing 测试在 macOS 和 iPhone 模拟器上运行。

## 快速开始

**1. 添加软件包**

在 Xcode 中选择 **File › Add Package Dependencies…**，然后输入仓库地址：

```text
https://github.com/muhittincamdali/SwiftAI.git
```

**2. 导入模块**

```swift
import SwiftAI
```

**3. 开始使用**

在新建的 Xcode App 中（**File › New › Project… › App**），将 `ContentView.swift` 的全部内容替换为：

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

点击 **Run**（⌘R）。App 会在包内自带的 150 朵鸢尾花数据上训练一个随机森林，并显示测试样本中分类正确的比例，以及一朵新花的品种：`virginica`。

## 安装

### Swift Package Manager

在 Xcode 中选择 **File › Add Package Dependencies…**，然后输入仓库地址：

```text
https://github.com/muhittincamdali/SwiftAI.git
```

或者将其添加到 `Package.swift` 的 `dependencies` 中：

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

2.0.0 版（2026 年 10 月）是当前这套库的首个发布版本。更早的 1.0.0 版（2026 年 2 月）早于它：1.0.0 发布三天后，其应用架构模块被移除，并编写了一个更小的机器学习核心；2026 年 6 月，该核心经过重构，测试缩减为单个占位测试，并加入了几个小型桩（stub）层；2026 年 10 月，库围绕经过校验的数据、经过测试的模型和安全的模型文件从头重建。两者的 API 不兼容；变更列表见 [CHANGELOG.md](CHANGELOG.md)。

## 使用方法

以下示例复制自 [`Examples/ModelLab/ModelLab/ReadmeSamples.swift`](Examples/ModelLab/ModelLab/ReadmeSamples.swift)。示例 App 会编译该文件，测试套件也会编译它并运行每一个示例。

### 加载你自己的数据

带表头行的 CSV 文件会变成数据集；除目标列外，每一列都必须是数字。

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

### 缩放特征并训练分类器

`Pipeline` 只用训练数据拟合缩放器，并以同样的方式缩放之后的每个样本。

```swift
let (training, test) = try Dataset.iris.stratifiedSplit(testFraction: 0.3, seed: 1)
let model = try Pipeline.fit(training, transformer: StandardScaler.fit) { scaled in
    try LogisticRegression.fit(scaled)
}
let report = try model.evaluate(on: test)
print(report)                       // precision, recall and F1 per class
print(report.confusionMatrix)
```

### 预测一个数值

回归目标请写 `Dataset<Double>`；整数字面量会得到 `Dataset<Int>`。

```swift
// Size in square metres and number of rooms → price.
let houses = try Dataset<Double>(
    features: [[50, 1], [65, 2], [80, 2], [95, 3], [120, 3], [140, 4]],
    targets: [150_000, 190_000, 236_000, 280_000, 350_000, 405_000]
)
let model = try LinearRegression.fit(houses, regularization: 0.1)
let price = try model.predict([100, 3])
```

### 用交叉验证比较模型

```swift
let data = Dataset.iris
let results = [
    "k-nearest neighbours": try data.crossValidate(folds: 5) { try KNearestNeighborsClassifier.fit($0, k: 7) },
    "naive Bayes": try data.crossValidate(folds: 5) { try GaussianNaiveBayes.fit($0) },
    "decision tree": try data.crossValidate(folds: 5) { try DecisionTreeClassifier.fit($0, maxDepth: 3) },
]
```

### 保存模型并在 App 中加载

```swift
let model = try RandomForestClassifier.fit(Dataset.iris, treeCount: 50, seed: 7)
let file = FileManager.default.temporaryDirectory.appendingPathComponent("iris-forest.json")

try JSONEncoder().encode(model).write(to: file)
let data = try Data(contentsOf: file)
let loaded = try JSONDecoder().decode(RandomForestClassifier<String>.self, from: data)
// `loaded` predicts exactly like `model`
```

### 在没有标签的情况下发现分组

```swift
let features = Dataset.iris.features
let pca = try PrincipalComponentAnalysis.fit(features, componentCount: 2)
let points = try pca.transform(features)          // 150 × 2, for a scatter plot
let kMeans = try KMeans.fit(points, clusterCount: 3, seed: 1)
let clusters = try kMeans.predict(points)          // 0, 1 or 2 per flower
```

## 演示

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="docs/images/decision-boundaries-dark.png">
  <img src="docs/images/decision-boundaries-light.png" alt="基于鸢尾花花瓣测量值训练的四个分类器，图中显示各自在平面上预测的品种及交叉验证准确率（k 近邻 96.0%，逻辑回归 95.3%，决策树 94.0%，神经网络 96.0%）" width="780">
</picture>

每个彩色格子是在 150 朵鸢尾花上训练的模型所做的预测；圆点是这些花。图像由
[`Examples/ModelLab/ModelLab/DecisionBoundaries.swift`](Examples/ModelLab/ModelLab/DecisionBoundaries.swift)
渲染而成，生成脚本为 [`scripts/generate-images.sh`](scripts/generate-images.sh)，它会运行训练这四个模型的测试。

想亲自试用这些模型，请用 Xcode 打开 [`Examples/ModelLab`](Examples/ModelLab) 中的 `ModelLab.xcodeproj`，选择 iPhone 模拟器或 **My Mac**，然后点击 **Run**。App 包含一个快速开始标签页、一个带滑块并用你选择的模型对花进行分类的界面，以及这张图像；详情见 [Examples/README.md](Examples/README.md)。

## 文档

API 参考文档与文章：

- [API 参考](https://muhittincamdali.github.io/SwiftAI/documentation/swiftai/)（DocC，从 `master` 发布到 GitHub Pages）
- 在 Xcode 中通过 **Product › Build Documentation** 在本地构建，或使用命令行：

```sh
xcodebuild docbuild -scheme SwiftAI -destination 'generic/platform=macOS'
```

## 指南

- [Getting Started](https://muhittincamdali.github.io/SwiftAI/documentation/swiftai/gettingstarted)
  — 添加该包、训练分类器、评估并预测（[源文件](Sources/SwiftAI/SwiftAI.docc/GettingStarted.md)）。
- [Choosing a Model](https://muhittincamdali.github.io/SwiftAI/documentation/swiftai/choosingamodel)
  — 各模型擅长什么、是否需要缩放后的特征，以及关键设置（[源文件](Sources/SwiftAI/SwiftAI.docc/ChoosingAModel.md)）。
- [Preparing Data](https://muhittincamdali.github.io/SwiftAI/documentation/swiftai/preparingdata)
  — CSV 文件、划分、用流水线缩放以及 PCA（[源文件](Sources/SwiftAI/SwiftAI.docc/PreparingData.md)）。
- [Saving and Loading Models](https://muhittincamdali.github.io/SwiftAI/documentation/swiftai/savingmodels)
  — 将训练好的模型以 JSON 形式交付，以及加载时会检查什么（[源文件](Sources/SwiftAI/SwiftAI.docc/SavingModels.md)）。

## 系统要求

| 平台 | 最低版本 |
| ------------------- | ------------------ |
| iOS | 15 |
| macOS | 12 |
| tvOS | 15 |
| watchOS | 8 |
| visionOS | 1 |
| 工具链 | Swift 6.2 · Xcode 26+ |

ModelLab 示例 App 需要 iOS 17 或 macOS 14。

## 架构

- `Sources/SwiftAI/Core/` 包含 `Matrix`（按行存储的 `Double` 网格；乘法使用 Accelerate）、输入检查、`SeededGenerator`（SplitMix64）、Householder QR 最小二乘求解器和 L-BFGS 优化器。
- `Data/` 包含 `Dataset`（特征加目标，创建时校验一次）、划分与折叠、`CSVTable` 以及鸢尾花数据。`Preprocessing/`、`Models/`、`Trees/`、`NeuralNetwork/`、`Clustering/` 和 `Evaluation/` 放置其余部分，每个文件对应一个模型家族。
- 模型是由静态 `fit` 函数生成的不可变值类型，因此模型值一定是训练过的。分类器遵循 `Classifier`（以及 `ProbabilisticClassifier`），回归器遵循 `Regressor`；`accuracy(on:)`、`evaluate(on:)` 和批量预测等共用行为放在协议扩展中。
- 校验发生在公开边界（创建数据集、拟合、预测、解码）；内部代码信任这些检查。所有由用户控制大小的循环都有上界。
- 决策树以数组形式存储，子节点始终排在父节点之后；解码时会强制这一点，因此遍历一棵树总会结束。

在本地运行测试：

```sh
swift test                                    # macOS
xcodebuild test -scheme SwiftAI -destination 'platform=iOS Simulator,name=iPhone 17'
```

## 路线图

- 线性支持向量机、lasso 与 elastic-net 回归，以及多项式特征转换器。
- 梯度提升树。
- 将线性模型和树导出为 Core ML。
- 将该包提交到 Swift Package Index；`.spi.yml` 已在仓库中。

## 参与贡献

欢迎参与贡献。提交 pull request 之前，请先阅读[贡献指南](https://github.com/muhittincamdali/SwiftAI/blob/master/CONTRIBUTING.md)和[行为准则](https://github.com/muhittincamdali/.github/blob/main/CODE_OF_CONDUCT.md)。如发现安全问题，请按照[安全策略](https://github.com/muhittincamdali/SwiftAI/blob/master/SECURITY.md)私下报告。

## 许可证

基于 MIT 许可证发布。详见 [LICENSE](LICENSE)。
