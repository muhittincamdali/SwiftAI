import XCTest
@testable import SwiftAI

final class SwiftAITests: XCTestCase {
    func testNeuralNetworkInitialization() {
        let network = NeuralNetwork()
        XCTAssertNotNil(network)
    }
}
