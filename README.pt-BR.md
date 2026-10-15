<!-- i18n-source: README.md@e0c55bc21df63f9a2618b00bda59aa525f4235d2 status=reviewed -->
<!-- brand:start -->

<p align="center"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/banner-pt-BR-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/banner-pt-BR-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/banner-pt-BR-light.svg" alt="SwiftAI: Aprendizado de máquina em Swift puro: treine, avalie e salve modelos no dispositivo."></picture></p>

<!-- lang-selector:start -->
<p align="center"><a href="README.md">English</a> · <a href="README.tr.md">Türkçe</a> · <a href="README.zh-CN.md">简体中文</a> · <a href="README.ja.md">日本語</a> · <a href="README.ko.md">한국어</a> · <a href="README.es.md">Español</a> · <a href="README.de.md">Deutsch</a> · <a href="README.fr.md">Français</a> · <a href="README.pt-BR.md">Português (Brasil)</a> · <a href="README.ru.md">Русский</a></p>
<!-- lang-selector:end -->

<p align="center">
<a href="https://github.com/muhittincamdali/SwiftAI/actions/workflows/ci.yml"><img src="https://github.com/muhittincamdali/SwiftAI/actions/workflows/ci.yml/badge.svg" alt="Status da CI"></a>
<a href="https://github.com/muhittincamdali/SwiftAI/releases"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/badge-version-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/badge-version-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/badge-version-light.svg" alt="Versão mais recente: v2.0.0"></picture></a>
<a href="https://github.com/muhittincamdali/SwiftAI/blob/master/Package.swift"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/badge-platforms-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/badge-platforms-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/badge-platforms-light.svg" alt="Plataformas compatíveis: iOS 15+ · macOS 12+ · tvOS 15+ · watchOS 8+ · visionOS 1+"></picture></a>
<a href="https://github.com/muhittincamdali/SwiftAI/blob/master/Package.swift"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/badge-language-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/badge-language-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/badge-language-light.svg" alt="Versão da linguagem: Swift 6.2+"></picture></a>
<a href="https://github.com/muhittincamdali/SwiftAI/blob/master/LICENSE"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/badge-license-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/badge-license-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/badge-license-light.svg" alt="Licença: MIT"></picture></a>
</p>

<p align="center">
<a href="#início-rápido"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/button-start-pt-BR-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/button-start-pt-BR-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/button-start-pt-BR-light.svg" alt="Começar"></picture></a>
<a href="https://muhittincamdali.github.io/SwiftAI/documentation/swiftai/"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/button-docs-pt-BR-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/button-docs-pt-BR-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/button-docs-pt-BR-light.svg" alt="Documentação"></picture></a>
<a href="https://github.com/muhittincamdali/SwiftAI/tree/master/Examples"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/button-examples-pt-BR-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/button-examples-pt-BR-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/SwiftAI/master/.github/brand/button-examples-pt-BR-light.svg" alt="Exemplos"></picture></a>
</p>

> Esta é uma tradução do README em inglês. Se houver diferença, vale a versão em inglês.

<!-- brand:end -->

O SwiftAI é um pacote Swift para aprendizado de máquina clássico nas plataformas Apple: classificação,
regressão, agrupamento (clustering) e redução de dimensionalidade em tabelas de números. Ele é para
desenvolvedores de apps que querem treinar ou executar um modelo no dispositivo, em Swift, sem uma
toolchain Python nem um servidor. Você carrega os dados de um CSV ou de arrays, divide, treina um modelo
com uma única chamada de função, mede o desempenho e salva em JSON para carregar no seu app. O pacote
não tem dependências.

## Destaques

- **Onze modelos supervisionados** — regressão linear e ridge, regressão logística, k vizinhos mais
  próximos, Naive Bayes gaussiano, árvores de decisão, florestas aleatórias e redes neurais
  (classificador e regressor quando se aplica), além de agrupamento k-means e análise de componentes principais.
- **Conferido com o scikit-learn** — quando o scikit-learn tem o mesmo modelo, o SwiftAI usa o mesmo
  objetivo e os mesmos padrões, e os testes comparam coeficientes, probabilidades e clusters com o
  scikit-learn 1.9.1 (por exemplo, probabilidades da regressão logística a 1e-5 e PCA a 1e-10).
- **Erros em vez de travamentos** — toda função que recebe dados ou configurações os valida e lança um
  `SwiftAIError` que diz o que mudar: valores NaN, número de features incorreto, somas que estouram,
  configurações fora do intervalo, linhas de CSV que não são números.
- **Carregamento seguro** — modelos, scalers e pipelines são `Codable`; a decodificação verifica
  formatos, valores, listas de classes e a estrutura das árvores, de modo que um arquivo danificado ou
  manipulado não consegue travar uma previsão.
- **Reproduzível** — toda etapa aleatória (divisões, florestas, k-means++, pesos da rede) recebe um
  `seed`; o mesmo seed gera o mesmo modelo em qualquer plataforma, inclusive em florestas treinadas em paralelo.
- **Swift 6, testado** — compila no modo de linguagem Swift 6 com verificação estrita de concorrência
  e sem avisos; 133 testes do Swift Testing rodam no macOS e em um simulador de iPhone.

## Início rápido

**1. Adicione o pacote**

No Xcode, escolha **File › Add Package Dependencies…** e informe a URL do repositório:

```text
https://github.com/muhittincamdali/SwiftAI.git
```

**2. Importe o módulo**

```swift
import SwiftAI
```

**3. Use**

Em um app novo do Xcode (**File › New › Project… › App**), substitua todo o conteúdo de
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

Clique em **Run** (⌘R). O app treina uma floresta aleatória com as 150 flores íris que acompanham o
pacote e mostra a porcentagem de flores de teste classificadas corretamente e a espécie de uma flor
nova: `virginica`.

## Instalação

### Swift Package Manager

No Xcode, escolha **File › Add Package Dependencies…** e informe a URL do repositório:

```text
https://github.com/muhittincamdali/SwiftAI.git
```

Ou adicione-o às `dependencies` do seu `Package.swift`:

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

A versão 2.0.0 (outubro de 2026) é o primeiro lançamento da biblioteca atual. O lançamento anterior,
1.0.0 (fevereiro de 2026), é anterior a ela: três dias após o lançamento, os módulos de arquitetura de
aplicativo foram removidos e um núcleo menor de aprendizado de máquina foi escrito; em junho de 2026
esse núcleo foi refatorado, os testes foram reduzidos a um único teste de espaço reservado e algumas
pequenas camadas stub foram adicionadas; em outubro de 2026 a biblioteca foi reconstruída do zero em
torno de dados validados, modelos testados e arquivos de modelo seguros. As APIs não são compatíveis;
o [CHANGELOG.md](CHANGELOG.md) lista as mudanças.

## Uso

Os exemplos abaixo foram copiados de
[`Examples/ModelLab/ModelLab/ReadmeSamples.swift`](Examples/ModelLab/ModelLab/ReadmeSamples.swift).
O app de exemplo compila esse arquivo, e a suíte de testes o compila e executa cada exemplo.

### Carregue seus próprios dados

Um arquivo CSV com linha de cabeçalho vira um conjunto de dados; todas as colunas, exceto o alvo, devem conter números.

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

### Escale as features e treine um classificador

Um `Pipeline` ajusta o scaler apenas com os dados de treino e escala todas as amostras seguintes da mesma forma.

```swift
let (training, test) = try Dataset.iris.stratifiedSplit(testFraction: 0.3, seed: 1)
let model = try Pipeline.fit(training, transformer: StandardScaler.fit) { scaled in
    try LogisticRegression.fit(scaled)
}
let report = try model.evaluate(on: test)
print(report)                       // precision, recall and F1 per class
print(report.confusionMatrix)
```

### Preveja um número

Escreva `Dataset<Double>` para alvos de regressão; literais inteiros resultariam em um `Dataset<Int>`.

```swift
// Size in square metres and number of rooms → price.
let houses = try Dataset<Double>(
    features: [[50, 1], [65, 2], [80, 2], [95, 3], [120, 3], [140, 4]],
    targets: [150_000, 190_000, 236_000, 280_000, 350_000, 405_000]
)
let model = try LinearRegression.fit(houses, regularization: 0.1)
let price = try model.predict([100, 3])
```

### Compare modelos com validação cruzada

```swift
let data = Dataset.iris
let results = [
    "k-nearest neighbours": try data.crossValidate(folds: 5) { try KNearestNeighborsClassifier.fit($0, k: 7) },
    "naive Bayes": try data.crossValidate(folds: 5) { try GaussianNaiveBayes.fit($0) },
    "decision tree": try data.crossValidate(folds: 5) { try DecisionTreeClassifier.fit($0, maxDepth: 3) },
]
```

### Salve um modelo e carregue-o no app

```swift
let model = try RandomForestClassifier.fit(Dataset.iris, treeCount: 50, seed: 7)
let file = FileManager.default.temporaryDirectory.appendingPathComponent("iris-forest.json")

try JSONEncoder().encode(model).write(to: file)
let data = try Data(contentsOf: file)
let loaded = try JSONDecoder().decode(RandomForestClassifier<String>.self, from: data)
// `loaded` predicts exactly like `model`
```

### Encontre grupos sem rótulos

```swift
let features = Dataset.iris.features
let pca = try PrincipalComponentAnalysis.fit(features, componentCount: 2)
let points = try pca.transform(features)          // 150 × 2, for a scatter plot
let kMeans = try KMeans.fit(points, clusterCount: 3, seed: 1)
let clusters = try kMeans.predict(points)          // 0, 1 or 2 per flower
```

## Demonstração

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="docs/images/decision-boundaries-dark.png">
  <img src="docs/images/decision-boundaries-light.png" alt="Quatro classificadores treinados com as medidas das pétalas da íris, com a espécie que cada um prevê no plano e sua acurácia com validação cruzada (k vizinhos mais próximos 96,0%, regressão logística 95,3%, árvore de decisão 94,0%, rede neural 96,0%)" width="780">
</picture>

Cada célula colorida é uma previsão do modelo treinado com as 150 flores íris; os pontos são as
flores. A imagem é gerada a partir de
[`Examples/ModelLab/ModelLab/DecisionBoundaries.swift`](Examples/ModelLab/ModelLab/DecisionBoundaries.swift)
por [`scripts/generate-images.sh`](scripts/generate-images.sh), que executa o teste que treina os
quatro modelos.

Para experimentar os modelos você mesmo, abra `ModelLab.xcodeproj` em [`Examples/ModelLab`](Examples/ModelLab)
com o Xcode, escolha um simulador de iPhone ou **My Mac** e clique em **Run**. O app tem uma aba de
início rápido, uma tela com controles deslizantes que classifica uma flor com o modelo escolhido e esta
imagem; o [Examples/README.md](Examples/README.md) traz os detalhes.

## Documentação

Referência da API e artigos:

- [Referência da API](https://muhittincamdali.github.io/SwiftAI/documentation/swiftai/)
  (DocC, publicada no GitHub Pages a partir de `master`)
- Gere localmente no Xcode com **Product › Build Documentation** ou pela linha de comando:

```sh
xcodebuild docbuild -scheme SwiftAI -destination 'generic/platform=macOS'
```

## Guias

- [Getting Started](https://muhittincamdali.github.io/SwiftAI/documentation/swiftai/gettingstarted)
  — adicione o pacote, treine um classificador, meça o desempenho e faça previsões
  ([código-fonte](Sources/SwiftAI/SwiftAI.docc/GettingStarted.md)).
- [Choosing a Model](https://muhittincamdali.github.io/SwiftAI/documentation/swiftai/choosingamodel)
  — no que cada modelo é bom, se ele precisa de features escaladas e as configurações que importam
  ([código-fonte](Sources/SwiftAI/SwiftAI.docc/ChoosingAModel.md)).
- [Preparing Data](https://muhittincamdali.github.io/SwiftAI/documentation/swiftai/preparingdata)
  — arquivos CSV, divisões, escala com um pipeline e PCA
  ([código-fonte](Sources/SwiftAI/SwiftAI.docc/PreparingData.md)).
- [Saving and Loading Models](https://muhittincamdali.github.io/SwiftAI/documentation/swiftai/savingmodels)
  — distribua um modelo treinado como JSON e o que a leitura verifica
  ([código-fonte](Sources/SwiftAI/SwiftAI.docc/SavingModels.md)).

## Requisitos

| Plataforma | Versão mínima |
| ------------------- | ------------------ |
| iOS | 15 |
| macOS | 12 |
| tvOS | 15 |
| watchOS | 8 |
| visionOS | 1 |
| Ferramentas | Swift 6.2 · Xcode 26+ |

O app de exemplo ModelLab exige iOS 17 ou macOS 14.

## Arquitetura

- `Sources/SwiftAI/Core/` contém `Matrix` (uma grade de `Double` em ordem de linhas; os produtos usam
  o Accelerate), as verificações de entrada, o `SeededGenerator` (SplitMix64), o solver de mínimos
  quadrados com QR de Householder e o otimizador L-BFGS.
- `Data/` tem `Dataset` (features mais alvos, validados uma vez na criação), divisão e folds,
  `CSVTable` e os dados da íris. `Preprocessing/`, `Models/`, `Trees/`, `NeuralNetwork/`, `Clustering/`
  e `Evaluation/` guardam o resto, com uma família de modelos por arquivo.
- Os modelos são tipos de valor imutáveis criados por uma função estática `fit`, então um valor de
  modelo sempre está treinado. Os classificadores seguem `Classifier` (e `ProbabilisticClassifier`) e os
  regressores seguem `Regressor`; comportamentos compartilhados, como `accuracy(on:)`, `evaluate(on:)` e
  a previsão em lote, ficam em extensões de protocolo.
- A validação acontece na fronteira pública (criar um conjunto de dados, treinar, prever, decodificar);
  o código interno confia nessas verificações. Todo laço sobre tamanhos controlados pelo usuário é limitado.
- As árvores de decisão são armazenadas como arrays em que os filhos sempre vêm depois do pai; a
  decodificação impõe isso, então percorrer uma árvore sempre termina.

Execute os testes localmente:

```sh
swift test                                    # macOS
xcodebuild test -scheme SwiftAI -destination 'platform=iOS Simulator,name=iPhone 17'
```

## Roteiro

- Máquinas de vetores de suporte lineares, regressão lasso e elastic-net e um transformador de
  features polinomiais.
- Árvores com gradient boosting.
- Exportação de modelos lineares e árvores para o Core ML.
- Adicionar o pacote ao Swift Package Index; o `.spi.yml` já está no repositório.

## Como contribuir

Contribuições são bem-vindas. Leia o [guia de contribuição](https://github.com/muhittincamdali/SwiftAI/blob/master/CONTRIBUTING.md) e o [código de conduta](https://github.com/muhittincamdali/.github/blob/main/CODE_OF_CONDUCT.md) antes de abrir um pull request. Relate problemas de segurança de forma privada, como descrito na [política de segurança](https://github.com/muhittincamdali/SwiftAI/blob/master/SECURITY.md).

## Licença

Publicado sob a licença MIT. Veja [LICENSE](LICENSE).
