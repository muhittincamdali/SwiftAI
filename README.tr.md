<!-- i18n-source: README.md@f259cb6cdf7b9b545881d4d6ec8eef1e0f111f95 status=reviewed -->
<!-- brand:start -->

<p align="center"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/banner-tr-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/banner-tr-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/banner-tr-light.svg" alt="SwiftAI: Saf Swift ile makine öğrenmesi: modelleri cihazda eğitin, değerlendirin ve kaydedin."></picture></p>

<!-- lang-selector:start -->
<p align="center"><a href="README.md">English</a> · <a href="README.tr.md">Türkçe</a> · <a href="README.zh-CN.md">简体中文</a> · <a href="README.ja.md">日本語</a> · <a href="README.ko.md">한국어</a> · <a href="README.es.md">Español</a> · <a href="README.de.md">Deutsch</a> · <a href="README.fr.md">Français</a> · <a href="README.pt-BR.md">Português (Brasil)</a> · <a href="README.ru.md">Русский</a></p>
<!-- lang-selector:end -->

<p align="center">
<a href="https://github.com/muhittincamdali/SwiftAI/actions/workflows/ci.yml"><img src="https://github.com/muhittincamdali/SwiftAI/actions/workflows/ci.yml/badge.svg" alt="CI durumu"></a>
<a href="https://github.com/muhittincamdali/SwiftAI/releases"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/badge-version-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/badge-version-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/badge-version-light.svg" alt="Son sürüm: v2.0.0"></picture></a>
<a href="https://github.com/muhittincamdali/SwiftAI/blob/master/Package.swift"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/badge-platforms-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/badge-platforms-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/badge-platforms-light.svg" alt="Desteklenen platformlar: iOS 15+ · macOS 12+ · tvOS 15+ · watchOS 8+ · visionOS 1+"></picture></a>
<a href="https://github.com/muhittincamdali/SwiftAI/blob/master/Package.swift"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/badge-language-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/badge-language-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/badge-language-light.svg" alt="Dil sürümü: Swift 6.2+"></picture></a>
<a href="https://github.com/muhittincamdali/SwiftAI/blob/master/LICENSE"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/badge-license-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/badge-license-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/badge-license-light.svg" alt="Lisans: MIT"></picture></a>
</p>

<p align="center">
<a href="#hızlı-başlangıç"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/button-start-tr-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/button-start-tr-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/button-start-tr-light.svg" alt="Başlayın"></picture></a>
<a href="https://muhittincamdali.github.io/SwiftAI/documentation/swiftai/"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/button-docs-tr-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/button-docs-tr-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/button-docs-tr-light.svg" alt="Dokümantasyon"></picture></a>
<a href="https://github.com/muhittincamdali/SwiftAI/tree/master/Examples"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/button-examples-tr-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/button-examples-tr-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/button-examples-tr-light.svg" alt="Örnekler"></picture></a>
</p>

> Bu belge İngilizce README'nin çevirisidir. İkisi arasında fark varsa güncel olan İngilizce sürümdür.

<!-- brand:end -->

SwiftAI, Apple platformlarında klasik makine öğrenmesi için bir Swift paketidir: sayı tablolarında
sınıflandırma, regresyon, kümeleme ve boyut indirgeme. Python araç zinciri ya da sunucu olmadan,
Swift ile cihaz üzerinde model eğitmek veya çalıştırmak isteyen uygulama geliştiriciler için
hazırlanmıştır. Verileri CSV'den ya da dizilerden yükler, bölersiniz; tek bir fonksiyon çağrısıyla
model eğitir, ölçer ve uygulamanızda yüklemek üzere JSON olarak kaydedersiniz. Paketin hiçbir
bağımlılığı yoktur.

## Öne çıkanlar

- **On bir denetimli model** — doğrusal ve ridge regresyon, lojistik regresyon, k-en yakın komşu,
  Gaussian naive Bayes, karar ağaçları, rastgele ormanlar ve sinir ağları (uygun olduğu yerde
  sınıflandırıcı ve regresör), ayrıca k-means kümeleme ve temel bileşen analizi.
- **scikit-learn ile karşılaştırıldı** — scikit-learn'de aynı model varsa SwiftAI aynı amaç
  fonksiyonunu ve varsayılanları kullanır; testler katsayıları, olasılıkları ve kümeleri
  scikit-learn 1.9.1 ile karşılaştırır (örneğin lojistik regresyon olasılıkları 1e-5, PCA 1e-10
  hassasiyetle).
- **Çökme yerine hata** — veri veya ayar alan her fonksiyon girdiyi doğrular ve neyin
  değişmesi gerektiğini söyleyen bir `SwiftAIError` fırlatır: NaN değerler, yanlış özellik sayısı,
  taşan toplamlar, aralık dışı ayarlar, sayı olmayan CSV satırları.
- **Güvenle yüklenir** — modeller, ölçekleyiciler ve pipeline'lar `Codable`'dır; kod çözme
  şekilleri, değerleri, sınıf listelerini ve ağaç yapısını denetler, böylece hasarlı veya
  kasıtlı hazırlanmış bir dosya tahmini çökertemez.
- **Tekrarlanabilir** — her rastgele adım (bölmeler, ormanlar, k-means++, ağ ağırlıkları) bir
  `seed` alır; aynı seed her platformda aynı modeli verir, paralel eğitilen ormanlarda da.
- **Swift 6, test edilmiş** — Swift 6 dil modunda, sıkı eşzamanlılık denetimiyle ve uyarısız
  derlenir; 133 Swift Testing testi macOS'ta ve bir iPhone simülatöründe çalışır.

## Hızlı başlangıç

**1. Paketi ekleyin**

Xcode'da **File › Add Package Dependencies…** menüsünü seçin ve depo adresini girin:

```text
https://github.com/muhittincamdali/SwiftAI.git
```

**2. Modülü içe aktarın**

```swift
import SwiftAI
```

**3. Kullanın**

Yeni bir Xcode uygulamasında (**File › New › Project… › App**) `ContentView.swift` dosyasının
tüm içeriğini şununla değiştirin:

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

**Run**'a (⌘R) basın. Uygulama, paketle birlikte gelen 150 iris çiçeği üzerinde bir rastgele orman
eğitir; test çiçeklerinin doğru sınıflandırılan oranını ve yeni bir çiçeğin türünü gösterir:
`virginica`.

## Kurulum

### Swift Package Manager

Xcode'da **File › Add Package Dependencies…** menüsünü seçin ve depo adresini girin:

```text
https://github.com/muhittincamdali/SwiftAI.git
```

Ya da `Package.swift` dosyanızdaki `dependencies` listesine ekleyin:

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

Sürüm 2.0.0 (Ekim 2026), kitaplığın güncel halinin ilk sürümüdür. Daha önceki sürüm olan
1.0.0 (Şubat 2026) bunun öncesine aittir: Haziran 2026'da kaynak kodu yer tutucu kodla
değiştirilmişti; Ekim 2026'da kitaplık, doğrulanmış veri, test edilmiş modeller ve güvenli model
dosyaları etrafında sıfırdan yeniden yazıldı. API'ler uyumlu değildir; değişiklikler
[CHANGELOG.md](CHANGELOG.md) dosyasında listelenir.

## Kullanım

Aşağıdaki örnekler
[`Examples/ModelLab/ModelLab/ReadmeSamples.swift`](Examples/ModelLab/ModelLab/ReadmeSamples.swift)
dosyasından kopyalanmıştır. Örnek uygulama bu dosyayı derler; test paketi de dosyayı derleyip her
örneği çalıştırır.

### Kendi verinizi yükleyin

Başlık satırı olan bir CSV dosyası veri kümesine dönüşür; hedef dışındaki her sütun sayı içermelidir.

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

### Özellikleri ölçekleyin ve bir sınıflandırıcı eğitin

`Pipeline`, ölçekleyiciyi yalnızca eğitim verisine uydurur ve sonraki her örneği aynı şekilde ölçekler.

```swift
let (training, test) = try Dataset.iris.stratifiedSplit(testFraction: 0.3, seed: 1)
let model = try Pipeline.fit(training, transformer: StandardScaler.fit) { scaled in
    try LogisticRegression.fit(scaled)
}
let report = try model.evaluate(on: test)
print(report)                       // precision, recall and F1 per class
print(report.confusionMatrix)
```

### Bir sayıyı tahmin edin

Regresyon hedefleri için `Dataset<Double>` yazın; tamsayı sabitleri `Dataset<Int>` oluştururdu.

```swift
// Size in square metres and number of rooms → price.
let houses = try Dataset<Double>(
    features: [[50, 1], [65, 2], [80, 2], [95, 3], [120, 3], [140, 4]],
    targets: [150_000, 190_000, 236_000, 280_000, 350_000, 405_000]
)
let model = try LinearRegression.fit(houses, regularization: 0.1)
let price = try model.predict([100, 3])
```

### Modelleri çapraz doğrulamayla karşılaştırın

```swift
let data = Dataset.iris
let results = [
    "k-nearest neighbours": try data.crossValidate(folds: 5) { try KNearestNeighborsClassifier.fit($0, k: 7) },
    "naive Bayes": try data.crossValidate(folds: 5) { try GaussianNaiveBayes.fit($0) },
    "decision tree": try data.crossValidate(folds: 5) { try DecisionTreeClassifier.fit($0, maxDepth: 3) },
]
```

### Modeli kaydedin ve uygulamada yükleyin

```swift
let model = try RandomForestClassifier.fit(Dataset.iris, treeCount: 50, seed: 7)
let file = FileManager.default.temporaryDirectory.appendingPathComponent("iris-forest.json")

try JSONEncoder().encode(model).write(to: file)
let data = try Data(contentsOf: file)
let loaded = try JSONDecoder().decode(RandomForestClassifier<String>.self, from: data)
// `loaded` predicts exactly like `model`
```

### Etiketsiz grupları bulun

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
  <img src="docs/images/decision-boundaries-light.png" alt="İris taç yaprağı ölçümleriyle eğitilmiş dört sınıflandırıcı: her birinin düzlem boyunca tahmin ettiği tür ve çapraz doğrulamalı doğrulukları (k-en yakın komşu %96,0, lojistik regresyon %95,3, karar ağacı %94,0, sinir ağı %96,0)" width="780">
</picture>

Renkli her hücre, 150 iris çiçeğiyle eğitilmiş modelin bir tahminidir; noktalar çiçeklerdir.
Görsel,
[`Examples/ModelLab/ModelLab/DecisionBoundaries.swift`](Examples/ModelLab/ModelLab/DecisionBoundaries.swift)
dosyasından, dört modeli eğiten testi çalıştıran [`scripts/generate-images.sh`](scripts/generate-images.sh)
betiğiyle üretilir.

Modelleri kendiniz denemek için [`Examples/ModelLab`](Examples/ModelLab) içindeki
`ModelLab.xcodeproj` dosyasını Xcode ile açın, bir iPhone simülatörü ya da **My Mac** seçin ve
**Run**'a basın. Uygulamada bir hızlı başlangıç sekmesi, seçtiğiniz modelle çiçek sınıflandıran
kaydırıcılı bir ekran ve bu görsel bulunur; ayrıntılar [Examples/README.md](Examples/README.md)
dosyasındadır.

## Dokümantasyon

API başvuru belgeleri ve makaleler:

- [API başvurusu](https://muhittincamdali.github.io/SwiftAI/documentation/swiftai/)
  (DocC, `master` dalından GitHub Pages'e yayımlanır)
- Xcode'da **Product › Build Documentation** ile ya da komut satırından yerelde derleyin:

```sh
xcodebuild docbuild -scheme SwiftAI -destination 'generic/platform=macOS'
```

## Rehberler

- [Getting Started](https://muhittincamdali.github.io/SwiftAI/documentation/swiftai/gettingstarted)
  — paketi ekleyin, bir sınıflandırıcı eğitin, ölçün ve tahmin yapın
  ([kaynak](Sources/SwiftAI/SwiftAI.docc/GettingStarted.md)).
- [Choosing a Model](https://muhittincamdali.github.io/SwiftAI/documentation/swiftai/choosingamodel)
  — her modelin hangi işte iyi olduğu, ölçeklenmiş özellik gerektirip gerektirmediği ve önemli ayarlar
  ([kaynak](Sources/SwiftAI/SwiftAI.docc/ChoosingAModel.md)).
- [Preparing Data](https://muhittincamdali.github.io/SwiftAI/documentation/swiftai/preparingdata)
  — CSV dosyaları, bölmeler, pipeline ile ölçekleme ve PCA
  ([kaynak](Sources/SwiftAI/SwiftAI.docc/PreparingData.md)).
- [Saving and Loading Models](https://muhittincamdali.github.io/SwiftAI/documentation/swiftai/savingmodels)
  — eğitilmiş modeli JSON olarak dağıtın ve yükleme sırasında nelerin denetlendiği
  ([kaynak](Sources/SwiftAI/SwiftAI.docc/SavingModels.md)).

## Gereksinimler

| Platform | En düşük sürüm |
| ------------------- | ------------------ |
| iOS | 15 |
| macOS | 12 |
| tvOS | 15 |
| watchOS | 8 |
| visionOS | 1 |
| Araç zinciri | Swift 6.2 · Xcode 26+ |

ModelLab örnek uygulaması iOS 17 veya macOS 14 gerektirir.

## Mimari

- `Sources/SwiftAI/Core/` içinde `Matrix` (satır öncelikli `Double` ızgarası; çarpımlar
  Accelerate kullanır), girdi denetimleri, `SeededGenerator` (SplitMix64), Householder QR en küçük
  kareler çözücüsü ve L-BFGS eniyileyicisi bulunur.
- `Data/` içinde `Dataset` (özellikler ve hedefler; oluşturulurken bir kez doğrulanır), bölme ve
  katlar, `CSVTable` ve iris verisi yer alır. `Preprocessing/`, `Models/`, `Trees/`,
  `NeuralNetwork/`, `Clustering/` ve `Evaluation/` gerisini içerir; her dosyada bir model ailesi vardır.
- Modeller, statik bir `fit` fonksiyonuyla üretilen değiştirilemez değer tipleridir; dolayısıyla bir
  model değeri her zaman eğitilmiştir. Sınıflandırıcılar `Classifier` (ve `ProbabilisticClassifier`),
  regresörler `Regressor` protokolüne uyar; `accuracy(on:)`, `evaluate(on:)` ve toplu tahmin gibi
  ortak davranışlar protokol extension'larındadır.
- Doğrulama, genel API sınırında yapılır (veri kümesi oluşturma, eğitim, tahmin, kod çözme); iç kod
  bu denetimlere güvenir. Kullanıcı tarafından belirlenen boyutlar üzerindeki her döngü sınırlıdır.
- Karar ağaçları, alt düğümlerin her zaman üst düğümlerinden sonra geldiği dizilerde saklanır; kod çözme
  bunu zorunlu kılar, bu yüzden bir ağaçta gezinme her zaman sona erer.

Testleri yerelde çalıştırın:

```sh
swift test                                    # macOS
xcodebuild test -scheme SwiftAI -destination 'platform=iOS Simulator,name=iPhone 17'
```

## Yol haritası

- Doğrusal destek vektör makineleri, lasso ve elastic-net regresyon, ayrıca polinom özellikler
  dönüştürücüsü.
- Gradyan artırmalı ağaçlar.
- Doğrusal modellerin ve ağaçların Core ML'e aktarılması.
- Paketi Swift Package Index'e eklemek; `.spi.yml` zaten depoda.

## Katkıda bulunma

Katkılarınızı bekliyoruz. Pull request açmadan önce [katkı rehberini](https://github.com/muhittincamdali/SwiftAI/blob/master/CONTRIBUTING.md) ve [davranış kurallarını](https://github.com/muhittincamdali/.github/blob/main/CODE_OF_CONDUCT.md) okuyun. Güvenlik açıklarını [güvenlik politikasında](https://github.com/muhittincamdali/SwiftAI/blob/master/SECURITY.md) anlatıldığı gibi gizli olarak bildirin.

## Lisans

MIT lisansıyla yayımlanmıştır. Ayrıntılar için [LICENSE](LICENSE) dosyasına bakın.
