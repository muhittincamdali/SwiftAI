# 🤖 AI API Reference

Complete API documentation for SwiftAI framework's AI processing capabilities.

## 📋 Table of Contents

- [AIEngine](#aiengine)
- [AIInput](#aiinput)
- [AIOutput](#aioutput)
- [AIModel](#aimodel)
- [AIResult](#airesult)
- [Error Handling](#error-handling)
- [Examples](#examples)

## 🚀 AIEngine

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

## 📝 AIInput

Represents different types of AI input.

### **Types**

```swift
enum AIInput {
    case text(String)
    case image(UIImage)
    case audio(Data)
    case video(URL)
    case document(Data)
    case sensor(SensorData)
    case multimodal([AIInput])
}
```

### **Properties**

- `type`: The type of input
- `size`: Size of the input in bytes
- `isValid`: Whether the input is valid

### **Methods**

#### **validate()**
Validates the input.

```swift
func validate() throws
```

#### **preprocess()**
Preprocesses the input.

```swift
func preprocess() throws -> AIInput
```

#### **extractFeatures()**
Extracts features from the input.

```swift
func extractFeatures() throws -> [String: Any]
```

### **Examples**

```swift
// Text input
let textInput = AIInput.text("Hello world")

// Image input
let imageInput = AIInput.image(UIImage(named: "photo")!)

// Audio input
let audioInput = AIInput.audio(audioData)

// Video input
let videoInput = AIInput.video(videoURL)

// Document input
let documentInput = AIInput.document(documentData)

// Sensor data input
let sensorInput = AIInput.sensor(sensorData)

// Multimodal input
let multimodalInput = AIInput.multimodal([textInput, imageInput])
```

## 📤 AIOutput

Represents different types of AI output.

### **Types**

```swift
enum AIOutput {
    case classification([String: Double])
    case detection([DetectionResult])
    case generation(String)
    case translation(String)
    case sentiment(SentimentScore)
}
```

### **Examples**

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

## 🧠 AIModel

Represents an AI model with metadata and configuration.

### **Properties**

- `id`: Unique identifier
- `name`: Model name
- `version`: Model version
- `type`: Model type (classification, detection, etc.)
- `inputType`: Expected input type
- `outputType`: Expected output type
- `size`: Model size in bytes
- `accuracy`: Model accuracy
- `metadata`: Model metadata
- `configuration`: Model configuration
- `performance`: Performance metrics

### **Methods**

#### **validate()**
Validates the model.

```swift
func validate() throws
```

#### **canProcess(_:)**
Checks if the model can process a given input.

```swift
func canProcess(_ input: AIInput) -> Bool
```

#### **estimateProcessingTime(for:)**
Estimates processing time for an input.

```swift
func estimateProcessingTime(for input: AIInput) -> TimeInterval
```

#### **estimateMemoryUsage(for:)**
Estimates memory usage for an input.

```swift
func estimateMemoryUsage(for input: AIInput) -> Int64
```

### **Examples**

```swift
let model = AIModel(
    name: "text_classifier",
    version: "1.0.0",
    type: .classification,
    inputType: .text,
    outputType: .classification,
    size: 50 * 1024 * 1024,
    accuracy: 0.85,
    metadata: modelMetadata,
    configuration: modelConfiguration,
    performance: modelPerformance
)
```

## 📊 AIResult

Represents a complete AI processing result.

### **Properties**

- `id`: Unique identifier
- `input`: Original input
- `output`: AI output
- `model`: Model used
- `processingTime`: Time taken for processing
- `memoryUsage`: Memory used during processing
- `confidence`: Confidence score
- `timestamp`: Processing timestamp
- `metadata`: Result metadata

### **Methods**

#### **validate()**
Validates the result.

```swift
func validate() throws
```

#### **isSuccessful**
Checks if processing was successful.

```swift
var isSuccessful: Bool
```

#### **isHighConfidence**
Checks if result has high confidence.

```swift
var isHighConfidence: Bool
```

#### **performanceScore**
Calculates performance score.

```swift
var performanceScore: Double
```

### **Examples**

```swift
let result = AIResult(
    input: AIInput.text("Hello world"),
    output: AIOutput.classification(["positive": 0.8, "negative": 0.2]),
    model: aiModel,
    processingTime: 0.1,
    memoryUsage: 50 * 1024 * 1024,
    confidence: 0.85,
    metadata: resultMetadata
)
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

### **Error Handling Example**
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

### **Model Configuration**
```swift
let config = ModelConfiguration(
    enableGPU: true,
    enableNeuralEngine: true,
    batchSize: 10,
    maxConcurrentRequests: 4,
    timeout: 30.0,
    memoryLimit: 100 * 1024 * 1024,
    quantization: .none,
    optimization: .none
)
```

### **Performance Configuration**
```swift
let perfConfig = PerformanceConfiguration(
    maxMemoryUsage: 100 * 1024 * 1024,
    inferenceTimeout: 10.0,
    enableMonitoring: true
)
```

## 📚 Examples

### **Text Classification**
```swift
let aiEngine = AIEngine()
let input = AIInput.text("I love this product!")
let result = try await aiEngine.process(input, type: .text)

switch result {
case .classification(let classifications):
    print("Classifications: \(classifications)")
default:
    break
}
```

### **Image Classification**
```swift
let aiEngine = AIEngine()
let input = AIInput.image(UIImage(named: "photo")!)
let result = try await aiEngine.process(input, type: .image)

switch result {
case .detection(let detections):
    for detection in detections {
        print("Detected: \(detection.label) with confidence: \(detection.confidence)")
    }
default:
    break
}
```

### **Batch Processing**
```swift
let aiEngine = AIEngine()
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

### **Performance Monitoring**
```swift
let aiEngine = AIEngine()
let result = try await aiEngine.process(input, type: .text)

let metrics = aiEngine.getPerformanceMetrics()
print("Average inference time: \(metrics.averageInferenceTime)ms")
print("Memory usage: \(metrics.memoryUsage) bytes")
print("Cache hit rate: \(metrics.cacheHitRate)")
```

## 🎯 Best Practices

1. **Always validate inputs** before processing
2. **Handle errors gracefully** with proper error handling
3. **Monitor performance** to ensure optimal operation
4. **Use batch processing** for multiple inputs
5. **Cache models** when possible for better performance
6. **Validate results** before using them
7. **Monitor memory usage** to prevent crashes
8. **Use appropriate input types** for your use case

## 📞 Support

For more information and support:
- [Documentation](Documentation/)
- [GitHub Issues](https://github.com/muhittincamdali/SwiftAI/issues)
- [GitHub Discussions](https://github.com/muhittincamdali/SwiftAI/discussions)
