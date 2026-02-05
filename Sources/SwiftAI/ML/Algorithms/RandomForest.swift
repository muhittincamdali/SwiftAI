// RandomForest.swift
// SwiftAI - Pure Swift Machine Learning Framework
// Copyright © 2024 Muhittin Camdali. All rights reserved.

import Foundation

// MARK: - Random Forest Classifier
public final class RandomForestClassifier: @unchecked Sendable {
    
    // MARK: - Properties
    public private(set) var trees: [DecisionTreeClassifier] = []
    public private(set) var classes: [Int] = []
    public private(set) var featureImportances: [Float]?
    
    public let nEstimators: Int
    public let maxDepth: Int
    public let minSamplesSplit: Int
    public let minSamplesLeaf: Int
    public let maxFeatures: MaxFeatures
    public let bootstrap: Bool
    public let oobScore: Bool
    
    public private(set) var oobScoreValue: Float?
    
    // MARK: - Types
    public enum MaxFeatures: Sendable {
        case sqrt
        case log2
        case fixed(Int)
        case fraction(Float)
        case all
    }
    
    // MARK: - Initialization
    public init(
        nEstimators: Int = 100,
        maxDepth: Int = 10,
        minSamplesSplit: Int = 2,
        minSamplesLeaf: Int = 1,
        maxFeatures: MaxFeatures = .sqrt,
        bootstrap: Bool = true,
        oobScore: Bool = false
    ) {
        self.nEstimators = nEstimators
        self.maxDepth = maxDepth
        self.minSamplesSplit = minSamplesSplit
        self.minSamplesLeaf = minSamplesLeaf
        self.maxFeatures = maxFeatures
        self.bootstrap = bootstrap
        self.oobScore = oobScore
    }
    
    // MARK: - Fitting
    public func fit(x: [[Float]], y: [Int]) {
        precondition(x.count == y.count, "X and Y must have same number of samples")
        precondition(!x.isEmpty, "Data cannot be empty")
        
        classes = Array(Set(y)).sorted()
        let nSamples = x.count
        let nFeatures = x[0].count
        
        let maxF = computeMaxFeatures(nFeatures: nFeatures)
        
        trees = []
        var oobPredictions = [[Float]](repeating: [Float](repeating: 0, count: classes.count), count: nSamples)
        var oobCounts = [Int](repeating: 0, count: nSamples)
        
        for _ in 0..<nEstimators {
            // Bootstrap sampling
            var sampleIndices: [Int]
            var oobIndices: Set<Int>?
            
            if bootstrap {
                sampleIndices = (0..<nSamples).map { _ in Int.random(in: 0..<nSamples) }
                if oobScore {
                    let sampledSet = Set(sampleIndices)
                    oobIndices = Set(0..<nSamples).subtracting(sampledSet)
                }
            } else {
                sampleIndices = Array(0..<nSamples)
            }
            
            let sampleX = sampleIndices.map { x[$0] }
            let sampleY = sampleIndices.map { y[$0] }
            
            // Create and train tree
            let tree = DecisionTreeClassifier(
                maxDepth: maxDepth,
                minSamplesSplit: minSamplesSplit,
                minSamplesLeaf: minSamplesLeaf,
                criterion: .gini,
                maxFeatures: maxF
            )
            tree.fit(x: sampleX, y: sampleY)
            trees.append(tree)
            
            // OOB predictions
            if oobScore, let oob = oobIndices {
                for idx in oob {
                    let proba = tree.predictProbaSingle(x[idx])
                    for (i, p) in proba.enumerated() {
                        oobPredictions[idx][i] += p
                    }
                    oobCounts[idx] += 1
                }
            }
        }
        
        // Compute OOB score
        if oobScore {
            var correct = 0
            var total = 0
            
            for i in 0..<nSamples {
                if oobCounts[i] > 0 {
                    let avgProba = oobPredictions[i].map { $0 / Float(oobCounts[i]) }
                    let predictedClass = classes[avgProba.enumerated().max(by: { $0.element < $1.element })!.offset]
                    if predictedClass == y[i] {
                        correct += 1
                    }
                    total += 1
                }
            }
            
            oobScoreValue = total > 0 ? Float(correct) / Float(total) : nil
        }
        
        // Compute feature importances
        computeFeatureImportances(nFeatures: nFeatures)
    }
    
    private func computeMaxFeatures(nFeatures: Int) -> Int {
        switch maxFeatures {
        case .sqrt:
            return Int(sqrt(Float(nFeatures)))
        case .log2:
            return Int(log2(Float(nFeatures)))
        case .fixed(let n):
            return min(n, nFeatures)
        case .fraction(let f):
            return Int(f * Float(nFeatures))
        case .all:
            return nFeatures
        }
    }
    
    private func computeFeatureImportances(nFeatures: Int) {
        var importances = [Float](repeating: 0, count: nFeatures)
        
        for tree in trees {
            if let treeImportances = tree.featureImportances {
                for (i, imp) in treeImportances.enumerated() {
                    importances[i] += imp
                }
            }
        }
        
        // Average
        let nTrees = Float(trees.count)
        featureImportances = importances.map { $0 / nTrees }
    }
    
    // MARK: - Prediction
    public func predict(_ x: [[Float]]) -> [Int] {
        x.map { predictSingle($0) }
    }
    
    public func predictSingle(_ x: [Float]) -> Int {
        let proba = predictProbaSingle(x)
        let maxIdx = proba.enumerated().max(by: { $0.element < $1.element })?.offset ?? 0
        return classes[maxIdx]
    }
    
    public func predictProba(_ x: [[Float]]) -> [[Float]] {
        x.map { predictProbaSingle($0) }
    }
    
    public func predictProbaSingle(_ x: [Float]) -> [Float] {
        var avgProba = [Float](repeating: 0, count: classes.count)
        
        for tree in trees {
            let proba = tree.predictProbaSingle(x)
            for (i, p) in proba.enumerated() {
                avgProba[i] += p
            }
        }
        
        let nTrees = Float(trees.count)
        return avgProba.map { $0 / nTrees }
    }
    
    // MARK: - Evaluation
    public func score(x: [[Float]], y: [Int]) -> Float {
        let predictions = predict(x)
        var correct = 0
        for i in 0..<y.count {
            if predictions[i] == y[i] {
                correct += 1
            }
        }
        return Float(correct) / Float(y.count)
    }
}

// MARK: - Random Forest Regressor
public final class RandomForestRegressor: @unchecked Sendable {
    
    // MARK: - Properties
    public private(set) var trees: [DecisionTreeRegressor] = []
    public private(set) var featureImportances: [Float]?
    
    public let nEstimators: Int
    public let maxDepth: Int
    public let minSamplesSplit: Int
    public let minSamplesLeaf: Int
    public let maxFeatures: RandomForestClassifier.MaxFeatures
    public let bootstrap: Bool
    
    public private(set) var oobScoreValue: Float?
    
    // MARK: - Initialization
    public init(
        nEstimators: Int = 100,
        maxDepth: Int = 10,
        minSamplesSplit: Int = 2,
        minSamplesLeaf: Int = 1,
        maxFeatures: RandomForestClassifier.MaxFeatures = .sqrt,
        bootstrap: Bool = true
    ) {
        self.nEstimators = nEstimators
        self.maxDepth = maxDepth
        self.minSamplesSplit = minSamplesSplit
        self.minSamplesLeaf = minSamplesLeaf
        self.maxFeatures = maxFeatures
        self.bootstrap = bootstrap
    }
    
    // MARK: - Fitting
    public func fit(x: [[Float]], y: [Float]) {
        precondition(x.count == y.count, "X and Y must have same number of samples")
        precondition(!x.isEmpty, "Data cannot be empty")
        
        let nSamples = x.count
        let nFeatures = x[0].count
        
        trees = []
        
        for _ in 0..<nEstimators {
            var sampleIndices: [Int]
            
            if bootstrap {
                sampleIndices = (0..<nSamples).map { _ in Int.random(in: 0..<nSamples) }
            } else {
                sampleIndices = Array(0..<nSamples)
            }
            
            let sampleX = sampleIndices.map { x[$0] }
            let sampleY = sampleIndices.map { y[$0] }
            
            let tree = DecisionTreeRegressor(
                maxDepth: maxDepth,
                minSamplesSplit: minSamplesSplit,
                minSamplesLeaf: minSamplesLeaf,
                criterion: .mse
            )
            tree.fit(x: sampleX, y: sampleY)
            trees.append(tree)
        }
        
        // Compute feature importances
        var importances = [Float](repeating: 0, count: nFeatures)
        
        for tree in trees {
            if let treeImportances = tree.featureImportances {
                for (i, imp) in treeImportances.enumerated() {
                    importances[i] += imp
                }
            }
        }
        
        let nTrees = Float(trees.count)
        featureImportances = importances.map { $0 / nTrees }
    }
    
    // MARK: - Prediction
    public func predict(_ x: [[Float]]) -> [Float] {
        x.map { predictSingle($0) }
    }
    
    public func predictSingle(_ x: [Float]) -> Float {
        let predictions = trees.map { $0.predictSingle(x) }
        return predictions.reduce(0, +) / Float(predictions.count)
    }
    
    // MARK: - Evaluation
    public func score(x: [[Float]], y: [Float]) -> Float {
        let predictions = predict(x)
        let mean = y.reduce(0, +) / Float(y.count)
        
        var ssRes: Float = 0
        var ssTot: Float = 0
        
        for i in 0..<y.count {
            ssRes += (y[i] - predictions[i]) * (y[i] - predictions[i])
            ssTot += (y[i] - mean) * (y[i] - mean)
        }
        
        return 1 - (ssRes / ssTot)
    }
}

// MARK: - Gradient Boosting Classifier
public final class GradientBoostingClassifier: @unchecked Sendable {
    
    // MARK: - Properties
    public private(set) var trees: [[DecisionTreeRegressor]] = []
    public private(set) var classes: [Int] = []
    public private(set) var initialPredictions: [Float] = []
    
    public let nEstimators: Int
    public let maxDepth: Int
    public let learningRate: Float
    public let subsample: Float
    
    // MARK: - Initialization
    public init(
        nEstimators: Int = 100,
        maxDepth: Int = 3,
        learningRate: Float = 0.1,
        subsample: Float = 1.0
    ) {
        self.nEstimators = nEstimators
        self.maxDepth = maxDepth
        self.learningRate = learningRate
        self.subsample = subsample
    }
    
    // MARK: - Fitting
    public func fit(x: [[Float]], y: [Int]) {
        precondition(x.count == y.count, "X and Y must have same number of samples")
        
        classes = Array(Set(y)).sorted()
        let nSamples = x.count
        let nClasses = classes.count
        
        // Initialize predictions (log-odds for each class)
        var classCounts = [Int: Int]()
        for label in y {
            classCounts[label, default: 0] += 1
        }
        
        initialPredictions = classes.map { cls -> Float in
            let p = Float(classCounts[cls, default: 0]) / Float(nSamples)
            return log(max(p, 1e-10) / max(1 - p, 1e-10))
        }
        
        // Current predictions for each sample and class
        var predictions = [[Float]](repeating: initialPredictions, count: nSamples)
        
        trees = [[DecisionTreeRegressor]](repeating: [], count: nClasses)
        
        for _ in 0..<nEstimators {
            // Compute probabilities using softmax
            let probas = predictions.map { softmax($0) }
            
            // For each class, fit a tree to the residuals
            for c in 0..<nClasses {
                // Compute residuals (negative gradient of cross-entropy)
                var residuals = [Float](repeating: 0, count: nSamples)
                for i in 0..<nSamples {
                    let target: Float = y[i] == classes[c] ? 1.0 : 0.0
                    residuals[i] = target - probas[i][c]
                }
                
                // Subsample
                var sampleIndices = Array(0..<nSamples)
                if subsample < 1.0 {
                    sampleIndices.shuffle()
                    sampleIndices = Array(sampleIndices.prefix(Int(subsample * Float(nSamples))))
                }
                
                let sampleX = sampleIndices.map { x[$0] }
                let sampleResiduals = sampleIndices.map { residuals[$0] }
                
                // Fit tree to residuals
                let tree = DecisionTreeRegressor(
                    maxDepth: maxDepth,
                    minSamplesSplit: 2,
                    minSamplesLeaf: 1
                )
                tree.fit(x: sampleX, y: sampleResiduals)
                trees[c].append(tree)
                
                // Update predictions
                for i in 0..<nSamples {
                    predictions[i][c] += learningRate * tree.predictSingle(x[i])
                }
            }
        }
    }
    
    private func softmax(_ x: [Float]) -> [Float] {
        let maxVal = x.max() ?? 0
        let exps = x.map { exp($0 - maxVal) }
        let sum = exps.reduce(0, +)
        return exps.map { $0 / sum }
    }
    
    // MARK: - Prediction
    public func predict(_ x: [[Float]]) -> [Int] {
        x.map { predictSingle($0) }
    }
    
    public func predictSingle(_ x: [Float]) -> Int {
        let proba = predictProbaSingle(x)
        let maxIdx = proba.enumerated().max(by: { $0.element < $1.element })?.offset ?? 0
        return classes[maxIdx]
    }
    
    public func predictProba(_ x: [[Float]]) -> [[Float]] {
        x.map { predictProbaSingle($0) }
    }
    
    public func predictProbaSingle(_ x: [Float]) -> [Float] {
        var scores = initialPredictions
        
        for c in 0..<classes.count {
            for tree in trees[c] {
                scores[c] += learningRate * tree.predictSingle(x)
            }
        }
        
        return softmax(scores)
    }
    
    // MARK: - Evaluation
    public func score(x: [[Float]], y: [Int]) -> Float {
        let predictions = predict(x)
        var correct = 0
        for i in 0..<y.count {
            if predictions[i] == y[i] {
                correct += 1
            }
        }
        return Float(correct) / Float(y.count)
    }
}
