// MetricsTests.swift
// SwiftAI Tests
// Copyright © 2024 Muhittin Camdali. All rights reserved.

import XCTest
@testable import SwiftAI

final class MetricsTests: XCTestCase {
    
    // MARK: - Classification Metrics
    
    func testAccuracyScore() {
        let yTrue = [0, 1, 1, 0, 1, 0]
        let yPred = [0, 1, 0, 0, 1, 1]
        
        let accuracy = accuracyScore(yTrue: yTrue, yPred: yPred)
        XCTAssertEqual(accuracy, 4.0 / 6.0, accuracy: 0.01)
    }
    
    func testPerfectAccuracy() {
        let y = [0, 1, 2, 0, 1, 2]
        let accuracy = accuracyScore(yTrue: y, yPred: y)
        XCTAssertEqual(accuracy, 1.0, accuracy: 0.001)
    }
    
    func testPrecisionRecallF1() {
        let yTrue = [0, 0, 1, 1, 1, 0]
        let yPred = [0, 1, 1, 1, 0, 0]
        
        let (precision, recall, f1) = precisionRecallF1(yTrue: yTrue, yPred: yPred)
        XCTAssertTrue(precision > 0 && precision <= 1)
        XCTAssertTrue(recall > 0 && recall <= 1)
        XCTAssertTrue(f1 > 0 && f1 <= 1)
    }
    
    func testConfusionMatrix() {
        let yTrue = [0, 0, 1, 1]
        let yPred = [0, 1, 0, 1]
        
        let matrix = confusionMatrix(yTrue: yTrue, yPred: yPred)
        XCTAssertEqual(matrix.count, 2)
        XCTAssertEqual(matrix[0], [1, 1])  // True 0: 1 correct, 1 predicted as 1
        XCTAssertEqual(matrix[1], [1, 1])  // True 1: 1 predicted as 0, 1 correct
    }
    
    // MARK: - Regression Metrics
    
    func testMSE() {
        let yTrue: [Float] = [1, 2, 3, 4, 5]
        let yPred: [Float] = [1.1, 2.1, 2.9, 4.2, 4.8]
        
        let mse = meanSquaredError(yTrue: yTrue, yPred: yPred)
        XCTAssertGreaterThan(mse, 0)
        XCTAssertLessThan(mse, 0.1)  // Should be small for close predictions
    }
    
    func testRMSE() {
        let yTrue: [Float] = [1, 2, 3, 4, 5]
        let yPred: [Float] = [1, 2, 3, 4, 5]
        
        let rmse = rootMeanSquaredError(yTrue: yTrue, yPred: yPred)
        XCTAssertEqual(rmse, 0, accuracy: 0.001)
    }
    
    func testMAE() {
        let yTrue: [Float] = [1, 2, 3]
        let yPred: [Float] = [1.5, 2.5, 3.5]
        
        let mae = meanAbsoluteError(yTrue: yTrue, yPred: yPred)
        XCTAssertEqual(mae, 0.5, accuracy: 0.01)
    }
    
    func testR2Score() {
        // Perfect prediction
        let yTrue: [Float] = [1, 2, 3, 4, 5]
        let yPred: [Float] = [1, 2, 3, 4, 5]
        
        let r2 = r2Score(yTrue: yTrue, yPred: yPred)
        XCTAssertEqual(r2, 1.0, accuracy: 0.001)
    }
    
    func testR2ScoreBad() {
        // Predicting mean everywhere
        let yTrue: [Float] = [1, 2, 3, 4, 5]
        let yPred: [Float] = [3, 3, 3, 3, 3]  // All mean
        
        let r2 = r2Score(yTrue: yTrue, yPred: yPred)
        XCTAssertEqual(r2, 0.0, accuracy: 0.01)
    }
    
    // MARK: - Clustering Metrics
    
    func testSilhouetteScore() {
        // Two well-separated clusters
        let x: [[Float]] = [
            [0, 0], [0.5, 0.5], [1, 0],
            [10, 10], [10.5, 10.5], [11, 10]
        ]
        let labels = [0, 0, 0, 1, 1, 1]
        
        let score = silhouetteScore(x: x, labels: labels)
        XCTAssertGreaterThan(score, 0.5)  // Well-separated clusters should have high score
    }
}
