// PreprocessingTests.swift
// SwiftAI Tests
// Copyright © 2024 Muhittin Camdali. All rights reserved.

import XCTest
@testable import SwiftAI

final class PreprocessingTests: XCTestCase {
    
    // MARK: - Standard Scaler
    
    func testStandardScaler() {
        let scaler = StandardScaler()
        let data: [[Float]] = [[1, 2], [3, 4], [5, 6], [7, 8]]
        
        let scaled = scaler.fitTransform(data)
        XCTAssertEqual(scaled.count, 4)
        
        // Mean should be ~0
        let col0 = scaled.map { $0[0] }
        let mean0 = col0.reduce(0, +) / Float(col0.count)
        XCTAssertEqual(mean0, 0, accuracy: 0.01)
        
        // Inverse transform should recover original
        let recovered = scaler.inverseTransform(scaled)
        for i in 0..<data.count {
            for j in 0..<data[0].count {
                XCTAssertEqual(recovered[i][j], data[i][j], accuracy: 0.01)
            }
        }
    }
    
    // MARK: - MinMax Scaler
    
    func testMinMaxScaler() {
        let scaler = MinMaxScaler()
        let data: [[Float]] = [[1], [3], [5], [7]]
        
        let scaled = scaler.fitTransform(data)
        
        XCTAssertEqual(scaled[0][0], 0, accuracy: 0.01)  // min -> 0
        XCTAssertEqual(scaled[3][0], 1, accuracy: 0.01)  // max -> 1
    }
    
    // MARK: - Label Encoder
    
    func testLabelEncoder() {
        let encoder = LabelEncoder()
        let labels = [5, 3, 1, 5, 3, 1, 5]
        
        let encoded = encoder.fitTransform(labels)
        
        XCTAssertNotNil(encoder.classes)
        XCTAssertEqual(encoder.classes!, [1, 3, 5])
        
        // Same labels should map to same indices
        XCTAssertEqual(encoded[0], encoded[3])
        XCTAssertEqual(encoded[1], encoded[4])
    }
    
    // MARK: - One-Hot Encoder
    
    func testOneHotEncoder() {
        let encoder = OneHotEncoder()
        let data: [[Int]] = [[0], [1], [2], [1]]
        
        let encoded = encoder.fitTransform(data)
        
        XCTAssertEqual(encoded[0], [1, 0, 0])  // class 0
        XCTAssertEqual(encoded[1], [0, 1, 0])  // class 1
        XCTAssertEqual(encoded[2], [0, 0, 1])  // class 2
        XCTAssertEqual(encoded[3], [0, 1, 0])  // class 1
    }
    
    // MARK: - Imputer
    
    func testSimpleImputer() {
        let imputer = SimpleImputer(strategy: .constant(0))
        let data: [[Float]] = [[1, .nan], [3, 4], [.nan, 6]]
        
        let filled = imputer.fitTransform(data)
        
        XCTAssertFalse(filled[0][1].isNaN)
        XCTAssertFalse(filled[2][0].isNaN)
    }
    
    // MARK: - Train/Test Split
    
    func testTrainTestSplit() {
        let x = Array(0..<100)
        let y = Array(0..<100)
        
        let (trainX, testX, trainY, testY) = trainTestSplit(
            x: x, y: y, testSize: 0.2, shuffle: false
        )
        
        XCTAssertEqual(trainX.count, 80)
        XCTAssertEqual(testX.count, 20)
        XCTAssertEqual(trainY.count, 80)
        XCTAssertEqual(testY.count, 20)
    }
    
    // MARK: - K-Fold
    
    func testKFold() {
        let kfold = KFold(nSplits: 5, shuffle: false)
        let splits = kfold.split(nSamples: 100)
        
        XCTAssertEqual(splits.count, 5)
        
        for (train, test) in splits {
            XCTAssertEqual(train.count + test.count, 100)
            XCTAssertEqual(test.count, 20)
        }
    }
    
    // MARK: - Normalizer
    
    func testNormalizer() {
        let normalizer = Normalizer(norm: .l2)
        let data: [[Float]] = [[3, 4], [6, 8]]
        
        let normalized = normalizer.transform(data)
        
        // L2 norm of [3, 4] = 5, so [0.6, 0.8]
        XCTAssertEqual(normalized[0][0], 0.6, accuracy: 0.01)
        XCTAssertEqual(normalized[0][1], 0.8, accuracy: 0.01)
    }
}
