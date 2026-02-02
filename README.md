# SwiftAI

```
╔═══════════════════════════════════════════════════════════════════════════════╗
║                                                                               ║
║   ███████╗██╗    ██╗██╗███████╗████████╗     █████╗ ██╗                       ║
║   ██╔════╝██║    ██║██║██╔════╝╚══██╔══╝    ██╔══██╗██║                       ║
║   ███████╗██║ █╗ ██║██║█████╗     ██║       ███████║██║                       ║
║   ╚════██║██║███╗██║██║██╔══╝     ██║       ██╔══██║██║                       ║
║   ███████║╚███╔███╔╝██║██║        ██║       ██║  ██║██║                       ║
║   ╚══════╝ ╚══╝╚══╝ ╚═╝╚═╝        ╚═╝       ╚═╝  ╚═╝╚═╝                       ║
║                                                                               ║
║              🤖 On-Device AI/ML Framework for Apple Platforms 🤖              ║
║                                                                               ║
╚═══════════════════════════════════════════════════════════════════════════════╝
```

<p align="center">
  <a href="https://swift.org"><img src="https://img.shields.io/badge/Swift-5.9+-F05138?style=flat&logo=swift&logoColor=white" alt="Swift 5.9+"></a>
  <a href="https://developer.apple.com/ios/"><img src="https://img.shields.io/badge/iOS-16.0+-000000?style=flat&logo=apple&logoColor=white" alt="iOS 16.0+"></a>
  <a href="https://developer.apple.com/macos/"><img src="https://img.shields.io/badge/macOS-13.0+-000000?style=flat&logo=apple&logoColor=white" alt="macOS 13.0+"></a>
  <a href="https://developer.apple.com/visionos/"><img src="https://img.shields.io/badge/visionOS-1.0+-007AFF?style=flat&logo=apple&logoColor=white" alt="visionOS 1.0+"></a>
  <a href="https://swift.org/package-manager/"><img src="https://img.shields.io/badge/SPM-Compatible-brightgreen.svg" alt="SPM Compatible"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-green.svg" alt="MIT License"></a>
</p>

<p align="center">
  <b>Powerful, privacy-first AI/ML framework built on CoreML and Apple's Neural Engine.</b>
  <br>
  <i>Run AI models on-device with zero cloud dependency. Fast, secure, and private.</i>
</p>

<p align="center">
  <a href="#-features">Features</a> •
  <a href="#-installation">Installation</a> •
  <a href="#-quick-start">Quick Start</a> •
  <a href="#-capabilities">Capabilities</a> •
  <a href="#-documentation">Documentation</a>
</p>

---

## 🌟 Why SwiftAI?

| Feature | SwiftAI | Cloud APIs |
|---------|---------|------------|
| **Privacy** | ✅ 100% on-device | ❌ Data sent to cloud |
| **Speed** | ✅ Neural Engine acceleration | ⚠️ Network latency |
| **Cost** | ✅ Free (no API costs) | ❌ Pay per request |
| **Offline** | ✅ Works anywhere | ❌ Requires internet |
| **Integration** | ✅ Native Swift | ⚠️ REST APIs |

---

## ✨ Features

### 🧠 AI Capabilities

```
┌─────────────────────────────────────────────────────────────┐
│                      SwiftAI Capabilities                    │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────┐   ┌─────────────┐   ┌─────────────┐       │
│  │   Vision    │   │     NLP     │   │    Audio    │       │
│  ├─────────────┤   ├─────────────┤   ├─────────────┤       │
│  │ • Classify  │   │ • Sentiment │   │ • Speech    │       │
│  │ • Detect    │   │ • Summarize │   │ • Transcribe│       │
│  │ • Segment   │   │ • Translate │   │ • Classify  │       │
│  │ • Track     │   │ • Generate  │   │ • Enhance   │       │
│  └─────────────┘   └─────────────┘   └─────────────┘       │
│                                                             │
│  ┌─────────────┐   ┌─────────────┐   ┌─────────────┐       │
│  │  Generative │   │ Predictive  │   │   Custom    │       │
│  ├─────────────┤   ├─────────────┤   ├─────────────┤       │
│  │ • Text      │   │ • Forecast  │   │ • CoreML    │       │
│  │ • Images    │   │ • Recommend │   │ • CreateML  │       │
│  │ • Code      │   │ • Anomaly   │   │ • Convert   │       │
│  └─────────────┘   └─────────────┘   └─────────────┘       │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### 🎯 Key Features

- ✅ **Apple Intelligence Ready** — Built for iOS 18+ AI features
- ✅ **Neural Engine Optimized** — Maximum performance on Apple Silicon
- ✅ **Privacy First** — All processing on-device
- ✅ **Zero Configuration** — Works out of the box
- ✅ **SwiftUI Integration** — Reactive AI components
- ✅ **Async/Await** — Modern Swift concurrency
- ✅ **Multi-Platform** — iOS, macOS, visionOS, watchOS, tvOS

---

## 📦 Installation

### Swift Package Manager

```swift
dependencies: [
    .package(url: "https://github.com/muhittincamdali/SwiftAI.git", from: "1.0.0")
]
```

---

## 🚀 Quick Start

### Image Classification

```swift
import SwiftAI

// One-line image classification
let result = try await SwiftAI.classify(image: uiImage)
print(result.topLabel) // "Golden Retriever"
print(result.confidence) // 0.95

// With custom model
let classifier = ImageClassifier(model: .custom("MyModel"))
let results = try await classifier.classify(image)
```

### Text Analysis

```swift
import SwiftAI

// Sentiment analysis
let sentiment = try await SwiftAI.analyzeSentiment("I love this app!")
print(sentiment.label) // .positive
print(sentiment.score) // 0.92

// Text summarization
let summary = try await SwiftAI.summarize(longText, maxLength: 100)

// Language detection
let language = try await SwiftAI.detectLanguage(text)
print(language) // "en"
```

### Speech Recognition

```swift
import SwiftAI

// Real-time transcription
let transcriber = SpeechTranscriber()
transcriber.onTranscript = { text in
    print("Heard: \(text)")
}
try await transcriber.start()

// Audio file transcription
let transcript = try await SwiftAI.transcribe(audioURL)
```

### Object Detection

```swift
import SwiftAI

// Detect objects in image
let detections = try await SwiftAI.detectObjects(in: image)
for detection in detections {
    print("\(detection.label) at \(detection.boundingBox)")
    print("Confidence: \(detection.confidence)")
}

// Real-time video detection
let detector = ObjectDetector()
detector.onDetection = { objects in
    // Update UI with detected objects
}
detector.process(sampleBuffer)
```

---

## 🧩 SwiftUI Integration

### AI-Powered Views

```swift
import SwiftUI
import SwiftAI

struct SmartImageView: View {
    @State private var classifications: [Classification] = []
    let image: UIImage
    
    var body: some View {
        VStack {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
            
            ClassificationResultsView(results: classifications)
        }
        .task {
            classifications = try? await SwiftAI.classify(image: image).all
        }
    }
}

// Pre-built AI camera view
struct CameraView: View {
    var body: some View {
        AICamera(mode: .objectDetection) { detections in
            // Handle real-time detections
        }
    }
}
```

---

## 📊 Capabilities

### Vision

| Feature | API | Performance |
|---------|-----|-------------|
| Image Classification | `SwiftAI.classify(image:)` | ~10ms |
| Object Detection | `SwiftAI.detectObjects(in:)` | ~15ms |
| Face Detection | `SwiftAI.detectFaces(in:)` | ~8ms |
| Text Recognition | `SwiftAI.recognizeText(in:)` | ~20ms |
| Image Segmentation | `SwiftAI.segment(image:)` | ~30ms |
| Barcode Scanning | `SwiftAI.scanBarcodes(in:)` | ~5ms |

### Natural Language

| Feature | API | Performance |
|---------|-----|-------------|
| Sentiment Analysis | `SwiftAI.analyzeSentiment(_:)` | ~5ms |
| Language Detection | `SwiftAI.detectLanguage(_:)` | ~2ms |
| Named Entity Recognition | `SwiftAI.extractEntities(_:)` | ~10ms |
| Text Summarization | `SwiftAI.summarize(_:)` | ~50ms |
| Translation | `SwiftAI.translate(_:to:)` | ~100ms |

### Audio

| Feature | API | Performance |
|---------|-----|-------------|
| Speech Recognition | `SwiftAI.transcribe(_:)` | Real-time |
| Sound Classification | `SwiftAI.classifySound(_:)` | ~10ms |
| Audio Enhancement | `SwiftAI.enhance(audio:)` | ~50ms |

---

## 🏗️ Architecture

```
┌──────────────────────────────────────────────────────────────┐
│                        SwiftAI                                │
├──────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌─────────────────────────────────────────────────────┐    │
│  │                   High-Level API                     │    │
│  │   classify() • detect() • transcribe() • analyze()  │    │
│  └─────────────────────────────────────────────────────┘    │
│                            │                                 │
│  ┌─────────────────────────────────────────────────────┐    │
│  │                   Domain Modules                     │    │
│  │  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌────────┐ │    │
│  │  │ Vision  │  │   NLP   │  │  Audio  │  │ Custom │ │    │
│  │  └─────────┘  └─────────┘  └─────────┘  └────────┘ │    │
│  └─────────────────────────────────────────────────────┘    │
│                            │                                 │
│  ┌─────────────────────────────────────────────────────┐    │
│  │                  Core Infrastructure                 │    │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────────────┐  │    │
│  │  │  CoreML  │  │  Vision  │  │  NaturalLanguage │  │    │
│  │  └──────────┘  └──────────┘  └──────────────────┘  │    │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────────────┐  │    │
│  │  │  Speech  │  │SoundAnal.│  │  Neural Engine   │  │    │
│  │  └──────────┘  └──────────┘  └──────────────────┘  │    │
│  └─────────────────────────────────────────────────────┘    │
│                                                              │
└──────────────────────────────────────────────────────────────┘
```

---

## 🛠 Requirements

| Platform | Minimum Version |
|----------|-----------------|
| iOS | 16.0+ |
| macOS | 13.0+ |
| visionOS | 1.0+ |
| watchOS | 9.0+ |
| tvOS | 16.0+ |
| Swift | 5.9+ |
| Xcode | 15.0+ |

---

## 📚 Documentation

- [Getting Started Guide](Documentation/GettingStarted.md)
- [Vision API Reference](Documentation/Vision.md)
- [NLP API Reference](Documentation/NLP.md)
- [Audio API Reference](Documentation/Audio.md)
- [Custom Models Guide](Documentation/CustomModels.md)
- [Performance Optimization](Documentation/Performance.md)

---

## 🤝 Contributing

Contributions welcome! See [CONTRIBUTING.md](CONTRIBUTING.md).

---

## 📄 License

MIT License - see [LICENSE](LICENSE).

---

## 👨‍💻 Author

**Muhittin Camdali**

[![Twitter](https://img.shields.io/badge/Twitter-@muhittincamdali-1DA1F2?style=flat&logo=twitter&logoColor=white)](https://twitter.com/muhittincamdali)
[![GitHub](https://img.shields.io/badge/GitHub-muhittincamdali-181717?style=flat&logo=github&logoColor=white)](https://github.com/muhittincamdali)

---

<p align="center">
  <b>Build intelligent apps with on-device AI. Star ⭐ if this helps you!</b>
</p>
