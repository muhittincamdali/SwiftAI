<!-- i18n-source: README.md@e0c55bc21df63f9a2618b00bda59aa525f4235d2 status=reviewed -->
<!-- brand:start -->

<p align="center"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/banner-ko-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/banner-ko-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/banner-ko-light.svg" alt="SwiftAI: 순수 Swift 머신러닝: 기기에서 모델을 학습하고 평가하고 저장합니다."></picture></p>

<!-- lang-selector:start -->
<p align="center"><a href="README.md">English</a> · <a href="README.tr.md">Türkçe</a> · <a href="README.zh-CN.md">简体中文</a> · <a href="README.ja.md">日本語</a> · <a href="README.ko.md">한국어</a> · <a href="README.es.md">Español</a> · <a href="README.de.md">Deutsch</a> · <a href="README.fr.md">Français</a> · <a href="README.pt-BR.md">Português (Brasil)</a> · <a href="README.ru.md">Русский</a></p>
<!-- lang-selector:end -->

<p align="center">
<a href="https://github.com/muhittincamdali/SwiftAI/actions/workflows/ci.yml"><img src="https://github.com/muhittincamdali/SwiftAI/actions/workflows/ci.yml/badge.svg" alt="CI 상태"></a>
<a href="https://github.com/muhittincamdali/SwiftAI/releases"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/badge-version-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/badge-version-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/badge-version-light.svg" alt="최신 버전: v2.0.0"></picture></a>
<a href="https://github.com/muhittincamdali/SwiftAI/blob/master/Package.swift"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/badge-platforms-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/badge-platforms-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/badge-platforms-light.svg" alt="지원 플랫폼: iOS 15+ · macOS 12+ · tvOS 15+ · watchOS 8+ · visionOS 1+"></picture></a>
<a href="https://github.com/muhittincamdali/SwiftAI/blob/master/Package.swift"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/badge-language-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/badge-language-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/badge-language-light.svg" alt="언어 버전: Swift 6.2+"></picture></a>
<a href="https://github.com/muhittincamdali/SwiftAI/blob/master/LICENSE"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/badge-license-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/badge-license-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/badge-license-light.svg" alt="라이선스: MIT"></picture></a>
</p>

<p align="center">
<a href="#빠른-시작"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/button-start-ko-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/button-start-ko-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/button-start-ko-light.svg" alt="시작하기"></picture></a>
<a href="https://muhittincamdali.github.io/SwiftAI/documentation/swiftai/"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/button-docs-ko-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/button-docs-ko-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/button-docs-ko-light.svg" alt="문서"></picture></a>
<a href="https://github.com/muhittincamdali/SwiftAI/tree/master/Examples"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/button-examples-ko-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/button-examples-ko-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/button-examples-ko-light.svg" alt="예제"></picture></a>
</p>

> 이 문서는 영어 README의 번역본입니다. 내용이 다를 경우 영어 버전이 최신입니다.

<!-- brand:end -->

SwiftAI는 Apple 플랫폼에서 고전적인 머신러닝을 수행하는 Swift 패키지입니다. 숫자 표 데이터에 대한 분류, 회귀,
클러스터링, 차원 축소를 다룹니다. Python 툴체인이나 서버 없이 Swift로 기기에서 모델을 학습하거나 실행하려는
앱 개발자를 위한 패키지입니다. CSV나 배열에서 데이터를 불러와 분할하고, 함수 호출 한 번으로 모델을 학습하고,
평가한 다음, 앱에서 불러올 수 있도록 JSON으로 저장합니다. 이 패키지는 의존성이 없습니다.

## 주요 기능

- **지도 학습 모델 11종** — 선형 회귀와 릿지 회귀, 로지스틱 회귀, k-최근접 이웃, 가우시안 나이브 베이즈,
  의사결정 트리, 랜덤 포레스트, 신경망(해당하는 경우 분류기와 회귀기 모두), 그리고 k-means 클러스터링과 주성분 분석.
- **scikit-learn과 대조 검증** — scikit-learn에 같은 모델이 있으면 SwiftAI는 같은 목적 함수와 기본값을 사용하며,
  테스트에서 계수, 확률, 클러스터를 scikit-learn 1.9.1과 비교합니다
  (예: 로지스틱 회귀 확률은 1e-5, PCA는 1e-10까지 일치).
- **크래시 대신 오류** — 데이터나 설정을 받는 모든 함수가 입력을 검증하고, 무엇을 바꿔야 하는지 알려 주는
  `SwiftAIError`를 던집니다. NaN 값, 잘못된 특징 수, 오버플로하는 합계, 범위를 벗어난 설정, 숫자가 아닌 CSV 줄 등이 해당합니다.
- **안전하게 불러오기** — 모델, 스케일러, 파이프라인은 `Codable`입니다. 디코딩할 때 형태, 값, 클래스 목록,
  트리 구조를 검사하므로 손상되거나 조작된 파일이 예측을 크래시시킬 수 없습니다.
- **재현 가능** — 모든 무작위 단계(분할, 포레스트, k-means++, 네트워크 가중치)가 `seed`를 받습니다.
  같은 seed는 모든 플랫폼에서, 병렬로 학습한 포레스트에서도 같은 모델을 만듭니다.
- **Swift 6, 테스트 완료** — 엄격한 동시성 검사를 켠 Swift 6 언어 모드에서 경고 없이 빌드됩니다.
  Swift Testing 테스트 133개가 macOS와 iPhone 시뮬레이터에서 실행됩니다.

## 빠른 시작

**1. 패키지 추가**

Xcode에서 **File › Add Package Dependencies…**를 선택하고 저장소 URL을 입력하세요.

```text
https://github.com/muhittincamdali/SwiftAI.git
```

**2. 모듈 가져오기**

```swift
import SwiftAI
```

**3. 사용하기**

새 Xcode 앱(**File › New › Project… › App**)에서 `ContentView.swift`의 내용을 모두 다음으로 바꾸세요.

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

**Run**(⌘R)을 누르세요. 앱은 패키지에 포함된 붓꽃 150송이로 랜덤 포레스트를 학습하고,
테스트용 꽃 중 올바르게 분류한 비율과 새 꽃의 품종 `virginica`를 보여 줍니다.

## 설치

### Swift Package Manager

Xcode에서 **File › Add Package Dependencies…**를 선택하고 저장소 URL을 입력하세요.

```text
https://github.com/muhittincamdali/SwiftAI.git
```

또는 `Package.swift`의 `dependencies`에 추가하세요.

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

버전 2.0.0(2026년 10월)은 현재 라이브러리의 첫 릴리스입니다. 그 이전 릴리스인 1.0.0(2026년 2월)은
이보다 앞선 버전입니다. 1.0.0 출시 3일 후 앱 아키텍처 모듈이 제거되고 더 작은 머신러닝 코어가
작성되었습니다. 2026년 6월에는 이 코어가 리팩터링되어 테스트가 자리 표시자 테스트 하나로 줄었고,
작은 스텁 레이어 몇 개가 추가되었습니다. 2026년 10월에 검증된 데이터, 테스트를 거친 모델, 안전한
모델 파일을 중심으로 라이브러리를 처음부터 다시 만들었습니다. 두 버전의 API는 호환되지 않습니다.
변경 사항은 [CHANGELOG.md](CHANGELOG.md)에 정리되어 있습니다.

## 사용법

아래 예제는
[`Examples/ModelLab/ModelLab/ReadmeSamples.swift`](Examples/ModelLab/ModelLab/ReadmeSamples.swift)에서
복사한 것입니다. 예제 앱이 이 파일을 컴파일하고, 테스트 스위트도 이 파일을 컴파일해 모든 예제를 실행합니다.

### 내 데이터 불러오기

헤더 행이 있는 CSV 파일은 데이터셋이 됩니다. 타깃 열을 제외한 모든 열은 숫자여야 합니다.

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

### 특징을 스케일링하고 분류기 학습하기

`Pipeline`은 스케일러를 학습 데이터에만 맞추고, 이후의 모든 샘플을 같은 방식으로 스케일링합니다.

```swift
let (training, test) = try Dataset.iris.stratifiedSplit(testFraction: 0.3, seed: 1)
let model = try Pipeline.fit(training, transformer: StandardScaler.fit) { scaled in
    try LogisticRegression.fit(scaled)
}
let report = try model.evaluate(on: test)
print(report)                       // precision, recall and F1 per class
print(report.confusionMatrix)
```

### 숫자 예측하기

회귀 타깃에는 `Dataset<Double>`이라고 쓰세요. 정수 리터럴은 `Dataset<Int>`가 됩니다.

```swift
// Size in square metres and number of rooms → price.
let houses = try Dataset<Double>(
    features: [[50, 1], [65, 2], [80, 2], [95, 3], [120, 3], [140, 4]],
    targets: [150_000, 190_000, 236_000, 280_000, 350_000, 405_000]
)
let model = try LinearRegression.fit(houses, regularization: 0.1)
let price = try model.predict([100, 3])
```

### 교차 검증으로 모델 비교하기

```swift
let data = Dataset.iris
let results = [
    "k-nearest neighbours": try data.crossValidate(folds: 5) { try KNearestNeighborsClassifier.fit($0, k: 7) },
    "naive Bayes": try data.crossValidate(folds: 5) { try GaussianNaiveBayes.fit($0) },
    "decision tree": try data.crossValidate(folds: 5) { try DecisionTreeClassifier.fit($0, maxDepth: 3) },
]
```

### 모델을 저장하고 앱에서 불러오기

```swift
let model = try RandomForestClassifier.fit(Dataset.iris, treeCount: 50, seed: 7)
let file = FileManager.default.temporaryDirectory.appendingPathComponent("iris-forest.json")

try JSONEncoder().encode(model).write(to: file)
let data = try Data(contentsOf: file)
let loaded = try JSONDecoder().decode(RandomForestClassifier<String>.self, from: data)
// `loaded` predicts exactly like `model`
```

### 레이블 없이 그룹 찾기

```swift
let features = Dataset.iris.features
let pca = try PrincipalComponentAnalysis.fit(features, componentCount: 2)
let points = try pca.transform(features)          // 150 × 2, for a scatter plot
let kMeans = try KMeans.fit(points, clusterCount: 3, seed: 1)
let clusters = try kMeans.predict(points)          // 0, 1 or 2 per flower
```

## 데모

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="docs/images/decision-boundaries-dark.png">
  <img src="docs/images/decision-boundaries-light.png" alt="붓꽃 꽃잎 측정값으로 학습한 분류기 4개. 각 분류기가 평면 전체에서 예측하는 품종과 교차 검증 정확도를 보여 줍니다(k-최근접 이웃 96.0%, 로지스틱 회귀 95.3%, 의사결정 트리 94.0%, 신경망 96.0%)" width="780">
</picture>

색이 칠해진 각 칸은 붓꽃 150송이로 학습한 모델의 예측이고, 점은 꽃입니다. 이미지는
[`Examples/ModelLab/ModelLab/DecisionBoundaries.swift`](Examples/ModelLab/ModelLab/DecisionBoundaries.swift)
에서 [`scripts/generate-images.sh`](scripts/generate-images.sh)로 생성하며,
이 스크립트는 네 모델을 학습하는 테스트를 실행합니다.

모델을 직접 사용해 보려면 [`Examples/ModelLab`](Examples/ModelLab)의 `ModelLab.xcodeproj`를 Xcode로 열고,
iPhone 시뮬레이터나 **My Mac**을 선택한 다음 **Run**을 누르세요. 앱에는 빠른 시작 탭, 선택한 모델로 슬라이더 값에 따라
꽃을 분류하는 화면, 그리고 이 이미지가 있습니다. 자세한 내용은 [Examples/README.md](Examples/README.md)를 참고하세요.

## 문서

API 레퍼런스와 문서:

- [API 레퍼런스](https://muhittincamdali.github.io/SwiftAI/documentation/swiftai/)
  (DocC, `master`에서 GitHub Pages로 게시)
- Xcode에서 **Product › Build Documentation**으로 로컬에서 빌드하거나, 명령줄에서 빌드합니다.

```sh
xcodebuild docbuild -scheme SwiftAI -destination 'generic/platform=macOS'
```

## 가이드

- [Getting Started](https://muhittincamdali.github.io/SwiftAI/documentation/swiftai/gettingstarted)
  — 패키지 추가, 분류기 학습, 평가와 예측
  ([소스](Sources/SwiftAI/SwiftAI.docc/GettingStarted.md))
- [Choosing a Model](https://muhittincamdali.github.io/SwiftAI/documentation/swiftai/choosingamodel)
  — 각 모델의 강점, 스케일링한 특징이 필요한지 여부, 중요한 설정
  ([소스](Sources/SwiftAI/SwiftAI.docc/ChoosingAModel.md))
- [Preparing Data](https://muhittincamdali.github.io/SwiftAI/documentation/swiftai/preparingdata)
  — CSV 파일, 분할, 파이프라인을 통한 스케일링, PCA
  ([소스](Sources/SwiftAI/SwiftAI.docc/PreparingData.md))
- [Saving and Loading Models](https://muhittincamdali.github.io/SwiftAI/documentation/swiftai/savingmodels)
  — 학습한 모델을 JSON으로 배포하는 방법과 불러올 때 검사하는 항목
  ([소스](Sources/SwiftAI/SwiftAI.docc/SavingModels.md))

## 요구 사항

| 플랫폼 | 최소 버전 |
| ------------------- | ------------------ |
| iOS | 15 |
| macOS | 12 |
| tvOS | 15 |
| watchOS | 8 |
| visionOS | 1 |
| 툴체인 | Swift 6.2 · Xcode 26+ |

ModelLab 예제 앱에는 iOS 17 또는 macOS 14가 필요합니다.

## 아키텍처

- `Sources/SwiftAI/Core/`에는 `Matrix`(행 우선 `Double` 격자, 곱셈에는 Accelerate 사용), 입력 검사,
  `SeededGenerator`(SplitMix64), Householder QR 최소제곱 해법, L-BFGS 옵티마이저가 있습니다.
- `Data/`에는 `Dataset`(특징과 타깃, 생성 시 한 번 검증), 분할과 폴드, `CSVTable`, 붓꽃 데이터가 있습니다.
  `Preprocessing/`, `Models/`, `Trees/`, `NeuralNetwork/`, `Clustering/`, `Evaluation/`이 나머지를 담당하며,
  파일 하나가 모델 계열 하나입니다.
- 모델은 정적 `fit` 함수로 만들어지는 불변 값 타입이므로, 모델 값은 항상 학습이 끝난 상태입니다.
  분류기는 `Classifier`(그리고 `ProbabilisticClassifier`)를, 회귀기는 `Regressor`를 따르며,
  `accuracy(on:)`, `evaluate(on:)`, 일괄 예측 같은 공통 동작은 프로토콜 익스텐션에 있습니다.
- 검증은 공개 경계(데이터셋 생성, 학습, 예측, 디코딩)에서 이루어지며, 내부 코드는 그 검사를 신뢰합니다.
  사용자가 크기를 정하는 모든 반복문에는 상한이 있습니다.
- 의사결정 트리는 자식 노드가 항상 부모 노드 뒤에 오는 배열로 저장됩니다. 디코딩 시 이를 강제하므로 트리 순회는 항상 끝납니다.

로컬에서 테스트를 실행합니다.

```sh
swift test                                    # macOS
xcodebuild test -scheme SwiftAI -destination 'platform=iOS Simulator,name=iPhone 17'
```

## 로드맵

- 선형 서포트 벡터 머신, lasso와 elastic-net 회귀, 다항 특징 변환기.
- 그래디언트 부스팅 트리.
- 선형 모델과 트리를 Core ML로 내보내기.
- 패키지를 Swift Package Index에 추가하기. `.spi.yml`은 이미 저장소에 있습니다.

## 기여하기

기여를 환영합니다. pull request를 열기 전에 [기여 가이드](https://github.com/muhittincamdali/SwiftAI/blob/master/CONTRIBUTING.md)와 [행동 강령](https://github.com/muhittincamdali/.github/blob/main/CODE_OF_CONDUCT.md)을 읽어 주세요. 보안 문제는 [보안 정책](https://github.com/muhittincamdali/SwiftAI/blob/master/SECURITY.md)에 따라 비공개로 제보해 주세요.

## 라이선스

MIT 라이선스로 배포됩니다. 자세한 내용은 [LICENSE](LICENSE)를 참고하세요.
