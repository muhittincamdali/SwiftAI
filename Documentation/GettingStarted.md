# 🚀 Getting Started with SwiftAI

Quick start guide for integrating SwiftAI into your iOS applications.

## 📋 Table of Contents

- [Installation](#installation)
- [Basic Usage](#basic-usage)
- [Advanced Features](#advanced-features)
- [Configuration](#configuration)
- [Troubleshooting](#troubleshooting)

## 📦 Installation

### Swift Package Manager

Add SwiftAI to your project using Swift Package Manager:

1. **In Xcode**: File → Add Package Dependencies
2. **Enter URL**: `https://github.com/muhittincamdali/SwiftAI.git`
3. **Select Version**: Choose the latest version
4. **Add to Target**: Select your app target

### CocoaPods

Add to your `Podfile`:

```ruby
pod 'SwiftAI', '~> 1.0'
```

Then run:
```bash
pod install
```

### Manual Installation

1. Download the source code
2. Add `Sources/` folder to your project
3. Link required frameworks:
   - CoreML
   - Vision
   - NaturalLanguage

## 🎯 Basic Usage

### Import SwiftAI

```swift
import SwiftAI
```

### Initialize AI Engine

```swift
let aiEngine = AIEngine()
```

### Text Classification

```swift
// Simple text classification
let textInput = AIInput.text("I love this product!")
let result = try await aiEngine.process(textInput, type: .text)

switch result {
case .classification(let classifications):
    print("Classifications: \(classifications)")
case .sentiment(let sentiment):
    print("Sentiment: \(sentiment)")
default:
    break
}
```

### Image Classification

```swift
// Image classification
guard let image = UIImage(named: "photo") else { return }
let imageInput = AIInput.image(image)
let result = try await aiEngine.process(imageInput, type: .image)

switch result {
case .detection(let detections):
    for detection in detections {
        print("Detected: \(detection.label) with confidence: \(detection.confidence)")
    }
default:
    break
}
```

### Batch Processing

```swift
// Process multiple inputs efficiently
let inputs = [
    AIInput.text("Positive review"),
    AIInput.text("Negative review"),
    AIInput.text("Neutral review")
]

let results = try await aiEngine.processBatch(inputs, type: .text)

for (index, result) in results.enumerated() {
    print("Result \(index): \(result)")
}
```

## ⚡ Advanced Features

### Custom Model Configuration

```swift
// Create custom model manager
class CustomModelManager: ModelManagerProtocol {
    func loadModel(name: String) async throws -> MLModel {
        // Custom model loading logic
        guard let modelURL = Bundle.main.url(forResource: name, withExtension: "mlmodel") else {
            throw AIError.modelNotFound
        }
        return try MLModel(contentsOf: modelURL)
    }
    
    func validateModel(_ model: MLModel) async throws -> Bool {
        // Custom validation logic
        return true
    }
    
    func optimizeModel(_ model: MLModel) async throws -> MLModel {
        // Custom optimization logic
        return model
    }
    
    func clearCache() async {
        // Custom cache clearing logic
    }
}

// Use custom model manager
let customModelManager = CustomModelManager()
let aiEngine = AIEngine(modelManager: customModelManager)
```

### Performance Monitoring

```swift
// Monitor performance metrics
let aiEngine = AIEngine()

// Perform some operations
let result = try await aiEngine.process(input, type: .text)

// Get performance metrics
let metrics = aiEngine.getPerformanceMetrics()
print("Average inference time: \(metrics.averageInferenceTime)ms")
print("Memory usage: \(metrics.memoryUsage) bytes")
print("Cache hit rate: \(metrics.cacheHitRate)")
```

### Error Handling

```swift
do {
    let result = try await aiEngine.process(input, type: .text)
    // Handle success
} catch AIError.modelNotFound {
    print("Model not found")
} catch AIError.invalidInput {
    print("Invalid input provided")
} catch AIError.inferenceFailed {
    print("Inference failed")
} catch {
    print("Unexpected error: \(error)")
}
```

## ⚙️ Configuration

### Model Configuration

```swift
// Configure model settings
struct ModelConfiguration {
    let enableGPU: Bool
    let enableNeuralEngine: Bool
    let batchSize: Int
    let cacheSize: Int
}

let config = ModelConfiguration(
    enableGPU: true,
    enableNeuralEngine: true,
    batchSize: 10,
    cacheSize: 100
)
```

### Performance Configuration

```swift
// Configure performance settings
struct PerformanceConfiguration {
    let maxMemoryUsage: Int64
    let inferenceTimeout: TimeInterval
    let enableMonitoring: Bool
}

let perfConfig = PerformanceConfiguration(
    maxMemoryUsage: 100 * 1024 * 1024, // 100MB
    inferenceTimeout: 10.0,
    enableMonitoring: true
)
```

### Security Configuration

```swift
// Configure security settings
struct SecurityConfiguration {
    let enableModelValidation: Bool
    let enableInputValidation: Bool
    let enableSecureStorage: Bool
}

let securityConfig = SecurityConfiguration(
    enableModelValidation: true,
    enableInputValidation: true,
    enableSecureStorage: true
)
```

## 🔧 Troubleshooting

### Common Issues

#### Model Loading Failed

```swift
// Check if model file exists
guard let modelURL = Bundle.main.url(forResource: "model_name", withExtension: "mlmodel") else {
    print("Model file not found")
    return
}

// Verify model compatibility
let model = try MLModel(contentsOf: modelURL)
print("Model loaded successfully")
```

#### Memory Issues

```swift
// Clear cache when memory is low
if getCurrentMemoryUsage() > 100 * 1024 * 1024 { // 100MB
    await aiEngine.clearCache()
}
```

#### Performance Issues

```swift
// Monitor performance and optimize
let metrics = aiEngine.getPerformanceMetrics()

if metrics.averageInferenceTime > 1.0 { // 1 second
    print("Inference is slow, consider optimization")
}

if metrics.memoryUsage > 50 * 1024 * 1024 { // 50MB
    print("High memory usage detected")
}
```

### Debug Mode

```swift
// Enable debug logging
#if DEBUG
print("Debug mode enabled")
print("Input: \(input)")
print("Model: \(model)")
print("Result: \(result)")
#endif
```

## 📚 Next Steps

1. **Read the [API Documentation](API.md)** for detailed API reference
2. **Explore [Architecture Guide](Architecture.md)** for system design
3. **Check [Performance Guide](Performance.md)** for optimization tips
4. **Review [Security Guide](Security.md)** for security best practices

## 🤝 Support

- **Documentation**: [Complete Documentation](Documentation/)
- **Issues**: [GitHub Issues](https://github.com/muhittincamdali/SwiftAI/issues)
- **Discussions**: [GitHub Discussions](https://github.com/muhittincamdali/SwiftAI/discussions)

---

**Happy coding with SwiftAI! 🚀** 