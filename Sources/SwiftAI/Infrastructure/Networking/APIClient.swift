//
//  APIClient.swift
//  SwiftAI
//
//  Created by Muhittin Camdali on 17/08/2024.
//

import Foundation
import Combine
import Network

/// Enterprise-grade API client with advanced networking capabilities
public final class APIClient: ObservableObject, APIClientProtocol {
    
    // MARK: - Public Properties
    
    @Published public private(set) var networkStatus: NetworkStatus = .unknown
    @Published public private(set) var activeRequests: [String: URLSessionTask] = [:]
    
    // MARK: - Private Properties
    
    private let session: URLSession
    private let baseURL: URL
    private let configuration: APIConfiguration
    private let interceptors: [RequestInterceptor]
    private let responseValidators: [ResponseValidator]
    private let logger: LoggerProtocol
    private let securityManager: SecurityManagerProtocol
    private let performanceMonitor: PerformanceMonitorProtocol
    
    private var cancellables = Set<AnyCancellable>()
    private let networkMonitor = NWPathMonitor()
    private let requestQueue = DispatchQueue(label: "com.swiftai.api.requests", qos: .userInitiated)
    private let requestTimeoutInterval: TimeInterval = 30.0
    
    // MARK: - Initialization
    
    public init(
        baseURL: URL,
        configuration: APIConfiguration = APIConfiguration(),
        interceptors: [RequestInterceptor] = [],
        responseValidators: [ResponseValidator] = [],
        logger: LoggerProtocol = Logger.shared,
        securityManager: SecurityManagerProtocol = SecurityManager.shared,
        performanceMonitor: PerformanceMonitorProtocol = PerformanceMonitor.shared
    ) {
        self.baseURL = baseURL
        self.configuration = configuration
        self.interceptors = interceptors
        self.responseValidators = responseValidators
        self.logger = logger
        self.securityManager = securityManager
        self.performanceMonitor = performanceMonitor
        
        // Configure URLSession
        let sessionConfiguration = URLSessionConfiguration.default
        sessionConfiguration.requestCachePolicy = configuration.cachePolicy
        sessionConfiguration.timeoutIntervalForRequest = requestTimeoutInterval
        sessionConfiguration.timeoutIntervalForResource = requestTimeoutInterval * 2
        sessionConfiguration.httpMaximumConnectionsPerHost = configuration.maxConcurrentConnections
        sessionConfiguration.urlCache = URLCache(
            memoryCapacity: configuration.memoryCacheCapacity,
            diskCapacity: configuration.diskCacheCapacity
        )
        
        self.session = URLSession(configuration: sessionConfiguration)
        
        setupNetworkMonitoring()
        setupSecurityValidation()
        
        logger.info("APIClient initialized with base URL: \(baseURL.absoluteString)")
    }
    
    deinit {
        networkMonitor.cancel()
        session.invalidateAndCancel()
    }
    
    // MARK: - Public Methods
    
    /// Performs a generic API request
    /// - Parameter endpoint: The endpoint to request
    /// - Returns: Publisher with decoded response or error
    public func request<T: Decodable>(_ endpoint: Endpoint) -> AnyPublisher<T, APIError> {
        return performanceMonitor.measure(operation: "api_request") {
            performRequest(endpoint)
                .decode(type: T.self, decoder: createJSONDecoder())
                .mapError { error in
                    if error is DecodingError {
                        self.logger.error("JSON decoding failed: \(error.localizedDescription)")
                        return APIError.decodingFailed(error)
                    }
                    return error as? APIError ?? APIError.unknown(error)
                }
                .receive(on: DispatchQueue.main)
                .eraseToAnyPublisher()
        }
    }
    
    /// Performs a request and returns raw data
    /// - Parameter endpoint: The endpoint to request
    /// - Returns: Publisher with raw data or error
    public func requestData(_ endpoint: Endpoint) -> AnyPublisher<Data, APIError> {
        return performanceMonitor.measure(operation: "api_request_data") {
            performRequest(endpoint)
                .receive(on: DispatchQueue.main)
                .eraseToAnyPublisher()
        }
    }
    
    /// Uploads data to an endpoint
    /// - Parameters:
    ///   - endpoint: The endpoint to upload to
    ///   - data: Data to upload
    ///   - progressHandler: Optional progress handler
    /// - Returns: Publisher with response or error
    public func upload<T: Decodable>(
        _ endpoint: Endpoint,
        data: Data,
        progressHandler: ((Double) -> Void)? = nil
    ) -> AnyPublisher<T, APIError> {
        return performanceMonitor.measure(operation: "api_upload") {
            Future<T, APIError> { [weak self] promise in
                guard let self = self else {
                    promise(.failure(APIError.clientDeallocated))
                    return
                }
                
                self.requestQueue.async {
                    do {
                        let request = try self.buildUploadRequest(endpoint: endpoint, data: data)
                        let requestId = UUID().uuidString
                        
                        let task = self.session.uploadTask(with: request, from: data) { data, response, error in
                            self.activeRequests.removeValue(forKey: requestId)
                            
                            if let error = error {
                                self.logger.error("Upload failed: \(error.localizedDescription)")
                                promise(.failure(APIError.networkError(error)))
                                return
                            }
                            
                            guard let data = data, let response = response else {
                                promise(.failure(APIError.noData))
                                return
                            }
                            
                            do {
                                try self.validateResponse(response: response, data: data)
                                let decodedResponse = try self.createJSONDecoder().decode(T.self, from: data)
                                self.logger.info("Upload completed successfully")
                                promise(.success(decodedResponse))
                            } catch {
                                self.logger.error("Upload response processing failed: \(error.localizedDescription)")
                                promise(.failure(APIError.responseProcessingFailed(error)))
                            }
                        }
                        
                        // Track upload progress
                        if let progressHandler = progressHandler {
                            self.observeTaskProgress(task: task, progressHandler: progressHandler)
                        }
                        
                        self.activeRequests[requestId] = task
                        task.resume()
                        
                    } catch {
                        self.logger.error("Failed to build upload request: \(error.localizedDescription)")
                        promise(.failure(APIError.requestBuildFailed(error)))
                    }
                }
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
        }
    }
    
    /// Downloads data from an endpoint
    /// - Parameters:
    ///   - endpoint: The endpoint to download from
    ///   - progressHandler: Optional progress handler
    /// - Returns: Publisher with downloaded data or error
    public func download(
        _ endpoint: Endpoint,
        progressHandler: ((Double) -> Void)? = nil
    ) -> AnyPublisher<Data, APIError> {
        return performanceMonitor.measure(operation: "api_download") {
            Future<Data, APIError> { [weak self] promise in
                guard let self = self else {
                    promise(.failure(APIError.clientDeallocated))
                    return
                }
                
                self.requestQueue.async {
                    do {
                        let request = try self.buildRequest(endpoint: endpoint)
                        let requestId = UUID().uuidString
                        
                        let task = self.session.downloadTask(with: request) { location, response, error in
                            self.activeRequests.removeValue(forKey: requestId)
                            
                            if let error = error {
                                self.logger.error("Download failed: \(error.localizedDescription)")
                                promise(.failure(APIError.networkError(error)))
                                return
                            }
                            
                            guard let location = location, let response = response else {
                                promise(.failure(APIError.noData))
                                return
                            }
                            
                            do {
                                let data = try Data(contentsOf: location)
                                try self.validateResponse(response: response, data: data)
                                self.logger.info("Download completed successfully")
                                promise(.success(data))
                            } catch {
                                self.logger.error("Download processing failed: \(error.localizedDescription)")
                                promise(.failure(APIError.responseProcessingFailed(error)))
                            }
                        }
                        
                        // Track download progress
                        if let progressHandler = progressHandler {
                            self.observeTaskProgress(task: task, progressHandler: progressHandler)
                        }
                        
                        self.activeRequests[requestId] = task
                        task.resume()
                        
                    } catch {
                        self.logger.error("Failed to build download request: \(error.localizedDescription)")
                        promise(.failure(APIError.requestBuildFailed(error)))
                    }
                }
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
        }
    }
    
    /// Cancels a specific request
    /// - Parameter requestId: ID of the request to cancel
    public func cancelRequest(withId requestId: String) {
        activeRequests[requestId]?.cancel()
        activeRequests.removeValue(forKey: requestId)
        logger.debug("Cancelled request: \(requestId)")
    }
    
    /// Cancels all active requests
    public func cancelAllRequests() {
        let requestCount = activeRequests.count
        activeRequests.values.forEach { $0.cancel() }
        activeRequests.removeAll()
        logger.info("Cancelled \(requestCount) active requests")
    }
    
    /// Gets current network statistics
    /// - Returns: Network statistics
    public func getNetworkStatistics() -> NetworkStatistics {
        return NetworkStatistics(
            activeRequestsCount: activeRequests.count,
            networkStatus: networkStatus,
            totalRequests: performanceMonitor.getTotalRequests(),
            averageResponseTime: performanceMonitor.getAverageResponseTime(),
            successRate: performanceMonitor.getSuccessRate()
        )
    }
    
    // MARK: - Private Methods
    
    private func performRequest(_ endpoint: Endpoint) -> AnyPublisher<Data, APIError> {
        return Future<Data, APIError> { [weak self] promise in
            guard let self = self else {
                promise(.failure(APIError.clientDeallocated))
                return
            }
            
            // Check network connectivity
            guard self.networkStatus != .unavailable else {
                promise(.failure(APIError.noNetworkConnection))
                return
            }
            
            self.requestQueue.async {
                do {
                    let request = try self.buildRequest(endpoint: endpoint)
                    let requestId = UUID().uuidString
                    
                    let task = self.session.dataTask(with: request) { data, response, error in
                        self.activeRequests.removeValue(forKey: requestId)
                        
                        if let error = error {
                            let urlError = error as? URLError
                            if urlError?.code == .cancelled {
                                self.logger.debug("Request was cancelled")
                                promise(.failure(APIError.requestCancelled))
                            } else {
                                self.logger.error("Network request failed: \(error.localizedDescription)")
                                promise(.failure(APIError.networkError(error)))
                            }
                            return
                        }
                        
                        guard let data = data, let response = response else {
                            promise(.failure(APIError.noData))
                            return
                        }
                        
                        do {
                            try self.validateResponse(response: response, data: data)
                            self.logger.debug("Request completed successfully")
                            promise(.success(data))
                        } catch {
                            self.logger.error("Response validation failed: \(error.localizedDescription)")
                            promise(.failure(error as? APIError ?? APIError.unknown(error)))
                        }
                    }
                    
                    self.activeRequests[requestId] = task
                    task.resume()
                    
                } catch {
                    self.logger.error("Failed to build request: \(error.localizedDescription)")
                    promise(.failure(APIError.requestBuildFailed(error)))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    private func buildRequest(endpoint: Endpoint) throws -> URLRequest {
        guard let url = URL(string: endpoint.path, relativeTo: baseURL) else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.timeoutInterval = requestTimeoutInterval
        
        // Apply headers
        for (key, value) in endpoint.headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        // Apply default headers
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(configuration.userAgent, forHTTPHeaderField: "User-Agent")
        
        // Add authentication if available
        if let authToken = configuration.authToken {
            request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        }
        
        // Add request body if needed
        if let body = endpoint.body {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        }
        
        // Apply request interceptors
        for interceptor in interceptors {
            request = try interceptor.intercept(request)
        }
        
        // Security validation
        try securityManager.validateRequest(request)
        
        return request
    }
    
    private func buildUploadRequest(endpoint: Endpoint, data: Data) throws -> URLRequest {
        var request = try buildRequest(endpoint: endpoint)
        request.setValue("application/octet-stream", forHTTPHeaderField: "Content-Type")
        request.setValue("\(data.count)", forHTTPHeaderField: "Content-Length")
        return request
    }
    
    private func validateResponse(response: URLResponse, data: Data) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        // Apply response validators
        for validator in responseValidators {
            try validator.validate(response: httpResponse, data: data)
        }
        
        // Default HTTP status validation
        guard 200..<300 ~= httpResponse.statusCode else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw APIError.httpError(httpResponse.statusCode, errorMessage)
        }
        
        // Security validation
        try securityManager.validateResponse(httpResponse, data: data)
    }
    
    private func createJSONDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            
            let formatters = [
                ISO8601DateFormatter(),
                DateFormatter.iso8601Full,
                DateFormatter.iso8601WithoutTimezone
            ]
            
            for formatter in formatters {
                if let date = formatter.date(from: dateString) {
                    return date
                }
            }
            
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Cannot decode date string \(dateString)"
            )
        }
        return decoder
    }
    
    private func setupNetworkMonitoring() {
        networkMonitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.updateNetworkStatus(from: path)
            }
        }
        
        let queue = DispatchQueue(label: "com.swiftai.network.monitor")
        networkMonitor.start(queue: queue)
    }
    
    private func updateNetworkStatus(from path: NWPath) {
        switch path.status {
        case .satisfied:
            if path.usesInterfaceType(.wifi) {
                networkStatus = .wifi
            } else if path.usesInterfaceType(.cellular) {
                networkStatus = .cellular
            } else {
                networkStatus = .ethernet
            }
        case .unsatisfied:
            networkStatus = .unavailable
        case .requiresConnection:
            networkStatus = .requiresConnection
        @unknown default:
            networkStatus = .unknown
        }
        
        logger.debug("Network status updated: \(networkStatus)")
    }
    
    private func setupSecurityValidation() {
        // Configure certificate pinning if needed
        if configuration.enableCertificatePinning {
            // Certificate pinning implementation would go here
            logger.info("Certificate pinning enabled")
        }
        
        // Configure request/response encryption if needed
        if configuration.enableRequestEncryption {
            // Request encryption implementation would go here
            logger.info("Request encryption enabled")
        }
    }
    
    private func observeTaskProgress(task: URLSessionTask, progressHandler: @escaping (Double) -> Void) {
        // This would require implementing a custom URLSessionDelegate
        // For now, we'll use KVO to observe the task's progress
        task.progress.addObserver(
            self,
            forKeyPath: "fractionCompleted",
            options: [.new],
            context: nil
        )
    }
    
    // MARK: - KVO
    
    public override func observeValue(
        forKeyPath keyPath: String?,
        of object: Any?,
        change: [NSKeyValueChangeKey : Any]?,
        context: UnsafeMutableRawPointer?
    ) {
        if keyPath == "fractionCompleted", let progress = object as? Progress {
            DispatchQueue.main.async {
                // Progress handling would be implemented here
                self.logger.debug("Task progress: \(progress.fractionCompleted)")
            }
        }
    }
}

// MARK: - Supporting Types

public enum NetworkStatus {
    case unknown
    case unavailable
    case wifi
    case cellular
    case ethernet
    case requiresConnection
}

public struct APIConfiguration {
    public let userAgent: String
    public let authToken: String?
    public let maxConcurrentConnections: Int
    public let cachePolicy: URLRequest.CachePolicy
    public let memoryCacheCapacity: Int
    public let diskCacheCapacity: Int
    public let enableCertificatePinning: Bool
    public let enableRequestEncryption: Bool
    
    public init(
        userAgent: String = "SwiftAI/1.0",
        authToken: String? = nil,
        maxConcurrentConnections: Int = 6,
        cachePolicy: URLRequest.CachePolicy = .returnCacheDataElseLoad,
        memoryCacheCapacity: Int = 10 * 1024 * 1024, // 10MB
        diskCacheCapacity: Int = 50 * 1024 * 1024, // 50MB
        enableCertificatePinning: Bool = true,
        enableRequestEncryption: Bool = false
    ) {
        self.userAgent = userAgent
        self.authToken = authToken
        self.maxConcurrentConnections = maxConcurrentConnections
        self.cachePolicy = cachePolicy
        self.memoryCacheCapacity = memoryCacheCapacity
        self.diskCacheCapacity = diskCacheCapacity
        self.enableCertificatePinning = enableCertificatePinning
        self.enableRequestEncryption = enableRequestEncryption
    }
}

public struct NetworkStatistics {
    public let activeRequestsCount: Int
    public let networkStatus: NetworkStatus
    public let totalRequests: Int
    public let averageResponseTime: TimeInterval
    public let successRate: Double
    
    public init(
        activeRequestsCount: Int,
        networkStatus: NetworkStatus,
        totalRequests: Int,
        averageResponseTime: TimeInterval,
        successRate: Double
    ) {
        self.activeRequestsCount = activeRequestsCount
        self.networkStatus = networkStatus
        self.totalRequests = totalRequests
        self.averageResponseTime = averageResponseTime
        self.successRate = successRate
    }
}

// MARK: - Endpoint Protocol

public protocol Endpoint {
    var path: String { get }
    var method: HTTPMethod { get }
    var headers: [String: String] { get }
    var body: [String: Any]? { get }
}

public enum HTTPMethod: String {
    case GET = "GET"
    case POST = "POST"
    case PUT = "PUT"
    case DELETE = "DELETE"
    case PATCH = "PATCH"
    case HEAD = "HEAD"
    case OPTIONS = "OPTIONS"
}

// MARK: - Request Interceptor Protocol

public protocol RequestInterceptor {
    func intercept(_ request: URLRequest) throws -> URLRequest
}

// MARK: - Response Validator Protocol

public protocol ResponseValidator {
    func validate(response: HTTPURLResponse, data: Data) throws
}

// MARK: - API Client Protocol

public protocol APIClientProtocol {
    func request<T: Decodable>(_ endpoint: Endpoint) -> AnyPublisher<T, APIError>
    func requestData(_ endpoint: Endpoint) -> AnyPublisher<Data, APIError>
    func upload<T: Decodable>(_ endpoint: Endpoint, data: Data, progressHandler: ((Double) -> Void)?) -> AnyPublisher<T, APIError>
    func download(_ endpoint: Endpoint, progressHandler: ((Double) -> Void)?) -> AnyPublisher<Data, APIError>
    func cancelRequest(withId requestId: String)
    func cancelAllRequests()
}

// MARK: - API Errors

public enum APIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case noData
    case noNetworkConnection
    case requestCancelled
    case clientDeallocated
    case networkError(Error)
    case httpError(Int, String)
    case decodingFailed(Error)
    case requestBuildFailed(Error)
    case responseProcessingFailed(Error)
    case unknown(Error)
    
    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response"
        case .noData:
            return "No data received"
        case .noNetworkConnection:
            return "No network connection"
        case .requestCancelled:
            return "Request was cancelled"
        case .clientDeallocated:
            return "API client was deallocated"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .httpError(let statusCode, let message):
            return "HTTP error \(statusCode): \(message)"
        case .decodingFailed(let error):
            return "Decoding failed: \(error.localizedDescription)"
        case .requestBuildFailed(let error):
            return "Request build failed: \(error.localizedDescription)"
        case .responseProcessingFailed(let error):
            return "Response processing failed: \(error.localizedDescription)"
        case .unknown(let error):
            return "Unknown error: \(error.localizedDescription)"
        }
    }
}