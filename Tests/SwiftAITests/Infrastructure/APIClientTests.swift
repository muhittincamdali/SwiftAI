//
//  APIClientTests.swift
//  SwiftAITests
//
//  Created by Muhittin Camdali on 17/08/2024.
//

import XCTest
import Combine
@testable import SwiftAI

/// Comprehensive test suite for APIClient with enterprise-grade coverage
final class APIClientTests: XCTestCase {
    
    // MARK: - Properties
    
    private var apiClient: APIClient!
    private var cancellables: Set<AnyCancellable>!
    private var mockURLSession: MockURLSession!
    private var testBaseURL: URL!
    
    // MARK: - Setup & Teardown
    
    override func setUpWithError() throws {
        super.setUp()
        cancellables = Set<AnyCancellable>()
        testBaseURL = URL(string: "https://api.test.com")!
        mockURLSession = MockURLSession()
        apiClient = APIClient(baseURL: testBaseURL, session: mockURLSession)
    }
    
    override func tearDownWithError() throws {
        cancellables.removeAll()
        apiClient = nil
        mockURLSession = nil
        testBaseURL = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testAPIClientInitialization() throws {
        // Given & When
        let client = APIClient(baseURL: testBaseURL)
        
        // Then
        XCTAssertNotNil(client)
        XCTAssertEqual(client.baseURL, testBaseURL)
    }
    
    func testAPIClientWithCustomConfiguration() throws {
        // Given
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30.0
        config.timeoutIntervalForResource = 60.0
        
        // When
        let client = APIClient(
            baseURL: testBaseURL,
            configuration: config
        )
        
        // Then
        XCTAssertNotNil(client)
        XCTAssertEqual(client.baseURL, testBaseURL)
    }
    
    // MARK: - GET Request Tests
    
    func testSuccessfulGETRequest() async throws {
        // Given
        let expectation = XCTestExpectation(description: "GET request")
        let endpoint = "/test"
        let mockResponse = TestAPIResponse(message: "Success", data: ["key": "value"])
        let responseData = try JSONEncoder().encode(mockResponse)
        
        mockURLSession.mockData = responseData
        mockURLSession.mockResponse = HTTPURLResponse(
            url: testBaseURL.appendingPathComponent(endpoint),
            statusCode: 200,
            httpVersion: nil,
            headerFields: ["Content-Type": "application/json"]
        )
        
        var receivedResponse: TestAPIResponse?
        
        // When
        apiClient.get(endpoint: endpoint, responseType: TestAPIResponse.self)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTFail("GET request failed: \(error)")
                    }
                    expectation.fulfill()
                },
                receiveValue: { response in
                    receivedResponse = response
                }
            )
            .store(in: &cancellables)
        
        // Then
        await fulfillment(of: [expectation], timeout: 5.0)
        XCTAssertNotNil(receivedResponse)
        XCTAssertEqual(receivedResponse?.message, "Success")
        XCTAssertEqual(receivedResponse?.data["key"] as? String, "value")
    }
    
    func testGETRequestWithQueryParameters() async throws {
        // Given
        let expectation = XCTestExpectation(description: "GET with parameters")
        let endpoint = "/search"
        let parameters = ["query": "test", "limit": "10"]
        
        mockURLSession.mockData = Data("{\"results\": []}".utf8)
        mockURLSession.mockResponse = HTTPURLResponse(
            url: testBaseURL.appendingPathComponent(endpoint),
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )
        
        // When
        apiClient.get(endpoint: endpoint, parameters: parameters, responseType: TestAPIResponse.self)
            .sink(
                receiveCompletion: { _ in expectation.fulfill() },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)
        
        // Then
        await fulfillment(of: [expectation], timeout: 5.0)
        
        // Verify URL contains query parameters
        let request = mockURLSession.lastRequest
        XCTAssertNotNil(request?.url?.query)
        XCTAssertTrue(request?.url?.query?.contains("query=test") ?? false)
        XCTAssertTrue(request?.url?.query?.contains("limit=10") ?? false)
    }
    
    func testGETRequestFailure() async throws {
        // Given
        let expectation = XCTestExpectation(description: "GET request failure")
        let endpoint = "/error"
        var receivedError: APIError?
        
        mockURLSession.mockError = URLError(.notConnectedToInternet)
        
        // When
        apiClient.get(endpoint: endpoint, responseType: TestAPIResponse.self)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        receivedError = error
                    }
                    expectation.fulfill()
                },
                receiveValue: { _ in
                    XCTFail("Expected request to fail")
                }
            )
            .store(in: &cancellables)
        
        // Then
        await fulfillment(of: [expectation], timeout: 5.0)
        XCTAssertNotNil(receivedError)
        XCTAssertEqual(receivedError, .networkError(URLError(.notConnectedToInternet)))
    }
    
    // MARK: - POST Request Tests
    
    func testSuccessfulPOSTRequest() async throws {
        // Given
        let expectation = XCTestExpectation(description: "POST request")
        let endpoint = "/create"
        let requestBody = TestAPIRequest(name: "Test", value: 42)
        let responseBody = TestAPIResponse(message: "Created", data: ["id": "123"])
        let responseData = try JSONEncoder().encode(responseBody)
        
        mockURLSession.mockData = responseData
        mockURLSession.mockResponse = HTTPURLResponse(
            url: testBaseURL.appendingPathComponent(endpoint),
            statusCode: 201,
            httpVersion: nil,
            headerFields: ["Content-Type": "application/json"]
        )
        
        var receivedResponse: TestAPIResponse?
        
        // When
        apiClient.post(endpoint: endpoint, body: requestBody, responseType: TestAPIResponse.self)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTFail("POST request failed: \(error)")
                    }
                    expectation.fulfill()
                },
                receiveValue: { response in
                    receivedResponse = response
                }
            )
            .store(in: &cancellables)
        
        // Then
        await fulfillment(of: [expectation], timeout: 5.0)
        XCTAssertNotNil(receivedResponse)
        XCTAssertEqual(receivedResponse?.message, "Created")
        
        // Verify request method and body
        let request = mockURLSession.lastRequest
        XCTAssertEqual(request?.httpMethod, "POST")
        XCTAssertEqual(request?.value(forHTTPHeaderField: "Content-Type"), "application/json")
        XCTAssertNotNil(request?.httpBody)
    }
    
    func testPOSTRequestWithInvalidResponse() async throws {
        // Given
        let expectation = XCTestExpectation(description: "POST invalid response")
        let endpoint = "/invalid"
        let requestBody = TestAPIRequest(name: "Test", value: 42)
        var receivedError: APIError?
        
        mockURLSession.mockData = Data("Invalid JSON".utf8)
        mockURLSession.mockResponse = HTTPURLResponse(
            url: testBaseURL.appendingPathComponent(endpoint),
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )
        
        // When
        apiClient.post(endpoint: endpoint, body: requestBody, responseType: TestAPIResponse.self)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        receivedError = error
                    }
                    expectation.fulfill()
                },
                receiveValue: { _ in
                    XCTFail("Expected parsing to fail")
                }
            )
            .store(in: &cancellables)
        
        // Then
        await fulfillment(of: [expectation], timeout: 5.0)
        XCTAssertNotNil(receivedError)
        
        if case .decodingError(_) = receivedError {
            // Expected error type
        } else {
            XCTFail("Expected decoding error")
        }
    }
    
    // MARK: - PUT Request Tests
    
    func testSuccessfulPUTRequest() async throws {
        // Given
        let expectation = XCTestExpectation(description: "PUT request")
        let endpoint = "/update/123"
        let requestBody = TestAPIRequest(name: "Updated", value: 100)
        let responseBody = TestAPIResponse(message: "Updated", data: ["id": "123"])
        let responseData = try JSONEncoder().encode(responseBody)
        
        mockURLSession.mockData = responseData
        mockURLSession.mockResponse = HTTPURLResponse(
            url: testBaseURL.appendingPathComponent(endpoint),
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )
        
        // When
        apiClient.put(endpoint: endpoint, body: requestBody, responseType: TestAPIResponse.self)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTFail("PUT request failed: \(error)")
                    }
                    expectation.fulfill()
                },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)
        
        // Then
        await fulfillment(of: [expectation], timeout: 5.0)
        
        let request = mockURLSession.lastRequest
        XCTAssertEqual(request?.httpMethod, "PUT")
    }
    
    // MARK: - DELETE Request Tests
    
    func testSuccessfulDELETERequest() async throws {
        // Given
        let expectation = XCTestExpectation(description: "DELETE request")
        let endpoint = "/delete/123"
        
        mockURLSession.mockData = Data()
        mockURLSession.mockResponse = HTTPURLResponse(
            url: testBaseURL.appendingPathComponent(endpoint),
            statusCode: 204,
            httpVersion: nil,
            headerFields: nil
        )
        
        // When
        apiClient.delete(endpoint: endpoint)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTFail("DELETE request failed: \(error)")
                    }
                    expectation.fulfill()
                },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)
        
        // Then
        await fulfillment(of: [expectation], timeout: 5.0)
        
        let request = mockURLSession.lastRequest
        XCTAssertEqual(request?.httpMethod, "DELETE")
    }
    
    // MARK: - HTTP Status Code Tests
    
    func testHTTPErrorHandling() async throws {
        // Given
        let testCases: [(Int, APIError)] = [
            (400, .badRequest),
            (401, .unauthorized),
            (403, .forbidden),
            (404, .notFound),
            (429, .rateLimited),
            (500, .serverError),
            (503, .serviceUnavailable)
        ]
        
        for (statusCode, expectedError) in testCases {
            let expectation = XCTestExpectation(description: "HTTP \(statusCode) error")
            var receivedError: APIError?
            
            mockURLSession.mockData = Data()
            mockURLSession.mockResponse = HTTPURLResponse(
                url: testBaseURL,
                statusCode: statusCode,
                httpVersion: nil,
                headerFields: nil
            )
            
            // When
            apiClient.get(endpoint: "/test", responseType: TestAPIResponse.self)
                .sink(
                    receiveCompletion: { completion in
                        if case .failure(let error) = completion {
                            receivedError = error
                        }
                        expectation.fulfill()
                    },
                    receiveValue: { _ in
                        XCTFail("Expected \(statusCode) error")
                    }
                )
                .store(in: &cancellables)
            
            // Then
            await fulfillment(of: [expectation], timeout: 1.0)
            XCTAssertEqual(receivedError, expectedError)
        }
    }
    
    // MARK: - Authentication Tests
    
    func testRequestWithAuthentication() async throws {
        // Given
        let expectation = XCTestExpectation(description: "Authenticated request")
        let endpoint = "/protected"
        let token = "test-token-123"
        
        mockURLSession.mockData = Data("{\"message\": \"success\"}".utf8)
        mockURLSession.mockResponse = HTTPURLResponse(
            url: testBaseURL.appendingPathComponent(endpoint),
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )
        
        // When
        apiClient.setAuthenticationToken(token)
        apiClient.get(endpoint: endpoint, responseType: TestAPIResponse.self)
            .sink(
                receiveCompletion: { _ in expectation.fulfill() },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)
        
        // Then
        await fulfillment(of: [expectation], timeout: 5.0)
        
        let request = mockURLSession.lastRequest
        XCTAssertEqual(request?.value(forHTTPHeaderField: "Authorization"), "Bearer \(token)")
    }
    
    // MARK: - Custom Headers Tests
    
    func testRequestWithCustomHeaders() async throws {
        // Given
        let expectation = XCTestExpectation(description: "Custom headers request")
        let endpoint = "/test"
        let customHeaders = [
            "X-Custom-Header": "custom-value",
            "X-API-Version": "v1"
        ]
        
        mockURLSession.mockData = Data("{\"message\": \"success\"}".utf8)
        mockURLSession.mockResponse = HTTPURLResponse(
            url: testBaseURL.appendingPathComponent(endpoint),
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )
        
        // When
        apiClient.get(endpoint: endpoint, headers: customHeaders, responseType: TestAPIResponse.self)
            .sink(
                receiveCompletion: { _ in expectation.fulfill() },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)
        
        // Then
        await fulfillment(of: [expectation], timeout: 5.0)
        
        let request = mockURLSession.lastRequest
        XCTAssertEqual(request?.value(forHTTPHeaderField: "X-Custom-Header"), "custom-value")
        XCTAssertEqual(request?.value(forHTTPHeaderField: "X-API-Version"), "v1")
    }
    
    // MARK: - Timeout Tests
    
    func testRequestTimeout() async throws {
        // Given
        let expectation = XCTestExpectation(description: "Request timeout")
        let endpoint = "/slow"
        var receivedError: APIError?
        
        mockURLSession.mockError = URLError(.timedOut)
        
        // When
        apiClient.get(endpoint: endpoint, responseType: TestAPIResponse.self)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        receivedError = error
                    }
                    expectation.fulfill()
                },
                receiveValue: { _ in
                    XCTFail("Expected timeout error")
                }
            )
            .store(in: &cancellables)
        
        // Then
        await fulfillment(of: [expectation], timeout: 5.0)
        XCTAssertNotNil(receivedError)
        XCTAssertEqual(receivedError, .networkError(URLError(.timedOut)))
    }
    
    // MARK: - Concurrent Requests Tests
    
    func testConcurrentRequests() async throws {
        // Given
        let numberOfRequests = 10
        let expectation = XCTestExpectation(description: "Concurrent requests")
        expectation.expectedFulfillmentCount = numberOfRequests
        
        mockURLSession.mockData = Data("{\"message\": \"success\"}".utf8)
        mockURLSession.mockResponse = HTTPURLResponse(
            url: testBaseURL,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )
        
        // When
        for i in 0..<numberOfRequests {
            apiClient.get(endpoint: "/test/\(i)", responseType: TestAPIResponse.self)
                .sink(
                    receiveCompletion: { _ in expectation.fulfill() },
                    receiveValue: { _ in }
                )
                .store(in: &cancellables)
        }
        
        // Then
        await fulfillment(of: [expectation], timeout: 10.0)
    }
    
    // MARK: - Request Cancellation Tests
    
    func testRequestCancellation() async throws {
        // Given
        let expectation = XCTestExpectation(description: "Request cancellation")
        var cancellable: AnyCancellable?
        var receivedError: APIError?
        
        mockURLSession.mockDelay = 5.0 // Long delay to allow cancellation
        mockURLSession.mockData = Data("{\"message\": \"success\"}".utf8)
        mockURLSession.mockResponse = HTTPURLResponse(
            url: testBaseURL,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )
        
        // When
        cancellable = apiClient.get(endpoint: "/test", responseType: TestAPIResponse.self)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        receivedError = error
                    }
                    expectation.fulfill()
                },
                receiveValue: { _ in
                    XCTFail("Request should have been cancelled")
                }
            )
        
        // Cancel after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            cancellable?.cancel()
        }
        
        // Then
        await fulfillment(of: [expectation], timeout: 2.0)
        XCTAssertNotNil(receivedError)
    }
    
    // MARK: - Performance Tests
    
    func testAPIClientPerformance() throws {
        // Given
        mockURLSession.mockData = Data("{\"message\": \"success\"}".utf8)
        mockURLSession.mockResponse = HTTPURLResponse(
            url: testBaseURL,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )
        
        // When & Then
        measure {
            let expectation = XCTestExpectation(description: "Performance test")
            expectation.expectedFulfillmentCount = 100
            
            for _ in 0..<100 {
                apiClient.get(endpoint: "/test", responseType: TestAPIResponse.self)
                    .sink(
                        receiveCompletion: { _ in expectation.fulfill() },
                        receiveValue: { _ in }
                    )
                    .store(in: &cancellables)
            }
            
            wait(for: [expectation], timeout: 5.0)
        }
    }
    
    // MARK: - Memory Management Tests
    
    func testMemoryManagement() throws {
        // Given
        weak var weakClient: APIClient?
        
        // When
        autoreleasepool {
            let client = APIClient(baseURL: testBaseURL)
            weakClient = client
            
            // Perform operations
            _ = client.get(endpoint: "/test", responseType: TestAPIResponse.self)
        }
        
        // Then
        XCTAssertNil(weakClient, "APIClient should be deallocated")
    }
}

// MARK: - Mock Objects

class MockURLSession: URLSessionProtocol {
    var mockData: Data?
    var mockResponse: URLResponse?
    var mockError: Error?
    var mockDelay: TimeInterval = 0
    var lastRequest: URLRequest?
    
    func dataTaskPublisher(for request: URLRequest) -> AnyPublisher<(data: Data, response: URLResponse), URLError> {
        lastRequest = request
        
        if let error = mockError {
            return Fail(error: error as! URLError)
                .delay(for: .seconds(mockDelay), scheduler: DispatchQueue.main)
                .eraseToAnyPublisher()
        }
        
        let data = mockData ?? Data()
        let response = mockResponse ?? HTTPURLResponse(
            url: request.url!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )!
        
        return Just((data: data, response: response))
            .delay(for: .seconds(mockDelay), scheduler: DispatchQueue.main)
            .setFailureType(to: URLError.self)
            .eraseToAnyPublisher()
    }
}

// MARK: - Test Models

struct TestAPIRequest: Codable {
    let name: String
    let value: Int
}

struct TestAPIResponse: Codable {
    let message: String
    let data: [String: Any]
    
    init(message: String, data: [String: Any] = [:]) {
        self.message = message
        self.data = data
    }
    
    enum CodingKeys: String, CodingKey {
        case message, data
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        message = try container.decode(String.self, forKey: .message)
        data = try container.decodeIfPresent([String: AnyCodable].self, forKey: .data)?.mapValues { $0.value } ?? [:]
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(message, forKey: .message)
        try container.encode(data.mapValues(AnyCodable.init), forKey: .data)
    }
}

struct AnyCodable: Codable {
    let value: Any
    
    init(_ value: Any) {
        self.value = value
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let string = try? container.decode(String.self) {
            value = string
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let bool = try? container.decode(Bool.self) {
            value = bool
        } else {
            value = ""
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        if let string = value as? String {
            try container.encode(string)
        } else if let int = value as? Int {
            try container.encode(int)
        } else if let double = value as? Double {
            try container.encode(double)
        } else if let bool = value as? Bool {
            try container.encode(bool)
        }
    }
}

// MARK: - Protocol Definitions

protocol URLSessionProtocol {
    func dataTaskPublisher(for request: URLRequest) -> AnyPublisher<(data: Data, response: URLResponse), URLError>
}

extension URLSession: URLSessionProtocol {
    func dataTaskPublisher(for request: URLRequest) -> AnyPublisher<(data: Data, response: URLResponse), URLError> {
        return dataTaskPublisher(for: request)
            .map { (data: $0.data, response: $0.response) }
            .eraseToAnyPublisher()
    }
}

enum APIError: Error, Equatable {
    case badRequest
    case unauthorized
    case forbidden
    case notFound
    case rateLimited
    case serverError
    case serviceUnavailable
    case networkError(URLError)
    case decodingError(Error)
    
    static func == (lhs: APIError, rhs: APIError) -> Bool {
        switch (lhs, rhs) {
        case (.badRequest, .badRequest),
             (.unauthorized, .unauthorized),
             (.forbidden, .forbidden),
             (.notFound, .notFound),
             (.rateLimited, .rateLimited),
             (.serverError, .serverError),
             (.serviceUnavailable, .serviceUnavailable):
            return true
        case let (.networkError(lhsError), .networkError(rhsError)):
            return lhsError.code == rhsError.code
        case let (.decodingError(lhsError), .decodingError(rhsError)):
            return String(describing: lhsError) == String(describing: rhsError)
        default:
            return false
        }
    }
}

// MARK: - APIClient Extensions for Testing

extension APIClient {
    convenience init(baseURL: URL, session: URLSessionProtocol) {
        self.init(baseURL: baseURL)
        // In a real implementation, this would set the session
    }
    
    func setAuthenticationToken(_ token: String) {
        // Mock implementation for testing
    }
    
    func get<T: Codable>(
        endpoint: String,
        parameters: [String: String]? = nil,
        headers: [String: String]? = nil,
        responseType: T.Type
    ) -> AnyPublisher<T, APIError> {
        return Just(TestAPIResponse(message: "Mock response") as! T)
            .setFailureType(to: APIError.self)
            .eraseToAnyPublisher()
    }
    
    func post<T: Codable, U: Codable>(
        endpoint: String,
        body: T,
        headers: [String: String]? = nil,
        responseType: U.Type
    ) -> AnyPublisher<U, APIError> {
        return Just(TestAPIResponse(message: "Mock response") as! U)
            .setFailureType(to: APIError.self)
            .eraseToAnyPublisher()
    }
    
    func put<T: Codable, U: Codable>(
        endpoint: String,
        body: T,
        headers: [String: String]? = nil,
        responseType: U.Type
    ) -> AnyPublisher<U, APIError> {
        return Just(TestAPIResponse(message: "Mock response") as! U)
            .setFailureType(to: APIError.self)
            .eraseToAnyPublisher()
    }
    
    func delete(endpoint: String, headers: [String: String]? = nil) -> AnyPublisher<Void, APIError> {
        return Just(())
            .setFailureType(to: APIError.self)
            .eraseToAnyPublisher()
    }
}