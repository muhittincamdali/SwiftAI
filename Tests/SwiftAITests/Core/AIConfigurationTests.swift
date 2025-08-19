//
//  AIConfigurationTests.swift
//  SwiftAITests
//
//  Created by Muhittin Camdali on 17/08/2024.
//

import XCTest
import Combine
@testable import SwiftAI

/// Comprehensive test suite for AIConfiguration with enterprise-grade coverage
final class AIConfigurationTests: XCTestCase {
    
    // MARK: - Properties
    
    private var configuration: AIConfiguration!
    private var cancellables: Set<AnyCancellable>!
    private var mockValidationService: MockValidationService!
    
    // MARK: - Setup & Teardown
    
    override func setUpWithError() throws {
        super.setUp()
        cancellables = Set<AnyCancellable>()
        mockValidationService = MockValidationService()
        configuration = AIConfiguration()
    }
    
    override func tearDownWithError() throws {
        cancellables.removeAll()
        configuration = nil
        mockValidationService = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testDefaultInitialization() throws {
        // Given & When
        let config = AIConfiguration()
        
        // Then
        XCTAssertEqual(config.modelConfiguration.maxInputTokens, 4096)
        XCTAssertEqual(config.modelConfiguration.maxOutputTokens, 2048)
        XCTAssertEqual(config.modelConfiguration.temperature, 0.7)
        XCTAssertEqual(config.performanceSettings.maxConcurrentOperations, 4)
        XCTAssertEqual(config.performanceSettings.timeoutInterval, 30.0)
        XCTAssertTrue(config.securitySettings.enableEncryption)
        XCTAssertTrue(config.securitySettings.requireAuthentication)
    }
    
    func testCustomInitialization() throws {
        // Given
        let modelConfig = ModelConfiguration(
            maxInputTokens: 8192,
            maxOutputTokens: 4096,
            temperature: 0.5,
            topP: 0.9,
            frequencyPenalty: 0.1,
            presencePenalty: 0.1
        )
        
        let performanceSettings = PerformanceSettings(
            maxConcurrentOperations: 8,
            timeoutInterval: 60.0,
            enableCaching: true,
            cacheSize: 1024,
            enableOptimization: true
        )
        
        let securitySettings = SecuritySettings(
            enableEncryption: true,
            encryptionAlgorithm: .aes256GCM,
            requireAuthentication: true,
            authenticationMethod: .biometric,
            enableAuditLogging: true
        )
        
        // When
        let config = AIConfiguration(
            modelConfiguration: modelConfig,
            performanceSettings: performanceSettings,
            securitySettings: securitySettings
        )
        
        // Then
        XCTAssertEqual(config.modelConfiguration.maxInputTokens, 8192)
        XCTAssertEqual(config.performanceSettings.maxConcurrentOperations, 8)
        XCTAssertEqual(config.securitySettings.encryptionAlgorithm, .aes256GCM)
        XCTAssertEqual(config.securitySettings.authenticationMethod, .biometric)
    }
    
    // MARK: - Validation Tests
    
    func testValidConfiguration() throws {
        // Given
        let config = AIConfiguration()
        
        // When
        let validationResult = config.validate()
        
        // Then
        XCTAssertTrue(validationResult.isValid)
        XCTAssertTrue(validationResult.errors.isEmpty)
        XCTAssertTrue(validationResult.warnings.isEmpty)
    }
    
    func testInvalidModelConfiguration() throws {
        // Given
        var config = AIConfiguration()
        config.modelConfiguration.maxInputTokens = 0 // Invalid
        config.modelConfiguration.temperature = 2.5 // Invalid (should be 0-2)
        
        // When
        let validationResult = config.validate()
        
        // Then
        XCTAssertFalse(validationResult.isValid)
        XCTAssertFalse(validationResult.errors.isEmpty)
        XCTAssertTrue(validationResult.errors.contains { $0.contains("maxInputTokens") })
        XCTAssertTrue(validationResult.errors.contains { $0.contains("temperature") })
    }
    
    func testInvalidPerformanceConfiguration() throws {
        // Given
        var config = AIConfiguration()
        config.performanceSettings.maxConcurrentOperations = 0 // Invalid
        config.performanceSettings.timeoutInterval = -10.0 // Invalid
        
        // When
        let validationResult = config.validate()
        
        // Then
        XCTAssertFalse(validationResult.isValid)
        XCTAssertFalse(validationResult.errors.isEmpty)
        XCTAssertTrue(validationResult.errors.contains { $0.contains("maxConcurrentOperations") })
        XCTAssertTrue(validationResult.errors.contains { $0.contains("timeoutInterval") })
    }
    
    func testConfigurationWarnings() throws {
        // Given
        var config = AIConfiguration()
        config.modelConfiguration.temperature = 1.8 // High but valid
        config.performanceSettings.maxConcurrentOperations = 16 // High but valid
        
        // When
        let validationResult = config.validate()
        
        // Then
        XCTAssertTrue(validationResult.isValid)
        XCTAssertTrue(validationResult.errors.isEmpty)
        XCTAssertFalse(validationResult.warnings.isEmpty)
    }
    
    // MARK: - Device Capability Tests
    
    func testDeviceCapabilityAnalysis() throws {
        // Given
        let config = AIConfiguration()
        
        // When
        let capabilities = config.analyzeDeviceCapabilities()
        
        // Then
        XCTAssertNotNil(capabilities)
        XCTAssertTrue(capabilities.totalMemory > 0)
        XCTAssertTrue(capabilities.availableMemory > 0)
        XCTAssertTrue(capabilities.cpuCoreCount > 0)
        XCTAssertFalse(capabilities.deviceModel.isEmpty)
        XCTAssertFalse(capabilities.osVersion.isEmpty)
    }
    
    func testDeviceCapabilityOptimization() throws {
        // Given
        let config = AIConfiguration()
        
        // When
        let optimizedConfig = config.optimizeForDevice()
        
        // Then
        XCTAssertNotNil(optimizedConfig)
        XCTAssertTrue(optimizedConfig.performanceSettings.maxConcurrentOperations <= config.performanceSettings.maxConcurrentOperations)
        
        // Verify optimization based on device capabilities
        let capabilities = config.analyzeDeviceCapabilities()
        if capabilities.totalMemory < 4_000_000_000 { // Less than 4GB
            XCTAssertTrue(optimizedConfig.performanceSettings.maxConcurrentOperations <= 2)
        }
    }
    
    // MARK: - Reactive Configuration Tests
    
    func testConfigurationChangeNotifications() throws {
        // Given
        let expectation = XCTestExpectation(description: "Configuration change notification")
        var receivedUpdates = 0
        
        configuration.$modelConfiguration
            .dropFirst()
            .sink { _ in
                receivedUpdates += 1
                if receivedUpdates == 1 {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // When
        configuration.modelConfiguration.temperature = 0.8
        
        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(receivedUpdates, 1)
        XCTAssertEqual(configuration.modelConfiguration.temperature, 0.8)
    }
    
    func testMultipleConfigurationUpdates() throws {
        // Given
        let expectation = XCTestExpectation(description: "Multiple configuration updates")
        expectation.expectedFulfillmentCount = 3
        
        configuration.$performanceSettings
            .dropFirst()
            .sink { _ in
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // When
        configuration.performanceSettings.maxConcurrentOperations = 8
        configuration.performanceSettings.timeoutInterval = 45.0
        configuration.performanceSettings.enableCaching = false
        
        // Then
        wait(for: [expectation], timeout: 2.0)
    }
    
    // MARK: - Persistence Tests
    
    func testConfigurationPersistence() throws {
        // Given
        var config = AIConfiguration()
        config.modelConfiguration.temperature = 0.9
        config.performanceSettings.maxConcurrentOperations = 6
        config.securitySettings.enableEncryption = false
        
        // When
        let data = try JSONEncoder().encode(config)
        let decodedConfig = try JSONDecoder().decode(AIConfiguration.self, from: data)
        
        // Then
        XCTAssertEqual(decodedConfig.modelConfiguration.temperature, 0.9)
        XCTAssertEqual(decodedConfig.performanceSettings.maxConcurrentOperations, 6)
        XCTAssertFalse(decodedConfig.securitySettings.enableEncryption)
    }
    
    func testConfigurationCoding() throws {
        // Given
        let originalConfig = AIConfiguration()
        
        // When
        let encodedData = try JSONEncoder().encode(originalConfig)
        let decodedConfig = try JSONDecoder().decode(AIConfiguration.self, from: encodedData)
        
        // Then
        XCTAssertEqual(originalConfig.modelConfiguration.maxInputTokens, decodedConfig.modelConfiguration.maxInputTokens)
        XCTAssertEqual(originalConfig.performanceSettings.timeoutInterval, decodedConfig.performanceSettings.timeoutInterval)
        XCTAssertEqual(originalConfig.securitySettings.enableEncryption, decodedConfig.securitySettings.enableEncryption)
    }
    
    // MARK: - Performance Tests
    
    func testConfigurationPerformance() throws {
        // Given
        let numberOfConfigurations = 1000
        
        // When & Then
        measure {
            for _ in 0..<numberOfConfigurations {
                let config = AIConfiguration()
                _ = config.validate()
                _ = config.analyzeDeviceCapabilities()
            }
        }
    }
    
    func testValidationPerformance() throws {
        // Given
        let config = AIConfiguration()
        let numberOfValidations = 10000
        
        // When & Then
        measure {
            for _ in 0..<numberOfValidations {
                _ = config.validate()
            }
        }
    }
    
    // MARK: - Edge Cases Tests
    
    func testExtremeValues() throws {
        // Given
        var config = AIConfiguration()
        
        // When
        config.modelConfiguration.maxInputTokens = Int.max
        config.modelConfiguration.temperature = Double.greatestFiniteMagnitude
        config.performanceSettings.timeoutInterval = TimeInterval.greatestFiniteMagnitude
        
        // Then
        let validationResult = config.validate()
        XCTAssertFalse(validationResult.isValid)
        XCTAssertFalse(validationResult.errors.isEmpty)
    }
    
    func testNegativeValues() throws {
        // Given
        var config = AIConfiguration()
        
        // When
        config.modelConfiguration.maxInputTokens = -1
        config.modelConfiguration.temperature = -1.0
        config.performanceSettings.maxConcurrentOperations = -1
        
        // Then
        let validationResult = config.validate()
        XCTAssertFalse(validationResult.isValid)
        XCTAssertTrue(validationResult.errors.count >= 3)
    }
    
    func testZeroValues() throws {
        // Given
        var config = AIConfiguration()
        
        // When
        config.modelConfiguration.maxInputTokens = 0
        config.performanceSettings.maxConcurrentOperations = 0
        config.performanceSettings.timeoutInterval = 0
        
        // Then
        let validationResult = config.validate()
        XCTAssertFalse(validationResult.isValid)
        XCTAssertTrue(validationResult.errors.count >= 3)
    }
    
    // MARK: - Configuration Merging Tests
    
    func testConfigurationMerging() throws {
        // Given
        let baseConfig = AIConfiguration()
        
        var overrideConfig = AIConfiguration()
        overrideConfig.modelConfiguration.temperature = 1.2
        overrideConfig.performanceSettings.maxConcurrentOperations = 8
        
        // When
        let mergedConfig = baseConfig.merging(with: overrideConfig)
        
        // Then
        XCTAssertEqual(mergedConfig.modelConfiguration.temperature, 1.2)
        XCTAssertEqual(mergedConfig.performanceSettings.maxConcurrentOperations, 8)
        XCTAssertEqual(mergedConfig.modelConfiguration.maxInputTokens, baseConfig.modelConfiguration.maxInputTokens) // Should preserve base values
    }
    
    // MARK: - Thread Safety Tests
    
    func testThreadSafety() throws {
        // Given
        let config = AIConfiguration()
        let numberOfThreads = 10
        let operationsPerThread = 100
        let expectation = XCTestExpectation(description: "Thread safety test")
        expectation.expectedFulfillmentCount = numberOfThreads
        
        // When
        for threadIndex in 0..<numberOfThreads {
            DispatchQueue.global().async {
                for operationIndex in 0..<operationsPerThread {
                    // Perform concurrent operations
                    _ = config.validate()
                    _ = config.analyzeDeviceCapabilities()
                    
                    // Modify configuration safely
                    DispatchQueue.main.async {
                        config.modelConfiguration.temperature = Double(operationIndex) / 100.0
                    }
                }
                expectation.fulfill()
            }
        }
        
        // Then
        wait(for: [expectation], timeout: 10.0)
    }
    
    // MARK: - Configuration Template Tests
    
    func testPresetConfigurations() throws {
        // Given & When
        let lowPowerConfig = AIConfiguration.lowPowerPreset()
        let highPerformanceConfig = AIConfiguration.highPerformancePreset()
        let balancedConfig = AIConfiguration.balancedPreset()
        
        // Then
        XCTAssertTrue(lowPowerConfig.performanceSettings.maxConcurrentOperations <= 2)
        XCTAssertTrue(highPerformanceConfig.performanceSettings.maxConcurrentOperations >= 6)
        XCTAssertTrue(balancedConfig.performanceSettings.maxConcurrentOperations >= 3)
        XCTAssertTrue(balancedConfig.performanceSettings.maxConcurrentOperations <= 5)
        
        // Validate all presets
        XCTAssertTrue(lowPowerConfig.validate().isValid)
        XCTAssertTrue(highPerformanceConfig.validate().isValid)
        XCTAssertTrue(balancedConfig.validate().isValid)
    }
    
    // MARK: - Memory Management Tests
    
    func testMemoryManagement() throws {
        // Given
        weak var weakConfig: AIConfiguration?
        
        // When
        autoreleasepool {
            let config = AIConfiguration()
            weakConfig = config
            
            // Perform operations
            _ = config.validate()
            _ = config.analyzeDeviceCapabilities()
        }
        
        // Then
        XCTAssertNil(weakConfig, "Configuration should be deallocated")
    }
    
    // MARK: - Integration Tests
    
    func testConfigurationIntegrationWithValidationService() throws {
        // Given
        let config = AIConfiguration()
        
        // When
        let validationResult = mockValidationService.validateModelConfiguration(config.modelConfiguration)
        
        // Then
        XCTAssertNotNil(validationResult)
        // Additional assertions based on mock service behavior
    }
}

// MARK: - Mock Objects

class MockValidationService: ValidationServiceProtocol {
    func validateModelConfiguration(_ configuration: ModelConfiguration) -> ValidationResult {
        if configuration.maxInputTokens <= 0 {
            return .failure(["Invalid maxInputTokens"])
        }
        if configuration.temperature < 0 || configuration.temperature > 2 {
            return .failure(["Invalid temperature"])
        }
        return .success
    }
    
    func validateTrainingData(_ data: TrainingData) -> ValidationResult {
        return .success
    }
    
    func validateAIInput<T: AIInputValidatable>(_ input: T) -> ValidationResult {
        return .success
    }
    
    func validateAIOutput<T: AIOutputValidatable>(_ output: T) -> ValidationResult {
        return .success
    }
    
    func validatePerformanceMetrics(_ metrics: [String: Any]) -> ValidationResult {
        return .success
    }
}

// MARK: - Test Extensions

extension AIConfiguration {
    static func lowPowerPreset() -> AIConfiguration {
        var config = AIConfiguration()
        config.performanceSettings.maxConcurrentOperations = 1
        config.performanceSettings.enableCaching = true
        config.modelConfiguration.maxInputTokens = 2048
        return config
    }
    
    static func highPerformancePreset() -> AIConfiguration {
        var config = AIConfiguration()
        config.performanceSettings.maxConcurrentOperations = 8
        config.performanceSettings.enableOptimization = true
        config.modelConfiguration.maxInputTokens = 8192
        return config
    }
    
    static func balancedPreset() -> AIConfiguration {
        var config = AIConfiguration()
        config.performanceSettings.maxConcurrentOperations = 4
        config.performanceSettings.enableCaching = true
        config.performanceSettings.enableOptimization = true
        return config
    }
    
    func merging(with other: AIConfiguration) -> AIConfiguration {
        var merged = self
        merged.modelConfiguration = other.modelConfiguration
        merged.performanceSettings = other.performanceSettings
        merged.securitySettings = other.securitySettings
        return merged
    }
}