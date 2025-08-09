# 👁️ Computer Vision Guide

<!-- TOC START -->
## Table of Contents
- [👁️ Computer Vision Guide](#-computer-vision-guide)
- [Overview](#overview)
- [Table of Contents](#table-of-contents)
- [Getting Started](#getting-started)
  - [Prerequisites](#prerequisites)
  - [Installation](#installation)
  - [Permission Setup](#permission-setup)
- [Image Classification](#image-classification)
  - [Basic Image Classification](#basic-image-classification)
  - [Custom Image Classification](#custom-image-classification)
- [Object Detection](#object-detection)
  - [Basic Object Detection](#basic-object-detection)
  - [Real-time Object Detection](#real-time-object-detection)
- [Face Recognition](#face-recognition)
  - [Basic Face Recognition](#basic-face-recognition)
  - [Face Database Management](#face-database-management)
- [Image Segmentation](#image-segmentation)
  - [Basic Image Segmentation](#basic-image-segmentation)
- [Real-time Processing](#real-time-processing)
  - [Camera Integration](#camera-integration)
- [Best Practices](#best-practices)
  - [Performance Optimization](#performance-optimization)
  - [Accuracy Improvement](#accuracy-improvement)
  - [User Experience](#user-experience)
- [Troubleshooting](#troubleshooting)
  - [Common Issues](#common-issues)
  - [Debug Tips](#debug-tips)
<!-- TOC END -->


## Overview

This comprehensive guide will help you integrate advanced computer vision capabilities into your iOS applications using the SwiftAI framework. Learn how to implement image classification, object detection, face recognition, and more.

## Table of Contents

- [Getting Started](#getting-started)
- [Image Classification](#image-classification)
- [Object Detection](#object-detection)
- [Face Recognition](#face-recognition)
- [Image Segmentation](#image-segmentation)
- [Real-time Processing](#real-time-processing)
- [Best Practices](#best-practices)
- [Troubleshooting](#troubleshooting)

## Getting Started

### Prerequisites

- iOS 15.0+ with Vision framework
- Camera permission
- SwiftAI framework installed
- Basic understanding of Swift and iOS development

### Installation

Add SwiftAI to your project:

```swift
// Package.swift
dependencies: [
    .package(url: "https://github.com/muhittincamdali/SwiftAI.git", from: "1.0.0")
]
```

### Permission Setup

Request camera permission in your app:

```swift
import AVFoundation

class CameraPermissionManager {
    func requestCameraPermission() {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            DispatchQueue.main.async {
                if granted {
                    print("Camera permission granted")
                } else {
                    print("Camera permission denied")
                }
            }
        }
    }
}
```

## Image Classification

### Basic Image Classification

```swift
import SwiftAI

class ImageClassification {
    private let visionManager = ComputerVisionManager()
    
    func setupImageClassification() {
        let config = ComputerVisionConfiguration()
        config.enableImageClassification = true
        
        visionManager.configure(config)
    }
    
    func classifyImage(_ image: UIImage) {
        let classifier = ImageClassifier(
            model: .resnet50,
            categories: ["cat", "dog", "car", "person", "building"]
        )
        
        visionManager.classifyImage(
            image: image,
            classifier: classifier
        ) { result in
            switch result {
            case .success(let classification):
                self.handleClassification(classification)
            case .failure(let error):
                self.handleError(error)
            }
        }
    }
    
    private func handleClassification(_ classification: ImageClassificationResult) {
        print("Top prediction: \(classification.topPrediction)")
        print("Confidence: \(classification.confidence)%")
        
        // Update UI with results
        DispatchQueue.main.async {
            self.updateUI(with: classification)
        }
    }
}
```

### Custom Image Classification

```swift
class CustomImageClassification {
    private let visionManager = ComputerVisionManager()
    
    func setupCustomClassifier() {
        let customCategories = [
            "product_a",
            "product_b",
            "product_c",
            "defective",
            "normal"
        ]
        
        let classifier = ImageClassifier(
            model: .custom,
            categories: customCategories,
            confidenceThreshold: 0.8
        )
        
        // Train custom classifier
        let trainingData = loadTrainingData()
        classifier.train(with: trainingData) { result in
            switch result {
            case .success(let trainingResult):
                print("Custom classifier trained successfully")
                print("Accuracy: \(trainingResult.accuracy)%")
            case .failure(let error):
                print("Training failed: \(error)")
            }
        }
    }
}
```

## Object Detection

### Basic Object Detection

```swift
class ObjectDetection {
    private let visionManager = ComputerVisionManager()
    
    func setupObjectDetection() {
        let config = ComputerVisionConfiguration()
        config.enableObjectDetection = true
        
        visionManager.configure(config)
    }
    
    func detectObjects(in image: UIImage) {
        let detector = ObjectDetector(
            model: .yolo,
            confidence: 0.5,
            nmsThreshold: 0.4
        )
        
        visionManager.detectObjects(
            image: image,
            detector: detector
        ) { result in
            switch result {
            case .success(let detections):
                self.handleDetections(detections)
            case .failure(let error):
                self.handleError(error)
            }
        }
    }
    
    private func handleDetections(_ detections: [ObjectDetection]) {
        print("Objects detected: \(detections.count)")
        
        for detection in detections {
            print("Object: \(detection.label)")
            print("Confidence: \(detection.confidence)%")
            print("Bounding box: \(detection.boundingBox)")
        }
        
        // Update UI with detection results
        DispatchQueue.main.async {
            self.updateUI(with: detections)
        }
    }
}
```

### Real-time Object Detection

```swift
class RealTimeObjectDetection {
    private let visionManager = ComputerVisionManager()
    
    func startRealTimeDetection() {
        let detector = ObjectDetector(
            model: .yolo,
            confidence: 0.6,
            nmsThreshold: 0.3
        )
        
        visionManager.startRealTimeDetection(
            detector: detector
        ) { result in
            switch result {
            case .success(let detections):
                self.updateRealTimeUI(with: detections)
            case .failure(let error):
                print("Real-time detection failed: \(error)")
            }
        }
    }
    
    private func updateRealTimeUI(with detections: [ObjectDetection]) {
        DispatchQueue.main.async {
            // Update UI with real-time detections
            self.drawBoundingBoxes(detections)
        }
    }
}
```

## Face Recognition

### Basic Face Recognition

```swift
class FaceRecognition {
    private let visionManager = ComputerVisionManager()
    private var faceDatabase: FaceDatabase
    
    func setupFaceRecognition() {
        let config = ComputerVisionConfiguration()
        config.enableFaceRecognition = true
        
        visionManager.configure(config)
    }
    
    func recognizeFaces(in image: UIImage) {
        let recognizer = FaceRecognizer(
            model: .facenet,
            database: faceDatabase
        )
        
        visionManager.recognizeFaces(
            image: image,
            recognizer: recognizer
        ) { result in
            switch result {
            case .success(let recognitions):
                self.handleFaceRecognitions(recognitions)
            case .failure(let error):
                self.handleError(error)
            }
        }
    }
    
    private func handleFaceRecognitions(_ recognitions: [FaceRecognition]) {
        print("Faces detected: \(recognitions.count)")
        
        for recognition in recognitions {
            print("Person: \(recognition.person)")
            print("Confidence: \(recognition.confidence)%")
            print("Face location: \(recognition.location)")
        }
    }
}
```

### Face Database Management

```swift
class FaceDatabaseManager {
    private var faceDatabase: FaceDatabase
    
    func addPerson(name: String, faceImages: [UIImage]) {
        faceDatabase.addPerson(
            name: name,
            faceImages: faceImages
        ) { result in
            switch result {
            case .success(let person):
                print("Person added: \(person.name)")
                print("Face embeddings: \(person.faceEmbeddings.count)")
            case .failure(let error):
                print("Failed to add person: \(error)")
            }
        }
    }
    
    func removePerson(name: String) {
        faceDatabase.removePerson(name: name) { success in
            if success {
                print("Person removed: \(name)")
            } else {
                print("Failed to remove person: \(name)")
            }
        }
    }
}
```

## Image Segmentation

### Basic Image Segmentation

```swift
class ImageSegmentation {
    private let visionManager = ComputerVisionManager()
    
    func setupImageSegmentation() {
        let config = ComputerVisionConfiguration()
        config.enableImageSegmentation = true
        
        visionManager.configure(config)
    }
    
    func segmentImage(_ image: UIImage) {
        let segmenter = ImageSegmenter(
            model: .deeplab,
            numClasses: 21
        )
        
        visionManager.segmentImage(
            image: image,
            segmenter: segmenter
        ) { result in
            switch result {
            case .success(let segmentation):
                self.handleSegmentation(segmentation)
            case .failure(let error):
                self.handleError(error)
            }
        }
    }
    
    private func handleSegmentation(_ segmentation: ImageSegmentationResult) {
        print("Segments: \(segmentation.segments.count)")
        print("Mask size: \(segmentation.maskSize)")
        print("Classes detected: \(segmentation.classes)")
        
        // Apply segmentation mask to image
        let maskedImage = applySegmentationMask(
            to: inputImage,
            mask: segmentation.mask
        )
        
        DispatchQueue.main.async {
            self.updateUI(with: maskedImage)
        }
    }
}
```

## Real-time Processing

### Camera Integration

```swift
import AVFoundation

class CameraVisionProcessor {
    private let captureSession = AVCaptureSession()
    private let visionManager = ComputerVisionManager()
    
    func setupCamera() {
        guard let camera = AVCaptureDevice.default(for: .video) else {
            print("Camera not available")
            return
        }
        
        do {
            let input = try AVCaptureDeviceInput(device: camera)
            let output = AVCaptureVideoDataOutput()
            
            captureSession.addInput(input)
            captureSession.addOutput(output)
            
            output.setSampleBufferDelegate(self, queue: DispatchQueue.global(qos: .userInteractive))
            
            captureSession.startRunning()
        } catch {
            print("Camera setup failed: \(error)")
        }
    }
}

extension CameraVisionProcessor: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        let image = UIImage(ciImage: CIImage(cvImageBuffer: imageBuffer))
        
        // Process image with computer vision
        processImage(image)
    }
    
    private func processImage(_ image: UIImage) {
        // Perform real-time analysis
        classifyImage(image)
        detectObjects(in: image)
    }
}
```

## Best Practices

### Performance Optimization

1. **Model Selection**: Choose appropriate models for your use case
2. **Image Preprocessing**: Optimize images before processing
3. **Batch Processing**: Process multiple images together
4. **Memory Management**: Release unused model resources
5. **GPU Utilization**: Use GPU acceleration when available

### Accuracy Improvement

1. **Image Quality**: Ensure high-quality input images
2. **Data Augmentation**: Use techniques to increase training data
3. **Model Fine-tuning**: Adapt models to your specific domain
4. **Ensemble Methods**: Combine multiple models for better accuracy

### User Experience

1. **Loading Indicators**: Show progress during processing
2. **Error Handling**: Provide meaningful error messages
3. **Real-time Feedback**: Update UI in real-time
4. **Privacy Protection**: Handle sensitive image data securely

## Troubleshooting

### Common Issues

**Issue**: Camera not working
**Solution**: Check camera permissions and device availability

**Issue**: Poor detection accuracy
**Solution**: Improve image quality and lighting conditions

**Issue**: High memory usage
**Solution**: Optimize image processing and release resources

**Issue**: Slow processing
**Solution**: Use GPU acceleration and optimize models

### Debug Tips

```swift
class VisionDebugger {
    func debugVisionProcessing() {
        // Enable debug logging
        ComputerVisionManager.enableDebugLogging = true
        
        // Monitor performance
        let performanceMonitor = PerformanceMonitor()
        performanceMonitor.trackVisionPerformance { result in
            switch result {
            case .success(let metrics):
                print("Vision processing time: \(metrics.processingTime)ms")
                print("Memory usage: \(metrics.memoryUsage)MB")
            case .failure(let error):
                print("Performance monitoring failed: \(error)")
            }
        }
    }
}
```

This comprehensive guide provides everything you need to implement advanced computer vision features in your iOS applications using the SwiftAI framework.
