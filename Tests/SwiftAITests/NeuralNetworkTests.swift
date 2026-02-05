// NeuralNetworkTests.swift
// SwiftAI Tests
// Copyright © 2024 Muhittin Camdali. All rights reserved.

import XCTest
@testable import SwiftAI

final class NeuralNetworkTests: XCTestCase {
    
    // MARK: - Model Building
    
    func testModelCreation() {
        let network = NeuralNetwork()
            .dense(4, 8, activation: .relu)
            .dropout(0.3)
            .dense(8, 2, activation: .softmax)
        
        XCTAssertEqual(network.layers.count, 5)  // Dense + Activation + Dropout + Dense + Activation
    }
    
    func testCompile() {
        let network = NeuralNetwork()
            .dense(4, 8, activation: .relu)
            .dense(8, 1)
        
        network.compile(optimizer: .adam, loss: .mse, learningRate: 0.01)
        XCTAssertNotNil(network.optimizer)
        XCTAssertNotNil(network.lossFunction)
    }
    
    // MARK: - Forward Pass
    
    func testForwardPass() {
        let network = NeuralNetwork()
            .dense(3, 5, activation: .relu)
            .dense(5, 2)
        
        let input = Tensor<Float>(shape: [3], data: [1.0, 2.0, 3.0])
        let output = network.predict(input)
        
        XCTAssertEqual(output.count, 2)
        XCTAssertEqual(output.shape, [2])
    }
    
    // MARK: - Training
    
    func testTrainingXOR() {
        let network = NeuralNetwork()
            .dense(2, 8, activation: .relu)
            .dense(8, 4, activation: .relu)
            .dense(4, 1, activation: .sigmoid)
        
        network.compile(optimizer: .adam, loss: .bce, learningRate: 0.01)
        
        // XOR dataset
        let x: [[Float]] = [[0, 0], [0, 1], [1, 0], [1, 1]]
        let y: [[Float]] = [[0], [1], [1], [0]]
        
        let history = network.train(
            x: x, y: y,
            epochs: 200,
            batchSize: 4,
            verbose: false
        )
        
        XCTAssertFalse(history.loss.isEmpty)
        // Loss should decrease
        XCTAssertLessThan(history.loss.last!, history.loss.first!)
    }
    
    // MARK: - Model Summary
    
    func testSummary() {
        let network = NeuralNetwork()
            .dense(784, 128, activation: .relu)
            .dense(128, 10, activation: .softmax)
        
        let summary = network.summary()
        XCTAssertFalse(summary.isEmpty)
        XCTAssertTrue(summary.contains("Model Summary"))
    }
    
    // MARK: - Evaluation
    
    func testEvaluate() {
        let network = NeuralNetwork()
            .dense(2, 4, activation: .relu)
            .dense(4, 2, activation: .softmax)
        
        network.compile(optimizer: .adam, loss: .crossEntropy)
        
        let x: [[Float]] = [[1, 0], [0, 1], [1, 1], [0, 0]]
        let y: [[Float]] = [[1, 0], [0, 1], [1, 0], [0, 1]]
        
        let (loss, accuracy) = network.evaluate(x: x, y: y)
        
        XCTAssertTrue(loss >= 0)
        XCTAssertTrue(accuracy >= 0 && accuracy <= 1)
    }
    
    // MARK: - Parameter Collection
    
    func testParameterCollection() {
        let network = NeuralNetwork()
            .dense(3, 5)
            .dense(5, 2)
        
        let params = network.collectParameters()
        // Dense(3,5) has weights + bias, Dense(5,2) has weights + bias
        XCTAssertEqual(params.count, 4)
    }
}
