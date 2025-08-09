# 📚 API Reference

<!-- TOC START -->
## Table of Contents
- [📚 API Reference](#-api-reference)
- [📋 Table of Contents](#-table-of-contents)
- [🤖 AIEngine](#-aiengine)
  - [**Initialization**](#initialization)
  - [**Methods**](#methods)
    - [**process(_:type:)**](#processtype)
    - [**processBatch(_:type:)**](#processbatchtype)
    - [**getPerformanceMetrics()**](#getperformancemetrics)
    - [**clearCache()**](#clearcache)
- [🧠 ModelManager](#-modelmanager)
  - [**Methods**](#methods)
    - [**loadModel(name:)**](#loadmodelname)
    - [**validateModel(_:)**](#validatemodel)
    - [**optimizeModel(_:)**](#optimizemodel)
    - [**clearCache()**](#clearcache)
- [🔄 InferenceEngine](#-inferenceengine)
  - [**Methods**](#methods)
    - [**infer(input:model:)**](#inferinputmodel)
    - [**inferBatch(inputs:model:)**](#inferbatchinputsmodel)
- [📊 PerformanceMonitor](#-performancemonitor)
  - [**Methods**](#methods)
    - [**startMonitoring()**](#startmonitoring)
    - [**stopMonitoring()**](#stopmonitoring)
    - [**getMetrics()**](#getmetrics)
- [📝 Data Types](#-data-types)
  - [**AIInput**](#aiinput)
  - [**AIOutput**](#aioutput)
  - [**AIInputType**](#aiinputtype)
  - [**SentimentScore**](#sentimentscore)
  - [**DetectionResult**](#detectionresult)
  - [**PerformanceMetrics**](#performancemetrics)
- [❌ Error Handling](#-error-handling)
  - [**AIError**](#aierror)
- [🔧 Configuration](#-configuration)
  - [**Custom Configuration**](#custom-configuration)
- [📚 Next Steps](#-next-steps)
- [🤝 Support](#-support)
<!-- TOC END -->


Complete API documentation for SwiftAI framework.

## 📋 Table of Contents

- [AIEngine](#aiengine)
- [ModelManager](#modelmanager)
- [InferenceEngine](#inferenceengine)
- [PerformanceMonitor](#performancemonitor)
- [Data Types](#data-types)
- [Error Handling](#error-handling)

## 🤖 AIEngine

The main AI processing engine for SwiftAI.

### **Initialization**
```swift
let aiEngine = AIEngine()
```

### **Methods**

#### **process(_:type:)**
Processes a single AI input.

```swift
func process(_ input: AIInput, type: AIInputType) async throws -> AIOutput
```

**Parameters:**
- `input`: The AI input to process
- `type`: The type of AI processing to perform

**Returns:** AIOutput containing the processing result

**Example:**
```swift
let textInput = AIInput.text("Hello, how are you?")
let result = try await aiEngine.process(textInput, type: .text)
```

#### **processBatch(_:type:)**
Processes multiple AI inputs efficiently.

```swift
func processBatch(_ inputs: [AIInput], type: AIInputType) async throws -> [AIOutput]
```

**Parameters:**
- `inputs`: Array of AI inputs to process
- `type`: The type of AI processing to perform

**Returns:** Array of AIOutput containing processing results

**Example:**
```swift
let inputs = [
    AIInput.text("Positive review"),
    AIInput.text("Negative review"),
    AIInput.text("Neutral review")
]
let results = try await aiEngine.processBatch(inputs, type: .text)
```

#### **getPerformanceMetrics()**
Retrieves current performance metrics.

```swift
func getPerformanceMetrics() -> PerformanceMetrics
```

**Returns:** PerformanceMetrics containing current performance data

**Example:**
```swift
let metrics = aiEngine.getPerformanceMetrics()
print("Average inference time: \(metrics.averageInferenceTime)ms")
```

#### **clearCache()**
Clears the model cache.

```swift
func clearCache() async
```

**Example:**
```swift
await aiEngine.clearCache()
```

## 🧠 ModelManager

Manages loading, caching, and validating Core ML models.

### **Methods**

#### **loadModel(name:)**
Loads a model by name.

```swift
func loadModel(name: String) async throws -> MLModel
```

**Parameters:**
- `name`: The name of the model to load

**Returns:** Loaded MLModel

**Throws:** AIError.modelNotFound if model cannot be found

#### **validateModel(_:)**
Validates a loaded model.

```swift
func validateModel(_ model: MLModel) async throws -> Bool
```

**Parameters:**
- `model`: The model to validate

**Returns:** True if model is valid, false otherwise

#### **optimizeModel(_:)**
Optimizes a model for better performance.

```swift
func optimizeModel(_ model: MLModel) async throws -> MLModel
```

**Parameters:**
- `model`: The model to optimize

**Returns:** Optimized MLModel

#### **clearCache()**
Clears the model cache.

```swift
func clearCache() async
```

## 🔄 InferenceEngine

Handles the actual inference and prediction using loaded models.

### **Methods**

#### **infer(input:model:)**
Performs inference on a single input.

```swift
func infer(input: AIInput, model: MLModel) async throws -> AIOutput
```

**Parameters:**
- `input`: The input to process
- `model`: The model to use for inference

**Returns:** AIOutput containing inference result

#### **inferBatch(inputs:model:)**
Performs inference on multiple inputs.

```swift
func inferBatch(inputs: [AIInput], model: MLModel) async throws -> [AIOutput]
```

**Parameters:**
- `inputs`: Array of inputs to process
- `model`: The model to use for inference

**Returns:** Array of AIOutput containing inference results

## 📊 PerformanceMonitor

Monitors and tracks performance metrics.

### **Methods**

#### **startMonitoring()**
Starts performance monitoring.

```swift
func startMonitoring()
```

#### **stopMonitoring()**
Stops performance monitoring.

```swift
func stopMonitoring()
```

#### **getMetrics()**
Retrieves current performance metrics.

```swift
func getMetrics() -> PerformanceMetrics
```

**Returns:** PerformanceMetrics containing current metrics

## 📝 Data Types

### **AIInput**
Represents different types of AI input.

```swift
enum AIInput {
    case text(String)
    case image(UIImage)
    case audio(Data)
    case video(URL)
}
```

**Examples:**
```swift
let textInput = AIInput.text("Hello world")
let imageInput = AIInput.image(UIImage(named: "photo")!)
let audioInput = AIInput.audio(audioData)
let videoInput = AIInput.video(videoURL)
```

### **AIOutput**
Represents different types of AI output.

```swift
enum AIOutput {
    case classification([String: Double])
    case detection([DetectionResult])
    case generation(String)
    case translation(String)
    case sentiment(SentimentScore)
}
```

**Examples:**
```swift
// Classification output
let classification = AIOutput.classification([
    "positive": 0.8,
    "negative": 0.1,
    "neutral": 0.1
])

// Detection output
let detection = AIOutput.detection([
    DetectionResult(label: "person", confidence: 0.95, boundingBox: nil),
    DetectionResult(label: "car", confidence: 0.87, boundingBox: nil)
])

// Generation output
let generation = AIOutput.generation("Generated text content")

// Translation output
let translation = AIOutput.translation("Translated text")

// Sentiment output
let sentiment = AIOutput.sentiment(.positive(0.8))
```

### **AIInputType**
Defines the type of AI processing.

```swift
enum AIInputType {
    case text
    case image
    case audio
    case video
}
```

### **SentimentScore**
Represents sentiment analysis results.

```swift
enum SentimentScore {
    case positive(Double)
    case negative(Double)
    case neutral(Double)
}
```

### **DetectionResult**
Represents object detection results.

```swift
struct DetectionResult {
    let label: String
    let confidence: Double
    let boundingBox: CGRect?
}
```

### **PerformanceMetrics**
Contains performance monitoring data.

```swift
struct PerformanceMetrics {
    let averageInferenceTime: TimeInterval
    let memoryUsage: Int64
    let cacheHitRate: Double
    let modelLoadTime: TimeInterval
}
```

## ❌ Error Handling

### **AIError**
Defines possible AI processing errors.

```swift
enum AIError: Error {
    case modelNotFound
    case invalidInput
    case inferenceFailed
    case modelLoadFailed
    case optimizationFailed
}
```

**Error Handling Example:**
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

## 🔧 Configuration

### **Custom Configuration**
```swift
// Custom model manager
let customModelManager = CustomModelManager()
let aiEngine = AIEngine(modelManager: customModelManager)

// Custom inference engine
let customInferenceEngine = CustomInferenceEngine()
let aiEngine = AIEngine(inferenceEngine: customInferenceEngine)

// Custom performance monitor
let customPerformanceMonitor = CustomPerformanceMonitor()
let aiEngine = AIEngine(performanceMonitor: customPerformanceMonitor)
```

## 📚 Next Steps

1. **Read [Getting Started](GettingStarted.md)** for quick setup
2. **Explore [Architecture Guide](Architecture.md)** for system design
3. **Check [Performance Guide](Performance.md)** for optimization tips
4. **Review [Security Guide](Security.md)** for security best practices

## 🤝 Support

- **Documentation**: [Complete Documentation](Documentation/)
- **Issues**: [GitHub Issues](https://github.com/muhittincamdali/SwiftAI/issues)
- **Discussions**: [GitHub Discussions](https://github.com/muhittincamdali/SwiftAI/discussions)

---

**For more information, visit our [GitHub repository](https://github.com/muhittincamdali/SwiftAI).** 