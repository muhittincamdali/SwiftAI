import XCTest
@testable import SwiftAI

final class AIManagerTests: XCTestCase {
    
    var aiManager: AIManager!
    
    override func setUp() {
        super.setUp()
        aiManager = AIManager()
    }
    
    override func tearDown() {
        aiManager = nil
        super.tearDown()
    }
    
    func testAIManagerInitialization() {
        XCTAssertNotNil(aiManager, "AI Manager should be initialized")
    }
    
    func testAIConfiguration() {
        let config = AIConfiguration()
        config.enableMachineLearning = true
        config.enableNaturalLanguageProcessing = true
        
        aiManager.configure(config)
        
        // Verify configuration was applied
        XCTAssertTrue(aiManager.isConfigured, "AI Manager should be configured")
    }
    
    func testBasicPrediction() {
        let expectation = XCTestExpectation(description: "Basic prediction")
        
        let simpleML = SimpleML()
        simpleML.predict(
            model: "test_model",
            input: [1.0, 2.0, 3.0, 4.0]
        ) { result in
            switch result {
            case .success(let prediction):
                XCTAssertNotNil(prediction, "Prediction should not be nil")
                expectation.fulfill()
            case .failure(let error):
                XCTFail("Prediction should succeed: \(error)")
            }
        }
        
        wait(for: [expectation], timeout: 10.0)
    }
    
    func testTextAnalysis() {
        let expectation = XCTestExpectation(description: "Text analysis")
        
        let simpleNLP = SimpleNLP()
        simpleNLP.analyzeText("This is a test text for analysis") { result in
            switch result {
            case .success(let analysis):
                XCTAssertNotNil(analysis.sentiment, "Sentiment should not be nil")
                XCTAssertNotNil(analysis.keywords, "Keywords should not be nil")
                expectation.fulfill()
            case .failure(let error):
                XCTFail("Text analysis should succeed: \(error)")
            }
        }
        
        wait(for: [expectation], timeout: 10.0)
    }
    
    func testPerformance() {
        measure {
            let simpleML = SimpleML()
            let expectation = XCTestExpectation(description: "Performance test")
            
            simpleML.predict(
                model: "performance_test_model",
                input: Array(repeating: 1.0, count: 1000)
            ) { _ in
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 5.0)
        }
    }
}

extension AIManagerTests {
    static var allTests = [
        ("testAIManagerInitialization", testAIManagerInitialization),
        ("testAIConfiguration", testAIConfiguration),
        ("testBasicPrediction", testBasicPrediction),
        ("testTextAnalysis", testTextAnalysis),
        ("testPerformance", testPerformance)
    ]
}
