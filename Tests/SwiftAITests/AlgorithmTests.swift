// AlgorithmTests.swift
// SwiftAI Tests
// Copyright © 2024 Muhittin Camdali. All rights reserved.

import XCTest
@testable import SwiftAI

final class AlgorithmTests: XCTestCase {
    
    // MARK: - Linear Regression
    
    func testLinearRegressionFit() {
        let model = LinearRegression()
        
        // y = 2x + 1
        let x: [[Float]] = [[1], [2], [3], [4], [5]]
        let y: [Float] = [3, 5, 7, 9, 11]
        
        model.fit(x: x, y: y)
        
        let predictions = model.predict(x)
        
        // Check predictions are close to actual
        for i in 0..<y.count {
            XCTAssertEqual(predictions[i], y[i], accuracy: 0.5)
        }
        
        // R² should be close to 1
        let r2 = model.score(x: x, y: y)
        XCTAssertGreaterThan(r2, 0.95)
    }
    
    func testLinearRegressionGradientDescent() {
        let model = LinearRegression()
        
        let x: [[Float]] = [[1], [2], [3], [4], [5]]
        let y: [Float] = [2, 4, 6, 8, 10]
        
        model.fit(x: x, y: y, method: .gradientDescent(learningRate: 0.01, epochs: 500))
        
        let r2 = model.score(x: x, y: y)
        XCTAssertGreaterThan(r2, 0.9)
    }
    
    func testRidgeRegression() {
        let model = RidgeRegression(alpha: 0.1)
        
        let x: [[Float]] = [[1], [2], [3], [4], [5]]
        let y: [Float] = [3, 5, 7, 9, 11]
        
        model.fit(x: x, y: y)
        let predictions = model.predict(x)
        XCTAssertEqual(predictions.count, 5)
    }
    
    // MARK: - Logistic Regression
    
    func testLogisticRegressionBinary() {
        let model = LogisticRegression()
        
        // Simple linearly separable data
        let x: [[Float]] = [
            [0, 0], [0, 1], [1, 0],
            [3, 3], [3, 4], [4, 3]
        ]
        let y: [Int] = [0, 0, 0, 1, 1, 1]
        
        model.fit(x: x, y: y, learningRate: 0.1)
        
        let accuracy = model.score(x: x, y: y)
        XCTAssertGreaterThan(accuracy, 0.8)
    }
    
    // MARK: - Decision Tree
    
    func testDecisionTreeClassifier() {
        let tree = DecisionTreeClassifier(maxDepth: 5)
        
        let x: [[Float]] = [
            [0, 0], [0, 1], [1, 0], [1, 1],
            [2, 2], [2, 3], [3, 2], [3, 3]
        ]
        let y: [Int] = [0, 0, 0, 0, 1, 1, 1, 1]
        
        tree.fit(x: x, y: y)
        
        let predictions = tree.predict(x)
        XCTAssertEqual(predictions.count, 8)
        
        let accuracy = tree.score(x: x, y: y)
        XCTAssertGreaterThan(accuracy, 0.8)
    }
    
    func testDecisionTreeRegressor() {
        let tree = DecisionTreeRegressor(maxDepth: 5)
        
        let x: [[Float]] = [[1], [2], [3], [4], [5], [6], [7], [8]]
        let y: [Float] = [2, 4, 6, 8, 10, 12, 14, 16]
        
        tree.fit(x: x, y: y)
        
        let predictions = tree.predict(x)
        XCTAssertEqual(predictions.count, 8)
    }
    
    // MARK: - Random Forest
    
    func testRandomForestClassifier() {
        let forest = RandomForestClassifier(nEstimators: 10, maxDepth: 5)
        
        let x: [[Float]] = [
            [0, 0], [0, 1], [1, 0], [1, 1],
            [5, 5], [5, 6], [6, 5], [6, 6]
        ]
        let y: [Int] = [0, 0, 0, 0, 1, 1, 1, 1]
        
        forest.fit(x: x, y: y)
        
        let predictions = forest.predict(x)
        XCTAssertEqual(predictions.count, 8)
        
        // Feature importance should be available
        XCTAssertNotNil(forest.featureImportances)
    }
    
    // MARK: - K-Means
    
    func testKMeansClustering() {
        let kmeans = KMeans(nClusters: 2, maxIterations: 100, initMethod: .kmeanspp, nInit: 3)
        
        // Two clear clusters
        let data: [[Float]] = [
            [0, 0], [0.5, 0.5], [1, 0], [0, 1],
            [10, 10], [10.5, 10.5], [11, 10], [10, 11]
        ]
        
        kmeans.fit(data)
        
        XCTAssertNotNil(kmeans.centroids)
        XCTAssertNotNil(kmeans.labels)
        XCTAssertEqual(kmeans.labels!.count, 8)
        
        // Points in same cluster should have same label
        XCTAssertEqual(kmeans.labels![0], kmeans.labels![1])
        XCTAssertEqual(kmeans.labels![4], kmeans.labels![5])
        XCTAssertNotEqual(kmeans.labels![0], kmeans.labels![4])
    }
    
    func testKMeansPredict() {
        let kmeans = KMeans(nClusters: 2, nInit: 3)
        
        let data: [[Float]] = [
            [0, 0], [1, 1],
            [10, 10], [11, 11]
        ]
        
        kmeans.fit(data)
        
        let newPoints: [[Float]] = [[0.5, 0.5], [10.5, 10.5]]
        let labels = kmeans.predict(newPoints)
        XCTAssertEqual(labels.count, 2)
        XCTAssertNotEqual(labels[0], labels[1])
    }
    
    // MARK: - KNN
    
    func testKNNClassifier() {
        let knn = KNeighborsClassifier(k: 3)
        
        let x: [[Float]] = [
            [0, 0], [0, 1], [1, 0], [1, 1],
            [5, 5], [5, 6], [6, 5], [6, 6]
        ]
        let y: [Int] = [0, 0, 0, 0, 1, 1, 1, 1]
        
        knn.fit(x: x, y: y)
        
        let predictions = knn.predict([[0.5, 0.5], [5.5, 5.5]])
        XCTAssertEqual(predictions[0], 0)
        XCTAssertEqual(predictions[1], 1)
    }
    
    // MARK: - SVM
    
    func testSVCBinary() {
        let svm = SVC(C: 1.0, kernel: .linear)
        
        let x: [[Float]] = [
            [0, 0], [0, 1], [1, 0],
            [5, 5], [5, 6], [6, 5]
        ]
        let y: [Int] = [0, 0, 0, 1, 1, 1]
        
        svm.fit(x: x, y: y)
        
        let predictions = svm.predict(x)
        XCTAssertEqual(predictions.count, 6)
    }
}
