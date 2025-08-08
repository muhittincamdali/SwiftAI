# 🎤 Speech Recognition Guide

## Overview

This comprehensive guide will help you integrate advanced speech recognition capabilities into your iOS applications using the SwiftAI framework. Learn how to implement speech-to-text, text-to-speech, voice commands, and emotion detection.

## Table of Contents

- [Getting Started](#getting-started)
- [Basic Speech Recognition](#basic-speech-recognition)
- [Advanced Features](#advanced-features)
- [Voice Commands](#voice-commands)
- [Text-to-Speech](#text-to-speech)
- [Emotion Detection](#emotion-detection)
- [Best Practices](#best-practices)
- [Troubleshooting](#troubleshooting)

## Getting Started

### Prerequisites

- iOS 15.0+ with Speech framework
- Microphone permission
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

Request microphone permission in your app:

```swift
import AVFoundation

class SpeechPermissionManager {
    func requestMicrophonePermission() {
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            DispatchQueue.main.async {
                if granted {
                    print("Microphone permission granted")
                } else {
                    print("Microphone permission denied")
                }
            }
        }
    }
}
```

## Basic Speech Recognition

### Simple Speech-to-Text

```swift
import SwiftAI

class BasicSpeechRecognition {
    private let speechManager = SpeechRecognitionManager()
    
    func setupSpeechRecognition() {
        // Configure speech recognition
        let config = SpeechRecognitionConfiguration()
        config.enableRealTimeRecognition = true
        config.enableLanguageDetection = true
        
        speechManager.configure(config)
    }
    
    func startSpeechRecognition() {
        let recognizer = SpeechToText(
            model: .whisper,
            language: "en-US",
            enablePunctuation: true
        )
        
        speechManager.startRealTimeRecognition(recognizer: recognizer) { result in
            switch result {
            case .success(let recognition):
                self.handleSpeechRecognition(recognition)
            case .failure(let error):
                self.handleError(error)
            }
        }
    }
    
    private func handleSpeechRecognition(_ recognition: RealTimeRecognitionResult) {
        print("Recognized text: \(recognition.text)")
        
        if recognition.isFinal {
            // Process final result
            processFinalText(recognition.text)
        }
    }
    
    private func processFinalText(_ text: String) {
        // Handle the final recognized text
        print("Final text: \(text)")
    }
    
    private func handleError(_ error: SpeechRecognitionError) {
        print("Speech recognition error: \(error)")
    }
}
```

### File-based Speech Recognition

```swift
class FileSpeechRecognition {
    private let speechManager = SpeechRecognitionManager()
    
    func recognizeSpeechFromFile(fileURL: URL) {
        guard let audioData = try? Data(contentsOf: fileURL) else {
            print("Failed to load audio file")
            return
        }
        
        let recognizer = SpeechToText(
            model: .whisper,
            language: "en-US"
        )
        
        speechManager.transcribeSpeech(
            audio: audioData,
            recognizer: recognizer
        ) { result in
            switch result {
            case .success(let transcription):
                print("Transcription: \(transcription.text)")
                print("Confidence: \(transcription.confidence)%")
                print("Duration: \(transcription.duration)s")
            case .failure(let error):
                print("Transcription failed: \(error)")
            }
        }
    }
}
```

## Advanced Features

### Multi-language Recognition

```swift
class MultiLanguageRecognition {
    private let speechManager = SpeechRecognitionManager()
    
    func setupMultiLanguageRecognition() {
        let recognizer = MultiLanguageRecognizer(
            languages: ["en-US", "es-ES", "fr-FR", "de-DE"],
            autoLanguageDetection: true
        )
        
        speechManager.recognizeMultiLanguage(
            recognizer: recognizer
        ) { result in
            switch result {
            case .success(let recognition):
                print("Detected language: \(recognition.language)")
                print("Translated text: \(recognition.translatedText)")
            case .failure(let error):
                print("Multi-language recognition failed: \(error)")
            }
        }
    }
}
```

### Speaker Recognition

```swift
class SpeakerRecognition {
    private let speechManager = SpeechRecognitionManager()
    private var speakerDatabase: SpeakerDatabase
    
    func setupSpeakerRecognition() {
        let recognizer = SpeakerRecognizer(
            model: .speakerNet,
            database: speakerDatabase,
            confidenceThreshold: 0.9
        )
        
        speechManager.recognizeSpeaker(
            recognizer: recognizer
        ) { result in
            switch result {
            case .success(let speaker):
                print("Recognized speaker: \(speaker.name)")
                print("Confidence: \(speaker.confidence)%")
            case .failure(let error):
                print("Speaker recognition failed: \(error)")
            }
        }
    }
    
    func addSpeaker(name: String, audioData: Data) {
        speakerDatabase.addSpeaker(
            name: name,
            audioData: audioData
        ) { result in
            switch result {
            case .success(let speaker):
                print("Speaker added: \(speaker.name)")
            case .failure(let error):
                print("Failed to add speaker: \(error)")
            }
        }
    }
}
```

## Voice Commands

### Basic Voice Commands

```swift
class VoiceCommandHandler {
    private let speechManager = SpeechRecognitionManager()
    
    func setupVoiceCommands() {
        let recognizer = VoiceCommandRecognizer(
            commands: ["play", "pause", "stop", "next", "previous"],
            language: "en-US",
            confidenceThreshold: 0.8
        )
        
        recognizer.setCommandHandler { command in
            self.handleVoiceCommand(command)
        }
        
        speechManager.recognizeVoiceCommand(
            recognizer: recognizer
        ) { result in
            switch result {
            case .success(let command):
                print("Voice command: \(command.text)")
            case .failure(let error):
                print("Voice command recognition failed: \(error)")
            }
        }
    }
    
    private func handleVoiceCommand(_ command: VoiceCommand) {
        switch command.action {
        case "play":
            playMedia()
        case "pause":
            pauseMedia()
        case "stop":
            stopMedia()
        case "next":
            nextTrack()
        case "previous":
            previousTrack()
        default:
            print("Unknown command: \(command.text)")
        }
    }
    
    private func playMedia() {
        print("Playing media...")
        // Implement media playback
    }
    
    private func pauseMedia() {
        print("Pausing media...")
        // Implement media pause
    }
    
    private func stopMedia() {
        print("Stopping media...")
        // Implement media stop
    }
    
    private func nextTrack() {
        print("Next track...")
        // Implement next track
    }
    
    private func previousTrack() {
        print("Previous track...")
        // Implement previous track
    }
}
```

### Advanced Voice Commands

```swift
class AdvancedVoiceCommands {
    private let speechManager = SpeechRecognitionManager()
    
    func setupAdvancedCommands() {
        let commands = [
            "turn on lights",
            "turn off lights",
            "set temperature to [number] degrees",
            "play [artist] [song]",
            "call [contact]",
            "send message to [contact]",
            "set alarm for [time]",
            "remind me to [task] at [time]"
        ]
        
        let recognizer = VoiceCommandRecognizer(
            commands: commands,
            language: "en-US",
            confidenceThreshold: 0.85
        )
        
        recognizer.setCommandHandler { command in
            self.handleAdvancedCommand(command)
        }
    }
    
    private func handleAdvancedCommand(_ command: VoiceCommand) {
        let text = command.text.lowercased()
        
        if text.contains("turn on lights") {
            turnOnLights()
        } else if text.contains("turn off lights") {
            turnOffLights()
        } else if text.contains("set temperature") {
            handleTemperatureCommand(command)
        } else if text.contains("play") {
            handleMusicCommand(command)
        } else if text.contains("call") {
            handleCallCommand(command)
        } else if text.contains("send message") {
            handleMessageCommand(command)
        } else if text.contains("set alarm") {
            handleAlarmCommand(command)
        } else if text.contains("remind me") {
            handleReminderCommand(command)
        }
    }
    
    private func handleTemperatureCommand(_ command: VoiceCommand) {
        // Extract temperature value from command
        let text = command.text
        if let temperature = extractNumber(from: text) {
            setTemperature(temperature)
        }
    }
    
    private func extractNumber(from text: String) -> Int? {
        // Extract number from text using regex
        let pattern = "\\d+"
        let regex = try? NSRegularExpression(pattern: pattern)
        let range = NSRange(text.startIndex..., in: text)
        
        if let match = regex?.firstMatch(in: text, range: range) {
            let numberString = String(text[Range(match.range, in: text)!])
            return Int(numberString)
        }
        
        return nil
    }
}
```

## Text-to-Speech

### Basic Text-to-Speech

```swift
class TextToSpeechHandler {
    private let speechManager = SpeechRecognitionManager()
    
    func speakText(_ text: String) {
        let synthesizer = TextToSpeech(
            voice: "en-US-Neural2-F",
            rate: 1.0,
            pitch: 1.0,
            volume: 1.0
        )
        
        speechManager.synthesizeSpeech(
            text: text,
            synthesizer: synthesizer
        ) { result in
            switch result {
            case .success(let synthesis):
                self.playAudio(synthesis.audioData)
            case .failure(let error):
                print("Speech synthesis failed: \(error)")
            }
        }
    }
    
    private func playAudio(_ audioData: Data) {
        // Implement audio playback
        print("Playing synthesized speech...")
    }
}
```

### Advanced Text-to-Speech

```swift
class AdvancedTextToSpeech {
    private let speechManager = SpeechRecognitionManager()
    
    func speakWithEmotion(_ text: String, emotion: Emotion) {
        let synthesizer = TextToSpeech(
            voice: "en-US-Neural2-F",
            rate: getRateForEmotion(emotion),
            pitch: getPitchForEmotion(emotion),
            volume: 1.0
        )
        
        let ssmlText = createSSMLWithEmotion(text, emotion: emotion)
        
        speechManager.synthesizeSSML(
            ssml: ssmlText,
            synthesizer: synthesizer
        ) { result in
            switch result {
            case .success(let synthesis):
                self.playAudio(synthesis.audioData)
            case .failure(let error):
                print("SSML synthesis failed: \(error)")
            }
        }
    }
    
    private func getRateForEmotion(_ emotion: Emotion) -> Float {
        switch emotion {
        case .excited: return 1.2
        case .sad: return 0.8
        case .angry: return 1.1
        default: return 1.0
        }
    }
    
    private func getPitchForEmotion(_ emotion: Emotion) -> Float {
        switch emotion {
        case .excited: return 1.2
        case .sad: return 0.9
        case .angry: return 1.1
        default: return 1.0
        }
    }
    
    private func createSSMLWithEmotion(_ text: String, emotion: Emotion) -> String {
        let prosodyAttributes = getProsodyAttributes(for: emotion)
        
        return """
        <speak>
            <prosody rate="\(prosodyAttributes.rate)" pitch="\(prosodyAttributes.pitch)">
                \(text)
            </prosody>
        </speak>
        """
    }
    
    private func getProsodyAttributes(for emotion: Emotion) -> (rate: String, pitch: String) {
        switch emotion {
        case .excited:
            return (rate: "fast", pitch: "high")
        case .sad:
            return (rate: "slow", pitch: "low")
        case .angry:
            return (rate: "medium", pitch: "high")
        default:
            return (rate: "medium", pitch: "medium")
        }
    }
}
```

## Emotion Detection

### Basic Emotion Detection

```swift
class EmotionDetection {
    private let speechManager = SpeechRecognitionManager()
    
    func setupEmotionDetection() {
        let detector = EmotionDetector(
            emotions: ["happy", "sad", "angry", "neutral", "excited"],
            model: .emotionNet,
            confidenceThreshold: 0.7
        )
        
        speechManager.startEmotionMonitoring(
            detector: detector
        ) { result in
            switch result {
            case .success(let emotion):
                self.handleEmotion(emotion)
            case .failure(let error):
                print("Emotion detection failed: \(error)")
            }
        }
    }
    
    private func handleEmotion(_ emotion: EmotionResult) {
        print("Detected emotion: \(emotion.primaryEmotion)")
        print("Confidence: \(emotion.confidence)%")
        print("Intensity: \(emotion.intensity)")
        
        // Adjust app behavior based on emotion
        adjustAppBehavior(for: emotion.primaryEmotion)
    }
    
    private func adjustAppBehavior(for emotion: String) {
        switch emotion {
        case "happy":
            // Brighten UI, play cheerful sounds
            print("User is happy - brightening UI")
        case "sad":
            // Dim UI, play calming sounds
            print("User is sad - dimming UI")
        case "angry":
            // Reduce UI complexity, play soothing sounds
            print("User is angry - simplifying UI")
        case "excited":
            // Increase UI responsiveness, play energetic sounds
            print("User is excited - increasing responsiveness")
        default:
            // Default behavior
            print("User is neutral - default behavior")
        }
    }
}
```

## Best Practices

### Performance Optimization

1. **Use Real-time Recognition**: For interactive applications
2. **Optimize Audio Quality**: Ensure clear audio input
3. **Implement Caching**: Cache frequently used models
4. **Handle Background Processing**: Manage audio sessions properly
5. **Monitor Battery Usage**: Optimize for battery life

### User Experience

1. **Provide Visual Feedback**: Show recognition status
2. **Handle Errors Gracefully**: Inform users of issues
3. **Support Multiple Languages**: Cater to diverse users
4. **Implement Fallbacks**: Provide alternative input methods
5. **Respect Privacy**: Handle audio data securely

### Security Considerations

1. **Secure Audio Storage**: Encrypt sensitive audio data
2. **Permission Management**: Request only necessary permissions
3. **Data Minimization**: Only process required audio
4. **User Consent**: Get explicit consent for voice features
5. **Regular Updates**: Keep models and frameworks updated

## Troubleshooting

### Common Issues

**Issue**: Speech recognition not working
**Solution**: Check microphone permissions and audio session configuration

**Issue**: Poor recognition accuracy
**Solution**: Improve audio quality and reduce background noise

**Issue**: High battery usage
**Solution**: Optimize processing frequency and use efficient models

**Issue**: App crashes during speech recognition
**Solution**: Handle audio session interruptions and memory management

### Debug Tips

```swift
class SpeechDebugger {
    func debugSpeechRecognition() {
        // Enable debug logging
        SpeechRecognitionManager.enableDebugLogging = true
        
        // Monitor performance
        let performanceMonitor = PerformanceMonitor()
        performanceMonitor.trackInferenceTime { result in
            switch result {
            case .success(let metrics):
                print("Average inference time: \(metrics.averageTime)ms")
            case .failure(let error):
                print("Performance tracking failed: \(error)")
            }
        }
    }
}
```

This comprehensive guide provides everything you need to implement advanced speech recognition features in your iOS applications using the SwiftAI framework.
