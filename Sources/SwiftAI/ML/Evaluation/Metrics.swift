// Metrics.swift
// SwiftAI - Pure Swift Machine Learning Framework
// Copyright © 2024 Muhittin Camdali. All rights reserved.

import Foundation
import Accelerate

// MARK: - Classification Metrics

/// Compute accuracy classification score
public func accuracyScore(yTrue: [Int], yPred: [Int]) -> Float {
    precondition(yTrue.count == yPred.count, "Arrays must have same length")
    let correct = zip(yTrue, yPred).filter { $0 == $1 }.count
    return Float(correct) / Float(yTrue.count)
}

/// Compute precision, recall, F1 score
public func precisionRecallF1(
    yTrue: [Int],
    yPred: [Int],
    average: AverageType = .weighted
) -> (precision: Float, recall: Float, f1: Float) {
    precondition(yTrue.count == yPred.count, "Arrays must have same length")
    
    let classes = Array(Set(yTrue + yPred)).sorted()
    var precisions = [Float]()
    var recalls = [Float]()
    var f1s = [Float]()
    var supports = [Int]()
    
    for cls in classes {
        var tp = 0, fp = 0, fn = 0
        var support = 0
        
        for i in 0..<yTrue.count {
            if yTrue[i] == cls {
                support += 1
                if yPred[i] == cls {
                    tp += 1
                } else {
                    fn += 1
                }
            } else if yPred[i] == cls {
                fp += 1
            }
        }
        
        let precision: Float = tp + fp > 0 ? Float(tp) / Float(tp + fp) : 0
        let recall: Float = tp + fn > 0 ? Float(tp) / Float(tp + fn) : 0
        let f1 = precision + recall > 0 ? 2 * precision * recall / (precision + recall) : 0
        
        precisions.append(precision)
        recalls.append(recall)
        f1s.append(f1)
        supports.append(support)
    }
    
    switch average {
    case .micro:
        // Global counts
        var totalTP = 0, totalFP = 0, totalFN = 0
        for cls in classes {
            for i in 0..<yTrue.count {
                if yTrue[i] == cls && yPred[i] == cls { totalTP += 1 }
                else if yPred[i] == cls { totalFP += 1 }
                else if yTrue[i] == cls { totalFN += 1 }
            }
        }
        let p: Float = totalTP + totalFP > 0 ? Float(totalTP) / Float(totalTP + totalFP) : 0
        let r: Float = totalTP + totalFN > 0 ? Float(totalTP) / Float(totalTP + totalFN) : 0
        let f = p + r > 0 ? 2 * p * r / (p + r) : 0
        return (p, r, f)
        
    case .macro:
        let n = Float(classes.count)
        return (
            precisions.reduce(0, +) / n,
            recalls.reduce(0, +) / n,
            f1s.reduce(0, +) / n
        )
        
    case .weighted:
        let totalSupport = Float(supports.reduce(0, +))
        var weightedP: Float = 0
        var weightedR: Float = 0
        var weightedF1: Float = 0
        
        for i in 0..<classes.count {
            let weight = Float(supports[i]) / totalSupport
            weightedP += precisions[i] * weight
            weightedR += recalls[i] * weight
            weightedF1 += f1s[i] * weight
        }
        
        return (weightedP, weightedR, weightedF1)
    }
}

public enum AverageType: Sendable {
    case micro
    case macro
    case weighted
}

/// Compute confusion matrix
public func confusionMatrix(yTrue: [Int], yPred: [Int]) -> [[Int]] {
    precondition(yTrue.count == yPred.count, "Arrays must have same length")
    
    let classes = Array(Set(yTrue + yPred)).sorted()
    let n = classes.count
    var matrix = [[Int]](repeating: [Int](repeating: 0, count: n), count: n)
    
    let classToIdx = Dictionary(uniqueKeysWithValues: classes.enumerated().map { ($1, $0) })
    
    for i in 0..<yTrue.count {
        let trueIdx = classToIdx[yTrue[i]]!
        let predIdx = classToIdx[yPred[i]]!
        matrix[trueIdx][predIdx] += 1
    }
    
    return matrix
}

/// Compute ROC AUC score
public func rocAucScore(yTrue: [Int], yScore: [Float]) -> Float {
    precondition(yTrue.count == yScore.count, "Arrays must have same length")
    
    // Sort by score descending
    let sorted = zip(yTrue, yScore).sorted { $0.1 > $1.1 }
    
    let nPositive = yTrue.filter { $0 == 1 }.count
    let nNegative = yTrue.count - nPositive
    
    guard nPositive > 0 && nNegative > 0 else { return 0.5 }
    
    var tpr = [Float]()
    var fpr = [Float]()
    
    var tp = 0, fp = 0
    
    for (label, _) in sorted {
        if label == 1 {
            tp += 1
        } else {
            fp += 1
        }
        tpr.append(Float(tp) / Float(nPositive))
        fpr.append(Float(fp) / Float(nNegative))
    }
    
    // Compute AUC using trapezoidal rule
    var auc: Float = 0
    for i in 1..<fpr.count {
        auc += (fpr[i] - fpr[i-1]) * (tpr[i] + tpr[i-1]) / 2
    }
    
    return auc
}

/// Compute log loss (cross-entropy)
public func logLoss(yTrue: [Int], yProba: [[Float]], eps: Float = 1e-15) -> Float {
    precondition(yTrue.count == yProba.count, "Arrays must have same length")
    
    var loss: Float = 0
    let n = Float(yTrue.count)
    
    for (i, label) in yTrue.enumerated() {
        let proba = max(min(yProba[i][label], 1 - eps), eps)
        loss -= log(proba)
    }
    
    return loss / n
}

// MARK: - Regression Metrics

/// Mean Squared Error
public func meanSquaredError(yTrue: [Float], yPred: [Float]) -> Float {
    precondition(yTrue.count == yPred.count, "Arrays must have same length")
    
    var mse: Float = 0
    for i in 0..<yTrue.count {
        let diff = yTrue[i] - yPred[i]
        mse += diff * diff
    }
    return mse / Float(yTrue.count)
}

/// Root Mean Squared Error
public func rootMeanSquaredError(yTrue: [Float], yPred: [Float]) -> Float {
    sqrt(meanSquaredError(yTrue: yTrue, yPred: yPred))
}

/// Mean Absolute Error
public func meanAbsoluteError(yTrue: [Float], yPred: [Float]) -> Float {
    precondition(yTrue.count == yPred.count, "Arrays must have same length")
    
    var mae: Float = 0
    for i in 0..<yTrue.count {
        mae += abs(yTrue[i] - yPred[i])
    }
    return mae / Float(yTrue.count)
}

/// R² Score (Coefficient of Determination)
public func r2Score(yTrue: [Float], yPred: [Float]) -> Float {
    precondition(yTrue.count == yPred.count, "Arrays must have same length")
    
    let mean = yTrue.reduce(0, +) / Float(yTrue.count)
    
    var ssRes: Float = 0
    var ssTot: Float = 0
    
    for i in 0..<yTrue.count {
        ssRes += (yTrue[i] - yPred[i]) * (yTrue[i] - yPred[i])
        ssTot += (yTrue[i] - mean) * (yTrue[i] - mean)
    }
    
    return ssTot > 0 ? 1 - (ssRes / ssTot) : 0
}

/// Mean Absolute Percentage Error
public func meanAbsolutePercentageError(yTrue: [Float], yPred: [Float], eps: Float = 1e-10) -> Float {
    precondition(yTrue.count == yPred.count, "Arrays must have same length")
    
    var mape: Float = 0
    for i in 0..<yTrue.count {
        mape += abs((yTrue[i] - yPred[i]) / (abs(yTrue[i]) + eps))
    }
    return mape * 100 / Float(yTrue.count)
}

/// Explained Variance Score
public func explainedVarianceScore(yTrue: [Float], yPred: [Float]) -> Float {
    precondition(yTrue.count == yPred.count, "Arrays must have same length")
    
    let n = Float(yTrue.count)
    
    // Compute residuals
    let residuals = zip(yTrue, yPred).map { $0 - $1 }
    let residualMean = residuals.reduce(0, +) / n
    var residualVar: Float = 0
    for r in residuals {
        residualVar += (r - residualMean) * (r - residualMean)
    }
    residualVar /= n
    
    // Compute y variance
    let yMean = yTrue.reduce(0, +) / n
    var yVar: Float = 0
    for y in yTrue {
        yVar += (y - yMean) * (y - yMean)
    }
    yVar /= n
    
    return yVar > 0 ? 1 - (residualVar / yVar) : 0
}

// MARK: - Clustering Metrics

/// Silhouette Score
public func silhouetteScore(x: [[Float]], labels: [Int]) -> Float {
    precondition(x.count == labels.count, "X and labels must have same length")
    
    let n = x.count
    var scores = [Float]()
    
    for i in 0..<n {
        let clusterI = labels[i]
        
        // Compute a(i): mean intra-cluster distance
        var aSum: Float = 0
        var aCount = 0
        
        for j in 0..<n {
            if i != j && labels[j] == clusterI {
                aSum += euclideanDistance(x[i], x[j])
                aCount += 1
            }
        }
        
        let a = aCount > 0 ? aSum / Float(aCount) : 0
        
        // Compute b(i): min mean inter-cluster distance
        let otherClusters = Set(labels).filter { $0 != clusterI }
        var b: Float = .infinity
        
        for otherCluster in otherClusters {
            var bSum: Float = 0
            var bCount = 0
            
            for j in 0..<n {
                if labels[j] == otherCluster {
                    bSum += euclideanDistance(x[i], x[j])
                    bCount += 1
                }
            }
            
            if bCount > 0 {
                b = min(b, bSum / Float(bCount))
            }
        }
        
        if b == .infinity { b = 0 }
        
        let s = (b - a) / max(a, b)
        scores.append(s)
    }
    
    return scores.reduce(0, +) / Float(scores.count)
}

/// Adjusted Rand Index
public func adjustedRandScore(labelsTrue: [Int], labelsPred: [Int]) -> Float {
    precondition(labelsTrue.count == labelsPred.count, "Arrays must have same length")
    
    let n = labelsTrue.count
    let classesTrue = Array(Set(labelsTrue))
    let classesPred = Array(Set(labelsPred))
    
    // Contingency table
    var contingency = [[Int]](repeating: [Int](repeating: 0, count: classesPred.count), count: classesTrue.count)
    
    let trueToIdx = Dictionary(uniqueKeysWithValues: classesTrue.enumerated().map { ($1, $0) })
    let predToIdx = Dictionary(uniqueKeysWithValues: classesPred.enumerated().map { ($1, $0) })
    
    for i in 0..<n {
        contingency[trueToIdx[labelsTrue[i]]!][predToIdx[labelsPred[i]]!] += 1
    }
    
    // Compute sums
    let sumA = contingency.map { $0.reduce(0, +) }
    let sumB = (0..<classesPred.count).map { j in contingency.map { $0[j] }.reduce(0, +) }
    
    // Compute index
    var sumNij2 = 0
    for row in contingency {
        for val in row {
            sumNij2 += val * (val - 1) / 2
        }
    }
    
    var sumA2 = 0
    for val in sumA { sumA2 += val * (val - 1) / 2 }
    
    var sumB2 = 0
    for val in sumB { sumB2 += val * (val - 1) / 2 }
    
    let nC2 = n * (n - 1) / 2
    
    let expectedIndex = Float(sumA2 * sumB2) / Float(nC2)
    let maxIndex = Float(sumA2 + sumB2) / 2
    
    if maxIndex == expectedIndex {
        return 1.0
    }
    
    return (Float(sumNij2) - expectedIndex) / (maxIndex - expectedIndex)
}

/// Davies-Bouldin Index
public func daviesBouldinScore(x: [[Float]], labels: [Int]) -> Float {
    let clusters = Set(labels)
    let k = clusters.count
    
    guard k > 1 else { return 0 }
    
    // Compute cluster centroids and scatter
    var centroids = [[Float]]()
    var scatters = [Float]()
    
    for cluster in clusters.sorted() {
        let clusterPoints = zip(x, labels).filter { $0.1 == cluster }.map { $0.0 }
        let n = clusterPoints.count
        let nFeatures = x[0].count
        
        // Centroid
        var centroid = [Float](repeating: 0, count: nFeatures)
        for point in clusterPoints {
            for j in 0..<nFeatures {
                centroid[j] += point[j]
            }
        }
        centroid = centroid.map { $0 / Float(n) }
        centroids.append(centroid)
        
        // Scatter (average distance to centroid)
        var scatter: Float = 0
        for point in clusterPoints {
            scatter += euclideanDistance(point, centroid)
        }
        scatters.append(scatter / Float(n))
    }
    
    // Compute Davies-Bouldin index
    var db: Float = 0
    
    for i in 0..<k {
        var maxRatio: Float = 0
        for j in 0..<k {
            if i != j {
                let dist = euclideanDistance(centroids[i], centroids[j])
                if dist > 0 {
                    let ratio = (scatters[i] + scatters[j]) / dist
                    maxRatio = max(maxRatio, ratio)
                }
            }
        }
        db += maxRatio
    }
    
    return db / Float(k)
}

// MARK: - Helper

private func euclideanDistance(_ a: [Float], _ b: [Float]) -> Float {
    var sum: Float = 0
    for i in 0..<a.count {
        let diff = a[i] - b[i]
        sum += diff * diff
    }
    return sqrt(sum)
}
