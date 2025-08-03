import Foundation
import UIKit
import CoreML
import Vision
import NaturalLanguage

// MARK: - AI Input Entity
public enum AIInput: Equatable, Hashable {
    case text(String)
    case image(UIImage)
    case audio(Data)
    case video(URL)
    case document(Data)
    case sensor(SensorData)
    case multimodal([AIInput])
    
    // MARK: - Properties
    public var type: AIInputType {
        switch self {
        case .text:
            return .text
        case .image:
            return .image
        case .audio:
            return .audio
        case .video:
            return .video
        case .document:
            return .document
        case .sensor:
            return .sensor
        case .multimodal:
            return .multimodal
        }
    }
    
    public var size: Int64 {
        switch self {
        case .text(let text):
            return Int64(text.utf8.count)
        case .image(let image):
            return Int64(image.jpegData(compressionQuality: 0.8)?.count ?? 0)
        case .audio(let data):
            return Int64(data.count)
        case .video(let url):
            return (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
        case .document(let data):
            return Int64(data.count)
        case .sensor(let sensorData):
            return sensorData.size
        case .multimodal(let inputs):
            return inputs.reduce(0) { $0 + $1.size }
        }
    }
    
    public var isValid: Bool {
        switch self {
        case .text(let text):
            return !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .image(let image):
            return image.size.width > 0 && image.size.height > 0
        case .audio(let data):
            return data.count > 0
        case .video(let url):
            return FileManager.default.fileExists(atPath: url.path)
        case .document(let data):
            return data.count > 0
        case .sensor(let sensorData):
            return sensorData.isValid
        case .multimodal(let inputs):
            return !inputs.isEmpty && inputs.allSatisfy { $0.isValid }
        }
    }
    
    // MARK: - Validation
    public func validate() throws {
        guard isValid else {
            throw AIInputError.invalidInput
        }
        
        switch self {
        case .text(let text):
            try validateText(text)
        case .image(let image):
            try validateImage(image)
        case .audio(let data):
            try validateAudio(data)
        case .video(let url):
            try validateVideo(url)
        case .document(let data):
            try validateDocument(data)
        case .sensor(let sensorData):
            try validateSensorData(sensorData)
        case .multimodal(let inputs):
            try validateMultimodalInputs(inputs)
        }
    }
    
    // MARK: - Preprocessing
    public func preprocess() throws -> AIInput {
        switch self {
        case .text(let text):
            return .text(preprocessText(text))
        case .image(let image):
            return .image(try preprocessImage(image))
        case .audio(let data):
            return .audio(try preprocessAudio(data))
        case .video(let url):
            return .video(try preprocessVideo(url))
        case .document(let data):
            return .document(try preprocessDocument(data))
        case .sensor(let sensorData):
            return .sensor(try preprocessSensorData(sensorData))
        case .multimodal(let inputs):
            return .multimodal(try preprocessMultimodalInputs(inputs))
        }
    }
    
    // MARK: - Feature Extraction
    public func extractFeatures() throws -> [String: Any] {
        switch self {
        case .text(let text):
            return try extractTextFeatures(text)
        case .image(let image):
            return try extractImageFeatures(image)
        case .audio(let data):
            return try extractAudioFeatures(data)
        case .video(let url):
            return try extractVideoFeatures(url)
        case .document(let data):
            return try extractDocumentFeatures(data)
        case .sensor(let sensorData):
            return try extractSensorFeatures(sensorData)
        case .multimodal(let inputs):
            return try extractMultimodalFeatures(inputs)
        }
    }
    
    // MARK: - Private Validation Methods
    private func validateText(_ text: String) throws {
        guard text.count <= 10000 else {
            throw AIInputError.textTooLong
        }
        
        guard !containsMaliciousContent(text) else {
            throw AIInputError.maliciousContent
        }
    }
    
    private func validateImage(_ image: UIImage) throws {
        guard image.size.width <= 4096 && image.size.height <= 4096 else {
            throw AIInputError.imageTooLarge
        }
        
        guard image.size.width >= 32 && image.size.height >= 32 else {
            throw AIInputError.imageTooSmall
        }
    }
    
    private func validateAudio(_ data: Data) throws {
        guard data.count <= 50 * 1024 * 1024 else { // 50MB
            throw AIInputError.audioTooLarge
        }
        
        guard data.count > 1024 else { // 1KB minimum
            throw AIInputError.audioTooSmall
        }
    }
    
    private func validateVideo(_ url: URL) throws {
        let fileSize = (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
        guard fileSize <= 100 * 1024 * 1024 else { // 100MB
            throw AIInputError.videoTooLarge
        }
        
        guard fileSize > 1024 else { // 1KB minimum
            throw AIInputError.videoTooSmall
        }
    }
    
    private func validateDocument(_ data: Data) throws {
        guard data.count <= 10 * 1024 * 1024 else { // 10MB
            throw AIInputError.documentTooLarge
        }
        
        guard data.count > 100 else { // 100 bytes minimum
            throw AIInputError.documentTooSmall
        }
    }
    
    private func validateSensorData(_ sensorData: SensorData) throws {
        guard sensorData.isValid else {
            throw AIInputError.invalidSensorData
        }
    }
    
    private func validateMultimodalInputs(_ inputs: [AIInput]) throws {
        guard inputs.count <= 10 else {
            throw AIInputError.tooManyInputs
        }
        
        for input in inputs {
            try input.validate()
        }
    }
    
    // MARK: - Private Preprocessing Methods
    private func preprocessText(_ text: String) -> String {
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "\t", with: " ")
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
    }
    
    private func preprocessImage(_ image: UIImage) throws -> UIImage {
        // Resize if too large
        let maxSize: CGFloat = 1024
        if image.size.width > maxSize || image.size.height > maxSize {
            let scale = min(maxSize / image.size.width, maxSize / image.size.height)
            let newSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
            
            UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
            image.draw(in: CGRect(origin: .zero, size: newSize))
            let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            
            guard let resizedImage = resizedImage else {
                throw AIInputError.imageProcessingFailed
            }
            
            return resizedImage
        }
        
        return image
    }
    
    private func preprocessAudio(_ data: Data) throws -> Data {
        // Basic audio preprocessing
        return data
    }
    
    private func preprocessVideo(_ url: URL) throws -> URL {
        // Basic video preprocessing
        return url
    }
    
    private func preprocessDocument(_ data: Data) throws -> Data {
        // Basic document preprocessing
        return data
    }
    
    private func preprocessSensorData(_ sensorData: SensorData) throws -> SensorData {
        // Basic sensor data preprocessing
        return sensorData
    }
    
    private func preprocessMultimodalInputs(_ inputs: [AIInput]) throws -> [AIInput] {
        return try inputs.map { try $0.preprocess() }
    }
    
    // MARK: - Private Feature Extraction Methods
    private func extractTextFeatures(_ text: String) throws -> [String: Any] {
        let tokenizer = NLTokenizer(unit: .word)
        tokenizer.string = text
        
        let tokens = tokenizer.tokens(for: text.startIndex..<text.endIndex)
        let wordCount = tokens.count
        let characterCount = text.count
        let averageWordLength = wordCount > 0 ? Double(characterCount) / Double(wordCount) : 0.0
        
        return [
            "wordCount": wordCount,
            "characterCount": characterCount,
            "averageWordLength": averageWordLength,
            "text": text
        ]
    }
    
    private func extractImageFeatures(_ image: UIImage) throws -> [String: Any] {
        guard let cgImage = image.cgImage else {
            throw AIInputError.imageProcessingFailed
        }
        
        return [
            "width": cgImage.width,
            "height": cgImage.height,
            "colorSpace": cgImage.colorSpace?.name ?? "unknown",
            "bitsPerComponent": cgImage.bitsPerComponent,
            "bitsPerPixel": cgImage.bitsPerPixel
        ]
    }
    
    private func extractAudioFeatures(_ data: Data) throws -> [String: Any] {
        return [
            "size": data.count,
            "duration": estimateAudioDuration(data),
            "format": detectAudioFormat(data)
        ]
    }
    
    private func extractVideoFeatures(_ url: URL) throws -> [String: Any] {
        let fileSize = (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
        return [
            "fileSize": fileSize,
            "path": url.path,
            "extension": url.pathExtension
        ]
    }
    
    private func extractDocumentFeatures(_ data: Data) throws -> [String: Any] {
        return [
            "size": data.count,
            "format": detectDocumentFormat(data),
            "hasText": detectTextContent(data)
        ]
    }
    
    private func extractSensorFeatures(_ sensorData: SensorData) throws -> [String: Any] {
        return [
            "type": sensorData.type.rawValue,
            "timestamp": sensorData.timestamp,
            "values": sensorData.values,
            "accuracy": sensorData.accuracy
        ]
    }
    
    private func extractMultimodalFeatures(_ inputs: [AIInput]) throws -> [String: Any] {
        var features: [String: Any] = [:]
        
        for (index, input) in inputs.enumerated() {
            let inputFeatures = try input.extractFeatures()
            features["input_\(index)"] = inputFeatures
        }
        
        return features
    }
    
    // MARK: - Helper Methods
    private func containsMaliciousContent(_ text: String) -> Bool {
        let maliciousPatterns = [
            "javascript:",
            "<script>",
            "SELECT *",
            "DROP TABLE",
            "UNION SELECT",
            "eval(",
            "document.cookie"
        ]
        
        let lowercasedText = text.lowercased()
        return maliciousPatterns.contains { pattern in
            lowercasedText.contains(pattern.lowercased())
        }
    }
    
    private func estimateAudioDuration(_ data: Data) -> TimeInterval {
        return TimeInterval(data.count / 16000) // Assuming 16kHz, 16-bit audio
    }
    
    private func detectAudioFormat(_ data: Data) -> String {
        if data.count >= 4 {
            let header = data.prefix(4)
            if header.starts(with: [0x52, 0x49, 0x46, 0x46]) {
                return "WAV"
            } else if header.starts(with: [0xFF, 0xFB]) || header.starts(with: [0xFF, 0xF3]) {
                return "MP3"
            }
        }
        return "unknown"
    }
    
    private func detectDocumentFormat(_ data: Data) -> String {
        if data.count >= 4 {
            let header = data.prefix(4)
            if header.starts(with: [0x25, 0x50, 0x44, 0x46]) {
                return "PDF"
            } else if header.starts(with: [0x50, 0x4B, 0x03, 0x04]) {
                return "DOCX"
            }
        }
        return "unknown"
    }
    
    private func detectTextContent(_ data: Data) -> Bool {
        guard let string = String(data: data, encoding: .utf8) else {
            return false
        }
        
        let textCharacters = CharacterSet.letters.union(.decimalDigits).union(.whitespaces)
        let nonTextCharacters = CharacterSet(charactersIn: string).subtracting(textCharacters)
        
        return Double(nonTextCharacters.count) / Double(string.count) < 0.3
    }
}

// MARK: - Sensor Data
public struct SensorData: Equatable, Hashable {
    public enum SensorType: String, CaseIterable {
        case accelerometer
        case gyroscope
        case magnetometer
        case barometer
        case proximity
        case ambientLight
        case temperature
        case humidity
    }
    
    public let type: SensorType
    public let timestamp: Date
    public let values: [Double]
    public let accuracy: Double
    
    public var size: Int64 {
        return Int64(MemoryLayout<SensorData>.size)
    }
    
    public var isValid: Bool {
        return !values.isEmpty && accuracy >= 0.0 && accuracy <= 1.0
    }
    
    public init(type: SensorType, timestamp: Date, values: [Double], accuracy: Double) {
        self.type = type
        self.timestamp = timestamp
        self.values = values
        self.accuracy = accuracy
    }
}

// MARK: - Error Types
public enum AIInputError: Error {
    case invalidInput
    case textTooLong
    case textTooShort
    case imageTooLarge
    case imageTooSmall
    case audioTooLarge
    case audioTooSmall
    case videoTooLarge
    case videoTooSmall
    case documentTooLarge
    case documentTooSmall
    case maliciousContent
    case invalidSensorData
    case tooManyInputs
    case imageProcessingFailed
    case audioProcessingFailed
    case videoProcessingFailed
    case documentProcessingFailed
    case featureExtractionFailed
}
