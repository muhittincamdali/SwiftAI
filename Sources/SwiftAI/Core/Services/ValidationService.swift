//
//  ValidationService.swift
//  SwiftAI
//
//  Created by Muhittin Camdali on 17/08/2024.
//

import Foundation

/// Enterprise-grade validation service for AI configuration and data validation
public final class ValidationService: ValidationServiceProtocol {
    
    // MARK: - Private Properties
    
    private let logger: LoggerProtocol
    private let deviceInfo: DeviceInfoProtocol
    
    // MARK: - Initialization
    
    public init(
        logger: LoggerProtocol = Logger.shared,
        deviceInfo: DeviceInfoProtocol = DeviceInfo.shared
    ) {
        self.logger = logger
        self.deviceInfo = deviceInfo
    }
    
    // MARK: - ValidationServiceProtocol Implementation
    
    public func validateModelConfiguration(_ config: ModelConfiguration) -> ValidationResult {
        logger.debug("Validating model configuration")
        
        // Validate preferred models
        if config.preferredModels.isEmpty {
            logger.error("Model configuration validation failed: No preferred models specified")
            return .failure(.invalidModelConfiguration("At least one preferred model must be specified"))
        }
        
        // Validate model size
        let maxSupportedSize = deviceInfo.maxSupportedModelSize
        if config.maxModelSize > maxSupportedSize {
            logger.error("Model configuration validation failed: Model size too large")
            return .failure(.invalidModelConfiguration("Maximum model size (\(config.maxModelSize)MB) exceeds device capability (\(maxSupportedSize)MB)"))
        }
        
        if config.maxModelSize <= 0 {
            logger.error("Model configuration validation failed: Invalid model size")
            return .failure(.invalidModelConfiguration("Model size must be greater than 0"))
        }
        
        // Validate timeout
        if config.modelTimeout <= 0 || config.modelTimeout > 300 {
            logger.error("Model configuration validation failed: Invalid timeout")
            return .failure(.invalidModelConfiguration("Model timeout must be between 1 and 300 seconds"))
        }
        
        // Validate custom model paths
        for path in config.customModelPaths {
            if !isValidModelPath(path) {
                logger.error("Model configuration validation failed: Invalid model path")
                return .failure(.invalidModelConfiguration("Invalid model path: \(path)"))
            }
        }
        
        // Validate GPU acceleration capability
        if config.useGPUAcceleration && !deviceInfo.supportsGPUAcceleration {
            logger.warning("GPU acceleration requested but not supported on this device")
        }
        
        logger.info("Model configuration validation successful")
        return .success
    }
    
    public func validatePerformanceSettings(_ settings: PerformanceSettings) -> ValidationResult {
        logger.debug("Validating performance settings")
        
        // Validate concurrent operations
        let maxConcurrency = deviceInfo.maxRecommendedConcurrency
        if settings.maxConcurrentOperations <= 0 {
            logger.error("Performance validation failed: Invalid concurrent operations count")
            return .failure(.invalidPerformanceSettings("Maximum concurrent operations must be greater than 0"))
        }
        
        if settings.maxConcurrentOperations > maxConcurrency {
            logger.warning("Concurrent operations (\(settings.maxConcurrentOperations)) exceeds recommended maximum (\(maxConcurrency))")
        }
        
        // Validate memory limit
        let availableMemory = deviceInfo.availableMemoryMB
        if settings.memoryLimit <= 0 {
            logger.error("Performance validation failed: Invalid memory limit")
            return .failure(.invalidPerformanceSettings("Memory limit must be greater than 0"))
        }
        
        if settings.memoryLimit > availableMemory {
            logger.error("Performance validation failed: Memory limit exceeds available memory")
            return .failure(.invalidPerformanceSettings("Memory limit (\(settings.memoryLimit)MB) exceeds available memory (\(availableMemory)MB)"))
        }
        
        // Validate background processing capability
        if settings.enableBackgroundProcessing && !deviceInfo.supportsBackgroundProcessing {
            logger.warning("Background processing requested but may be limited on this device")
        }
        
        logger.info("Performance settings validation successful")
        return .success
    }
    
    public func validateSecuritySettings(_ settings: SecuritySettings) -> ValidationResult {
        logger.debug("Validating security settings")
        
        // Validate data retention period
        if settings.dataRetentionDays < 1 || settings.dataRetentionDays > 365 {
            logger.error("Security validation failed: Invalid data retention period")
            return .failure(.invalidSecuritySettings("Data retention period must be between 1 and 365 days"))
        }
        
        // Validate biometric authentication capability
        if settings.biometricAuthRequired && !deviceInfo.supportsBiometricAuth {
            logger.error("Security validation failed: Biometric authentication not supported")
            return .failure(.invalidSecuritySettings("Biometric authentication is required but not supported on this device"))
        }
        
        // Validate encryption algorithm support
        if !isSupportedEncryptionAlgorithm(settings.encryptionAlgorithm) {
            logger.error("Security validation failed: Unsupported encryption algorithm")
            return .failure(.invalidSecuritySettings("Encryption algorithm \(settings.encryptionAlgorithm.rawValue) is not supported"))
        }
        
        // Validate certificate pinning compatibility
        if settings.certificatePinningEnabled && !deviceInfo.supportsCertificatePinning {
            logger.warning("Certificate pinning enabled but may have limited support")
        }
        
        logger.info("Security settings validation successful")
        return .success
    }
    
    public func validateNetworkConfiguration(_ config: NetworkConfiguration) -> ValidationResult {
        logger.debug("Validating network configuration")
        
        // Validate timeout
        if config.timeout <= 0 || config.timeout > 300 {
            logger.error("Network validation failed: Invalid timeout")
            return .failure(.invalidNetworkConfiguration("Network timeout must be between 1 and 300 seconds"))
        }
        
        // Validate retry count
        if config.retryCount < 0 || config.retryCount > 10 {
            logger.error("Network validation failed: Invalid retry count")
            return .failure(.invalidNetworkConfiguration("Retry count must be between 0 and 10"))
        }
        
        // Validate concurrent connections
        if config.maxConcurrentConnections <= 0 || config.maxConcurrentConnections > 20 {
            logger.error("Network validation failed: Invalid concurrent connections")
            return .failure(.invalidNetworkConfiguration("Maximum concurrent connections must be between 1 and 20"))
        }
        
        // Validate cellular access capability
        if !config.allowsCellularAccess && !deviceInfo.hasWiFiConnectivity {
            logger.warning("Cellular access disabled but WiFi connectivity not available")
        }
        
        logger.info("Network configuration validation successful")
        return .success
    }
    
    public func validateCacheConfiguration(_ config: CacheConfiguration) -> ValidationResult {
        logger.debug("Validating cache configuration")
        
        // Validate cache size
        let availableStorage = deviceInfo.availableStorageMB
        if config.maxCacheSize <= 0 {
            logger.error("Cache validation failed: Invalid cache size")
            return .failure(.invalidCacheConfiguration("Cache size must be greater than 0"))
        }
        
        if config.maxCacheSize > availableStorage / 4 {
            logger.warning("Cache size (\(config.maxCacheSize)MB) is large relative to available storage (\(availableStorage)MB)")
        }
        
        // Validate expiration time
        if config.cacheExpirationTime <= 0 || config.cacheExpirationTime > 86400 * 7 { // 7 days
            logger.error("Cache validation failed: Invalid expiration time")
            return .failure(.invalidCacheConfiguration("Cache expiration time must be between 1 second and 7 days"))
        }
        
        // Validate cache type configuration
        if !config.enableInMemoryCache && !config.enableDiskCache {
            logger.error("Cache validation failed: No cache type enabled")
            return .failure(.invalidCacheConfiguration("At least one cache type (in-memory or disk) must be enabled"))
        }
        
        // Validate preloading capability
        if config.enablePreloading && !deviceInfo.supportsBackgroundProcessing {
            logger.warning("Cache preloading enabled but background processing may be limited")
        }
        
        logger.info("Cache configuration validation successful")
        return .success
    }
    
    // MARK: - AI Data Validation
    
    /// Validates input data for AI processing
    /// - Parameter data: Input data to validate
    /// - Returns: Validation result with success or failure details
    public func validateAIInputData<T>(_ data: T) -> ValidationResult where T: AIInputValidatable {
        logger.debug("Validating AI input data of type \(type(of: data))")
        
        do {
            try data.validate()
            logger.info("AI input data validation successful")
            return .success
        } catch let error as AIInputValidationError {
            logger.error("AI input data validation failed: \(error.localizedDescription)")
            return .failure(.invalidModelConfiguration(error.localizedDescription))
        } catch {
            logger.error("AI input data validation failed with unexpected error: \(error.localizedDescription)")
            return .failure(.invalidModelConfiguration("Unexpected validation error: \(error.localizedDescription)"))
        }
    }
    
    /// Validates AI model output data
    /// - Parameter output: Model output to validate
    /// - Returns: Validation result with success or failure details
    public func validateAIOutputData<T>(_ output: T) -> ValidationResult where T: AIOutputValidatable {
        logger.debug("Validating AI output data of type \(type(of: output))")
        
        do {
            try output.validate()
            logger.info("AI output data validation successful")
            return .success
        } catch let error as AIOutputValidationError {
            logger.error("AI output data validation failed: \(error.localizedDescription)")
            return .failure(.invalidModelConfiguration(error.localizedDescription))
        } catch {
            logger.error("AI output data validation failed with unexpected error: \(error.localizedDescription)")
            return .failure(.invalidModelConfiguration("Unexpected validation error: \(error.localizedDescription)"))
        }
    }
    
    // MARK: - Private Helper Methods
    
    private func isValidModelPath(_ path: String) -> Bool {
        // Validate file path format and accessibility
        let url = URL(fileURLWithPath: path)
        
        // Check if path has valid extension
        let validExtensions = ["mlmodel", "tflite", "onnx", "coreml"]
        let pathExtension = url.pathExtension.lowercased()
        
        guard validExtensions.contains(pathExtension) else {
            return false
        }
        
        // Check if file exists and is readable
        let fileManager = FileManager.default
        return fileManager.fileExists(atPath: path) && fileManager.isReadableFile(atPath: path)
    }
    
    private func isSupportedEncryptionAlgorithm(_ algorithm: EncryptionAlgorithm) -> Bool {
        // Check if the encryption algorithm is supported on the current platform
        switch algorithm {
        case .aes256GCM:
            return true // Always supported
        case .chaCha20Poly1305:
            return deviceInfo.supportsAdvancedCryptography
        }
    }
}

// MARK: - AI Input/Output Validation Protocols

public protocol AIInputValidatable {
    func validate() throws
}

public protocol AIOutputValidatable {
    func validate() throws
}

// MARK: - Validation Errors

public enum AIInputValidationError: LocalizedError {
    case invalidDataFormat(String)
    case dataSizeExceeded(Int, Int) // actual, maximum
    case unsupportedDataType(String)
    case corrupted(String)
    case missingRequiredFields([String])
    
    public var errorDescription: String? {
        switch self {
        case .invalidDataFormat(let format):
            return "Invalid data format: \(format)"
        case .dataSizeExceeded(let actual, let maximum):
            return "Data size exceeded: \(actual) bytes (maximum: \(maximum) bytes)"
        case .unsupportedDataType(let type):
            return "Unsupported data type: \(type)"
        case .corrupted(let reason):
            return "Data corrupted: \(reason)"
        case .missingRequiredFields(let fields):
            return "Missing required fields: \(fields.joined(separator: ", "))"
        }
    }
}

public enum AIOutputValidationError: LocalizedError {
    case invalidOutputFormat(String)
    case incompleteOutput(String)
    case confidenceThresholdNotMet(Double, Double) // actual, required
    case unexpectedOutputType(String)
    case outputSizeInvalid(Int)
    
    public var errorDescription: String? {
        switch self {
        case .invalidOutputFormat(let format):
            return "Invalid output format: \(format)"
        case .incompleteOutput(let reason):
            return "Incomplete output: \(reason)"
        case .confidenceThresholdNotMet(let actual, let required):
            return "Confidence threshold not met: \(actual) (required: \(required))"
        case .unexpectedOutputType(let type):
            return "Unexpected output type: \(type)"
        case .outputSizeInvalid(let size):
            return "Invalid output size: \(size)"
        }
    }
}

// MARK: - Logger Protocol

public protocol LoggerProtocol {
    func debug(_ message: String)
    func info(_ message: String)
    func warning(_ message: String)
    func error(_ message: String)
}

// MARK: - Device Info Protocol

public protocol DeviceInfoProtocol {
    var maxSupportedModelSize: Int { get }
    var supportsGPUAcceleration: Bool { get }
    var maxRecommendedConcurrency: Int { get }
    var availableMemoryMB: Int { get }
    var supportsBackgroundProcessing: Bool { get }
    var supportsBiometricAuth: Bool { get }
    var supportsCertificatePinning: Bool { get }
    var hasWiFiConnectivity: Bool { get }
    var availableStorageMB: Int { get }
    var supportsAdvancedCryptography: Bool { get }
}

// MARK: - Default Implementations

public final class Logger: LoggerProtocol {
    public static let shared = Logger()
    
    private init() {}
    
    public func debug(_ message: String) {
        print("🐛 [DEBUG] \(message)")
    }
    
    public func info(_ message: String) {
        print("ℹ️ [INFO] \(message)")
    }
    
    public func warning(_ message: String) {
        print("⚠️ [WARNING] \(message)")
    }
    
    public func error(_ message: String) {
        print("❌ [ERROR] \(message)")
    }
}

public final class DeviceInfo: DeviceInfoProtocol {
    public static let shared = DeviceInfo()
    
    private init() {}
    
    public var maxSupportedModelSize: Int {
        let totalMemory = ProcessInfo.processInfo.physicalMemory
        return min(Int(totalMemory / (1024 * 1024 * 8)), 1000) // Max 1GB or 1/8th of total memory
    }
    
    public var supportsGPUAcceleration: Bool {
        return true // Simplified - in real implementation, check Metal support
    }
    
    public var maxRecommendedConcurrency: Int {
        return max(2, ProcessInfo.processInfo.processorCount)
    }
    
    public var availableMemoryMB: Int {
        let totalMemory = ProcessInfo.processInfo.physicalMemory
        return Int(totalMemory / (1024 * 1024 * 2)) // Simplified - half of total memory
    }
    
    public var supportsBackgroundProcessing: Bool {
        return true
    }
    
    public var supportsBiometricAuth: Bool {
        return true // Simplified - in real implementation, check LAContext
    }
    
    public var supportsCertificatePinning: Bool {
        return true
    }
    
    public var hasWiFiConnectivity: Bool {
        return true // Simplified - in real implementation, check network reachability
    }
    
    public var availableStorageMB: Int {
        // Simplified implementation
        do {
            let resources = try URL.documentsDirectory.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey])
            if let capacity = resources.volumeAvailableCapacityForImportantUsage {
                return Int(capacity / (1024 * 1024))
            }
        } catch {
            // Fallback value
        }
        return 1000 // 1GB fallback
    }
    
    public var supportsAdvancedCryptography: Bool {
        return true
    }
}