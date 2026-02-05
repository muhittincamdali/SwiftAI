// TensorTests.swift
// SwiftAI Tests
// Copyright © 2024 Muhittin Camdali. All rights reserved.

import XCTest
@testable import SwiftAI

final class TensorTests: XCTestCase {
    
    // MARK: - Creation Tests
    
    func testZeros() {
        let tensor = Tensor<Float>.zeros([3, 4])
        XCTAssertEqual(tensor.shape, [3, 4])
        XCTAssertEqual(tensor.count, 12)
        XCTAssertTrue(tensor.data.allSatisfy { $0 == 0 })
    }
    
    func testOnes() {
        let tensor = Tensor<Float>.ones([2, 3])
        XCTAssertEqual(tensor.shape, [2, 3])
        XCTAssertTrue(tensor.data.allSatisfy { $0 == 1 })
    }
    
    func testEye() {
        let eye = Tensor<Float>.eye(3)
        XCTAssertEqual(eye[0, 0], 1)
        XCTAssertEqual(eye[1, 1], 1)
        XCTAssertEqual(eye[2, 2], 1)
        XCTAssertEqual(eye[0, 1], 0)
        XCTAssertEqual(eye[1, 0], 0)
    }
    
    func testFromData() {
        let tensor = Tensor<Float>(shape: [2, 3], data: [1, 2, 3, 4, 5, 6])
        XCTAssertEqual(tensor.shape, [2, 3])
        XCTAssertEqual(tensor.rank, 2)
        XCTAssertEqual(tensor[0, 0], 1)
        XCTAssertEqual(tensor[1, 2], 6)
    }
    
    // MARK: - Shape Operations
    
    func testReshape() {
        let tensor = Tensor<Float>(shape: [2, 3], data: [1, 2, 3, 4, 5, 6])
        let reshaped = tensor.reshape([3, 2])
        XCTAssertEqual(reshaped.shape, [3, 2])
        XCTAssertEqual(reshaped.data, [1, 2, 3, 4, 5, 6])
    }
    
    func testTranspose() {
        let tensor = Tensor<Float>(shape: [2, 3], data: [1, 2, 3, 4, 5, 6])
        let transposed = tensor.T
        XCTAssertEqual(transposed.shape, [3, 2])
        XCTAssertEqual(transposed[0, 0], 1)
        XCTAssertEqual(transposed[0, 1], 4)
        XCTAssertEqual(transposed[2, 1], 6)
    }
    
    func testFlatten() {
        let tensor = Tensor<Float>(shape: [2, 3], data: [1, 2, 3, 4, 5, 6])
        let flat = tensor.flatten()
        XCTAssertEqual(flat.shape, [6])
        XCTAssertEqual(flat.data, [1, 2, 3, 4, 5, 6])
    }
    
    // MARK: - Arithmetic Operations
    
    func testAddition() {
        let a = Tensor<Float>(shape: [3], data: [1, 2, 3])
        let b = Tensor<Float>(shape: [3], data: [4, 5, 6])
        let c = a + b
        XCTAssertEqual(c.data, [5, 7, 9])
    }
    
    func testSubtraction() {
        let a = Tensor<Float>(shape: [3], data: [5, 7, 9])
        let b = Tensor<Float>(shape: [3], data: [1, 2, 3])
        let c = a - b
        XCTAssertEqual(c.data, [4, 5, 6])
    }
    
    func testScalarMultiplication() {
        let a = Tensor<Float>(shape: [3], data: [1, 2, 3])
        let c = a * Float(2)
        XCTAssertEqual(c.data, [2, 4, 6])
    }
    
    func testElementWiseMultiplication() {
        let a = Tensor<Float>(shape: [3], data: [1, 2, 3])
        let b = Tensor<Float>(shape: [3], data: [4, 5, 6])
        let c = a * b
        XCTAssertEqual(c.data, [4, 10, 18])
    }
    
    // MARK: - Matrix Multiplication
    
    func testMatmul() {
        let a = Tensor<Float>(shape: [2, 3], data: [1, 2, 3, 4, 5, 6])
        let b = Tensor<Float>(shape: [3, 2], data: [7, 8, 9, 10, 11, 12])
        let c = a.matmul(b)
        XCTAssertEqual(c.shape, [2, 2])
        XCTAssertEqual(c[0, 0], 58)   // 1*7 + 2*9 + 3*11
        XCTAssertEqual(c[0, 1], 64)   // 1*8 + 2*10 + 3*12
        XCTAssertEqual(c[1, 0], 139)  // 4*7 + 5*9 + 6*11
        XCTAssertEqual(c[1, 1], 154)  // 4*8 + 5*10 + 6*12
    }
    
    // MARK: - Statistics
    
    func testSum() {
        let tensor = Tensor<Float>(shape: [4], data: [1, 2, 3, 4])
        XCTAssertEqual(tensor.sum(), 10)
    }
    
    func testMean() {
        let tensor = Tensor<Float>(shape: [4], data: [1, 2, 3, 4])
        XCTAssertEqual(tensor.mean(), 2.5)
    }
    
    func testArgmax() {
        let tensor = Tensor<Float>(shape: [5], data: [1, 5, 3, 2, 4])
        XCTAssertEqual(tensor.argmax(), 1)
    }
    
    func testArgmin() {
        let tensor = Tensor<Float>(shape: [5], data: [3, 1, 5, 2, 4])
        XCTAssertEqual(tensor.argmin(), 1)
    }
    
    // MARK: - Copy
    
    func testCopy() {
        let original = Tensor<Float>(shape: [3], data: [1, 2, 3])
        let copy = original.copy()
        copy.data[0] = 99
        XCTAssertEqual(original.data[0], 1)
        XCTAssertEqual(copy.data[0], 99)
    }
}
