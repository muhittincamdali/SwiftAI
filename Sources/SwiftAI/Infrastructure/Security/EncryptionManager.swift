//
//  EncryptionManager.swift
//  SwiftAI
//
//  Created by Muhittin Camdali on 17/08/2024.
//

import Foundation
import CryptoKit
import Security
import LocalAuthentication

/// Enterprise-grade encryption manager with bank-level security
public final class EncryptionManager: ObservableObject, EncryptionManagerProtocol {
    
    // MARK: - Public Properties
    
    @Published public private(set) var isSecureEnclaveAvailable: Bool = false
    @Published public private(set) var isBiometricAuthenticationAvailable: Bool = false
    
    // MARK: - Private Properties
    
    private let logger: LoggerProtocol
    private let keyManager: KeyManagerProtocol
    private let secureStorage: SecureStorageProtocol
    private let biometricManager: BiometricManagerProtocol
    
    private let keyDerivationRounds: Int = 100_000
    private let saltSize: Int = 32
    private let ivSize: Int = 16
    
    // MARK: - Initialization
    
    public init(
        logger: LoggerProtocol = Logger.shared,
        keyManager: KeyManagerProtocol? = nil,
        secureStorage: SecureStorageProtocol? = nil,
        biometricManager: BiometricManagerProtocol? = nil
    ) {
        self.logger = logger
        self.keyManager = keyManager
        self.secureStorage = secureStorage
        self.biometricManager = biometricManager
        
        setupSecurityEnvironment()
        checkDeviceCapabilities()
    }
    
    // MARK: - AES-256-GCM Encryption
    
    /// Encrypts data using AES-256-GCM encryption
    /// - Parameters:
    ///   - data: Data to encrypt
    ///   - key: Encryption key (optional, will generate if not provided)
    ///   - associatedData: Additional authenticated data
    /// - Returns: Encrypted data with authentication tag
    /// - Throws: EncryptionError if encryption fails
    public func encryptAES256GCM(
        data: Data,
        key: SymmetricKey? = nil,
        associatedData: Data? = nil
    ) throws -> EncryptedData {
        logger.debug("Starting AES-256-GCM encryption")
        
        let encryptionKey = key ?? keyManager.generateAES256Key()
        
        do {
            let sealedBox = try AES.GCM.seal(
                data,
                using: encryptionKey,
                authenticating: associatedData
            )
            
            guard let encryptedData = sealedBox.ciphertext,
                  let tag = sealedBox.tag,
                  let nonce = sealedBox.nonce else {
                throw EncryptionError.encryptionFailed("Failed to extract encryption components")
            }
            
            let result = EncryptedData(
                algorithm: .aes256GCM,
                encryptedData: encryptedData,
                nonce: Data(nonce),
                tag: tag,
                keyId: encryptionKey.withUnsafeBytes { Data($0) }.sha256Hash,
                metadata: EncryptionMetadata(
                    timestamp: Date(),
                    version: "1.0",
                    keyDerivationRounds: keyDerivationRounds
                )
            )
            
            logger.info("AES-256-GCM encryption completed successfully")
            return result
            
        } catch {
            logger.error("AES-256-GCM encryption failed: \(error.localizedDescription)")
            throw EncryptionError.encryptionFailed(error.localizedDescription)
        }
    }
    
    /// Decrypts AES-256-GCM encrypted data
    /// - Parameters:
    ///   - encryptedData: Encrypted data package
    ///   - key: Decryption key
    ///   - associatedData: Additional authenticated data used during encryption
    /// - Returns: Decrypted original data
    /// - Throws: EncryptionError if decryption fails
    public func decryptAES256GCM(
        encryptedData: EncryptedData,
        key: SymmetricKey,
        associatedData: Data? = nil
    ) throws -> Data {
        logger.debug("Starting AES-256-GCM decryption")
        
        guard encryptedData.algorithm == .aes256GCM else {
            throw EncryptionError.algorithmMismatch
        }
        
        do {
            let nonce = try AES.GCM.Nonce(data: encryptedData.nonce)
            let sealedBox = try AES.GCM.SealedBox(
                nonce: nonce,
                ciphertext: encryptedData.encryptedData,
                tag: encryptedData.tag
            )
            
            let decryptedData = try AES.GCM.open(
                sealedBox,
                using: key,
                authenticating: associatedData
            )
            
            logger.info("AES-256-GCM decryption completed successfully")
            return decryptedData
            
        } catch {
            logger.error("AES-256-GCM decryption failed: \(error.localizedDescription)")
            throw EncryptionError.decryptionFailed(error.localizedDescription)
        }
    }
    
    // MARK: - ChaCha20-Poly1305 Encryption
    
    /// Encrypts data using ChaCha20-Poly1305 encryption
    /// - Parameters:
    ///   - data: Data to encrypt
    ///   - key: Encryption key (optional, will generate if not provided)
    ///   - associatedData: Additional authenticated data
    /// - Returns: Encrypted data with authentication tag
    /// - Throws: EncryptionError if encryption fails
    public func encryptChaCha20Poly1305(
        data: Data,
        key: SymmetricKey? = nil,
        associatedData: Data? = nil
    ) throws -> EncryptedData {
        logger.debug("Starting ChaCha20-Poly1305 encryption")
        
        let encryptionKey = key ?? keyManager.generateChaCha20Key()
        
        do {
            let sealedBox = try ChaChaPoly.seal(
                data,
                using: encryptionKey,
                authenticating: associatedData
            )
            
            let result = EncryptedData(
                algorithm: .chaCha20Poly1305,
                encryptedData: sealedBox.ciphertext,
                nonce: Data(sealedBox.nonce),
                tag: sealedBox.tag,
                keyId: encryptionKey.withUnsafeBytes { Data($0) }.sha256Hash,
                metadata: EncryptionMetadata(
                    timestamp: Date(),
                    version: "1.0",
                    keyDerivationRounds: keyDerivationRounds
                )
            )
            
            logger.info("ChaCha20-Poly1305 encryption completed successfully")
            return result
            
        } catch {
            logger.error("ChaCha20-Poly1305 encryption failed: \(error.localizedDescription)")
            throw EncryptionError.encryptionFailed(error.localizedDescription)
        }
    }
    
    /// Decrypts ChaCha20-Poly1305 encrypted data
    /// - Parameters:
    ///   - encryptedData: Encrypted data package
    ///   - key: Decryption key
    ///   - associatedData: Additional authenticated data used during encryption
    /// - Returns: Decrypted original data
    /// - Throws: EncryptionError if decryption fails
    public func decryptChaCha20Poly1305(
        encryptedData: EncryptedData,
        key: SymmetricKey,
        associatedData: Data? = nil
    ) throws -> Data {
        logger.debug("Starting ChaCha20-Poly1305 decryption")
        
        guard encryptedData.algorithm == .chaCha20Poly1305 else {
            throw EncryptionError.algorithmMismatch
        }
        
        do {
            let nonce = try ChaChaPoly.Nonce(data: encryptedData.nonce)
            let sealedBox = try ChaChaPoly.SealedBox(
                nonce: nonce,
                ciphertext: encryptedData.encryptedData,
                tag: encryptedData.tag
            )
            
            let decryptedData = try ChaChaPoly.open(
                sealedBox,
                using: key,
                authenticating: associatedData
            )
            
            logger.info("ChaCha20-Poly1305 decryption completed successfully")
            return decryptedData
            
        } catch {
            logger.error("ChaCha20-Poly1305 decryption failed: \(error.localizedDescription)")
            throw EncryptionError.decryptionFailed(error.localizedDescription)
        }
    }
    
    // MARK: - Secure Enclave Operations
    
    /// Generates a key in the Secure Enclave
    /// - Parameters:
    ///   - keyId: Unique identifier for the key
    ///   - requireBiometry: Whether biometric authentication is required
    /// - Returns: Key reference for the generated key
    /// - Throws: EncryptionError if key generation fails
    public func generateSecureEnclaveKey(
        keyId: String,
        requireBiometry: Bool = true
    ) throws -> SecureEnclaveKeyReference {
        logger.debug("Generating Secure Enclave key: \(keyId)")
        
        guard isSecureEnclaveAvailable else {
            throw EncryptionError.secureEnclaveNotAvailable
        }
        
        if requireBiometry && !isBiometricAuthenticationAvailable {
            throw EncryptionError.biometricAuthenticationNotAvailable
        }
        
        var accessControl: SecAccessControl
        var accessControlFlags: SecAccessControlCreateFlags = [.privateKeyUsage]
        
        if requireBiometry {
            accessControlFlags.insert(.biometryAny)
        }
        
        var error: Unmanaged<CFError>?
        guard let access = SecAccessControlCreateWithFlags(
            kCFAllocatorDefault,
            kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
            accessControlFlags,
            &error
        ) else {
            let errorDescription = error?.takeRetainedValue().localizedDescription ?? "Unknown error"
            throw EncryptionError.keyGenerationFailed("Access control creation failed: \(errorDescription)")
        }
        
        accessControl = access
        
        let keyAttributes: [String: Any] = [
            kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
            kSecAttrKeySizeInBits as String: 256,
            kSecAttrTokenID as String: kSecAttrTokenIDSecureEnclave,
            kSecPrivateKeyAttrs as String: [
                kSecAttrIsPermanent as String: true,
                kSecAttrApplicationTag as String: keyId.data(using: .utf8)!,
                kSecAttrAccessControl as String: accessControl
            ]
        ]
        
        guard let privateKey = SecKeyCreateRandomKey(keyAttributes as CFDictionary, &error) else {
            let errorDescription = error?.takeRetainedValue().localizedDescription ?? "Unknown error"
            throw EncryptionError.keyGenerationFailed("Secure Enclave key generation failed: \(errorDescription)")
        }
        
        let keyReference = SecureEnclaveKeyReference(
            keyId: keyId,
            privateKey: privateKey,
            requiresBiometry: requireBiometry,
            createdAt: Date()
        )
        
        // Store key reference
        try secureStorage.store(keyReference, forKey: "secure_enclave_key_\(keyId)")
        
        logger.info("Secure Enclave key generated successfully: \(keyId)")
        return keyReference
    }
    
    /// Signs data using a Secure Enclave key
    /// - Parameters:
    ///   - data: Data to sign
    ///   - keyReference: Reference to the Secure Enclave key
    /// - Returns: Digital signature
    /// - Throws: EncryptionError if signing fails
    public func signWithSecureEnclaveKey(
        data: Data,
        keyReference: SecureEnclaveKeyReference
    ) throws -> Data {
        logger.debug("Signing data with Secure Enclave key: \(keyReference.keyId)")
        
        if keyReference.requiresBiometry {
            let authResult = try biometricManager.authenticateUser()
            guard authResult else {
                throw EncryptionError.biometricAuthenticationFailed
            }
        }
        
        var error: Unmanaged<CFError>?
        guard let signature = SecKeyCreateSignature(
            keyReference.privateKey,
            .ecdsaSignatureMessageX962SHA256,
            data as CFData,
            &error
        ) else {
            let errorDescription = error?.takeRetainedValue().localizedDescription ?? "Unknown error"
            throw EncryptionError.signingFailed("Secure Enclave signing failed: \(errorDescription)")
        }
        
        logger.info("Data signed successfully with Secure Enclave key")
        return signature as Data
    }
    
    // MARK: - Key Derivation
    
    /// Derives a key from a password using PBKDF2
    /// - Parameters:
    ///   - password: Source password
    ///   - salt: Cryptographic salt (will generate if not provided)
    ///   - rounds: Number of derivation rounds
    ///   - keyLength: Desired key length in bytes
    /// - Returns: Derived key and salt used
    /// - Throws: EncryptionError if key derivation fails
    public func deriveKey(
        from password: String,
        salt: Data? = nil,
        rounds: Int? = nil,
        keyLength: Int = 32
    ) throws -> (key: SymmetricKey, salt: Data) {
        logger.debug("Deriving key from password")
        
        guard let passwordData = password.data(using: .utf8) else {
            throw EncryptionError.invalidInput("Password cannot be converted to data")
        }
        
        let derivationSalt = salt ?? Data.random(length: saltSize)
        let derivationRounds = rounds ?? keyDerivationRounds
        
        var derivedKeyData = Data(count: keyLength)
        let result = derivedKeyData.withUnsafeMutableBytes { derivedKeyBytes in
            derivationSalt.withUnsafeBytes { saltBytes in
                passwordData.withUnsafeBytes { passwordBytes in
                    CCKeyDerivationPBKDF(
                        CCPBKDFAlgorithm(kCCPBKDF2),
                        passwordBytes.bindMemory(to: Int8.self).baseAddress,
                        passwordData.count,
                        saltBytes.bindMemory(to: UInt8.self).baseAddress,
                        derivationSalt.count,
                        CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA256),
                        UInt32(derivationRounds),
                        derivedKeyBytes.bindMemory(to: UInt8.self).baseAddress,
                        keyLength
                    )
                }
            }
        }
        
        guard result == kCCSuccess else {
            throw EncryptionError.keyDerivationFailed("PBKDF2 derivation failed with code: \(result)")
        }
        
        let derivedKey = SymmetricKey(data: derivedKeyData)
        
        logger.info("Key derived successfully from password")
        return (key: derivedKey, salt: derivationSalt)
    }
    
    // MARK: - Hashing
    
    /// Computes SHA-256 hash of data
    /// - Parameter data: Data to hash
    /// - Returns: SHA-256 hash
    public func sha256Hash(of data: Data) -> Data {
        return Data(SHA256.hash(data: data))
    }
    
    /// Computes SHA-512 hash of data
    /// - Parameter data: Data to hash
    /// - Returns: SHA-512 hash
    public func sha512Hash(of data: Data) -> Data {
        return Data(SHA512.hash(data: data))
    }
    
    /// Computes HMAC-SHA256 of data with key
    /// - Parameters:
    ///   - data: Data to authenticate
    ///   - key: HMAC key
    /// - Returns: HMAC-SHA256 authentication code
    public func hmacSHA256(data: Data, key: SymmetricKey) -> Data {
        return Data(HMAC<SHA256>.authenticationCode(for: data, using: key))
    }
    
    // MARK: - Random Data Generation
    
    /// Generates cryptographically secure random data
    /// - Parameter length: Number of bytes to generate
    /// - Returns: Random data
    /// - Throws: EncryptionError if random generation fails
    public func generateRandomData(length: Int) throws -> Data {
        guard length > 0 else {
            throw EncryptionError.invalidInput("Length must be positive")
        }
        
        var randomData = Data(count: length)
        let result = randomData.withUnsafeMutableBytes { bytes in
            SecRandomCopyBytes(kSecRandomDefault, length, bytes.bindMemory(to: UInt8.self).baseAddress!)
        }
        
        guard result == errSecSuccess else {
            throw EncryptionError.randomGenerationFailed("SecRandomCopyBytes failed with code: \(result)")
        }
        
        return randomData
    }
    
    // MARK: - Data Integrity
    
    /// Creates a digital signature for data integrity
    /// - Parameters:
    ///   - data: Data to sign
    ///   - privateKey: Private key for signing
    /// - Returns: Digital signature
    /// - Throws: EncryptionError if signing fails
    public func createDigitalSignature(
        for data: Data,
        privateKey: SecKey
    ) throws -> Data {
        logger.debug("Creating digital signature")
        
        var error: Unmanaged<CFError>?
        guard let signature = SecKeyCreateSignature(
            privateKey,
            .rsaSignatureMessagePKCS1v15SHA256,
            data as CFData,
            &error
        ) else {
            let errorDescription = error?.takeRetainedValue().localizedDescription ?? "Unknown error"
            throw EncryptionError.signingFailed("Digital signature creation failed: \(errorDescription)")
        }
        
        logger.info("Digital signature created successfully")
        return signature as Data
    }
    
    /// Verifies a digital signature
    /// - Parameters:
    ///   - signature: Digital signature to verify
    ///   - data: Original data
    ///   - publicKey: Public key for verification
    /// - Returns: True if signature is valid
    /// - Throws: EncryptionError if verification fails
    public func verifyDigitalSignature(
        signature: Data,
        for data: Data,
        publicKey: SecKey
    ) throws -> Bool {
        logger.debug("Verifying digital signature")
        
        var error: Unmanaged<CFError>?
        let isValid = SecKeyVerifySignature(
            publicKey,
            .rsaSignatureMessagePKCS1v15SHA256,
            data as CFData,
            signature as CFData,
            &error
        )
        
        if let error = error {
            let errorDescription = error.takeRetainedValue().localizedDescription
            throw EncryptionError.signatureVerificationFailed("Digital signature verification failed: \(errorDescription)")
        }
        
        logger.info("Digital signature verification completed: \(isValid)")
        return isValid
    }
    
    // MARK: - Private Methods
    
    private func setupSecurityEnvironment() {
        logger.debug("Setting up security environment")
        
        // Clear any temporary keys on startup for security
        keyManager.clearTemporaryKeys()
        
        // Validate security configuration
        validateSecurityConfiguration()
        
        logger.info("Security environment setup completed")
    }
    
    private func checkDeviceCapabilities() {
        // Check Secure Enclave availability
        isSecureEnclaveAvailable = LAContext().canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
        
        // Check biometric authentication availability
        isBiometricAuthenticationAvailable = biometricManager.isBiometricAuthenticationAvailable()
        
        logger.info("Device capabilities: Secure Enclave: \(isSecureEnclaveAvailable), Biometrics: \(isBiometricAuthenticationAvailable)")
    }
    
    private func validateSecurityConfiguration() {
        // Validate that required security components are available
        guard keyManager.isAvailable else {
            logger.error("Key manager is not available")
            return
        }
        
        guard secureStorage.isAvailable else {
            logger.error("Secure storage is not available")
            return
        }
        
        logger.info("Security configuration validation passed")
    }
}

// MARK: - Supporting Types

public struct EncryptedData: Codable {
    public let algorithm: EncryptionAlgorithm
    public let encryptedData: Data
    public let nonce: Data
    public let tag: Data
    public let keyId: String
    public let metadata: EncryptionMetadata
    
    public init(
        algorithm: EncryptionAlgorithm,
        encryptedData: Data,
        nonce: Data,
        tag: Data,
        keyId: String,
        metadata: EncryptionMetadata
    ) {
        self.algorithm = algorithm
        self.encryptedData = encryptedData
        self.nonce = nonce
        self.tag = tag
        self.keyId = keyId
        self.metadata = metadata
    }
}

public struct EncryptionMetadata: Codable {
    public let timestamp: Date
    public let version: String
    public let keyDerivationRounds: Int
    
    public init(timestamp: Date, version: String, keyDerivationRounds: Int) {
        self.timestamp = timestamp
        self.version = version
        self.keyDerivationRounds = keyDerivationRounds
    }
}

public enum EncryptionAlgorithm: String, Codable, CaseIterable {
    case aes256GCM = "AES-256-GCM"
    case chaCha20Poly1305 = "ChaCha20-Poly1305"
}

public struct SecureEnclaveKeyReference: Codable {
    public let keyId: String
    public let privateKey: SecKey
    public let requiresBiometry: Bool
    public let createdAt: Date
    
    public init(keyId: String, privateKey: SecKey, requiresBiometry: Bool, createdAt: Date) {
        self.keyId = keyId
        self.privateKey = privateKey
        self.requiresBiometry = requiresBiometry
        self.createdAt = createdAt
    }
    
    // Custom Codable implementation since SecKey is not Codable
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        keyId = try container.decode(String.self, forKey: .keyId)
        requiresBiometry = try container.decode(Bool.self, forKey: .requiresBiometry)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        
        // Retrieve key from Keychain
        let query: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String: keyId.data(using: .utf8)!,
            kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
            kSecReturnRef as String: true
        ]
        
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        
        guard status == errSecSuccess, let key = item as? SecKey else {
            throw EncryptionError.keyNotFound("Secure Enclave key not found: \(keyId)")
        }
        
        privateKey = key
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(keyId, forKey: .keyId)
        try container.encode(requiresBiometry, forKey: .requiresBiometry)
        try container.encode(createdAt, forKey: .createdAt)
    }
    
    private enum CodingKeys: String, CodingKey {
        case keyId, requiresBiometry, createdAt
    }
}

// MARK: - Protocol Definitions

public protocol EncryptionManagerProtocol {
    func encryptAES256GCM(data: Data, key: SymmetricKey?, associatedData: Data?) throws -> EncryptedData
    func decryptAES256GCM(encryptedData: EncryptedData, key: SymmetricKey, associatedData: Data?) throws -> Data
    func encryptChaCha20Poly1305(data: Data, key: SymmetricKey?, associatedData: Data?) throws -> EncryptedData
    func decryptChaCha20Poly1305(encryptedData: EncryptedData, key: SymmetricKey, associatedData: Data?) throws -> Data
    func generateSecureEnclaveKey(keyId: String, requireBiometry: Bool) throws -> SecureEnclaveKeyReference
    func deriveKey(from password: String, salt: Data?, rounds: Int?, keyLength: Int) throws -> (key: SymmetricKey, salt: Data)
    func generateRandomData(length: Int) throws -> Data
}

public protocol KeyManagerProtocol {
    static var shared: KeyManagerProtocol { get }
    var isAvailable: Bool { get }
    func generateAES256Key() -> SymmetricKey
    func generateChaCha20Key() -> SymmetricKey
    func clearTemporaryKeys()
}

public protocol SecureStorageProtocol {
    static var shared: SecureStorageProtocol { get }
    var isAvailable: Bool { get }
    func store<T: Codable>(_ item: T, forKey key: String) throws
    func retrieve<T: Codable>(_ type: T.Type, forKey key: String) throws -> T?
    func delete(forKey key: String) throws
}

public protocol BiometricManagerProtocol {
    static var shared: BiometricManagerProtocol { get }
    func isBiometricAuthenticationAvailable() -> Bool
    func authenticateUser() throws -> Bool
}

// MARK: - Error Types

public enum EncryptionError: LocalizedError {
    case encryptionFailed(String)
    case decryptionFailed(String)
    case algorithmMismatch
    case keyGenerationFailed(String)
    case keyDerivationFailed(String)
    case keyNotFound(String)
    case invalidInput(String)
    case secureEnclaveNotAvailable
    case biometricAuthenticationNotAvailable
    case biometricAuthenticationFailed
    case randomGenerationFailed(String)
    case signingFailed(String)
    case signatureVerificationFailed(String)
    
    public var errorDescription: String? {
        switch self {
        case .encryptionFailed(let message):
            return "Encryption failed: \(message)"
        case .decryptionFailed(let message):
            return "Decryption failed: \(message)"
        case .algorithmMismatch:
            return "Encryption algorithm mismatch"
        case .keyGenerationFailed(let message):
            return "Key generation failed: \(message)"
        case .keyDerivationFailed(let message):
            return "Key derivation failed: \(message)"
        case .keyNotFound(let message):
            return "Key not found: \(message)"
        case .invalidInput(let message):
            return "Invalid input: \(message)"
        case .secureEnclaveNotAvailable:
            return "Secure Enclave is not available on this device"
        case .biometricAuthenticationNotAvailable:
            return "Biometric authentication is not available"
        case .biometricAuthenticationFailed:
            return "Biometric authentication failed"
        case .randomGenerationFailed(let message):
            return "Random data generation failed: \(message)"
        case .signingFailed(let message):
            return "Digital signing failed: \(message)"
        case .signatureVerificationFailed(let message):
            return "Signature verification failed: \(message)"
        }
    }
}

// MARK: - Data Extension

extension Data {
    /// Generates random data of specified length
    static func random(length: Int) -> Data {
        var data = Data(count: length)
        _ = data.withUnsafeMutableBytes { bytes in
            SecRandomCopyBytes(kSecRandomDefault, length, bytes.bindMemory(to: UInt8.self).baseAddress!)
        }
        return data
    }
}

// External dependencies for compilation
import CommonCrypto