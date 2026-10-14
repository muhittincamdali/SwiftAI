import Foundation
import Testing
@testable import SwiftAI

/// Runs every README sample from ReadmeExamples.swift and checks what it returns.
@Suite("README samples")
struct ReadmeExamplesTests {
    #if canImport(SwiftUI)
    @MainActor
    @Test("The quick start trains a forest and classifies the new flower")
    func quickStart() {
        let summary = ContentView().irisSummary()
        #expect(summary.hasPrefix("Test accuracy: "))
        #expect(summary.hasSuffix("New flower: virginica"))
    }
    #endif

    @Test("The CSV sample reads six samples with two features")
    func csv() throws {
        let data = try loadCSV()
        #expect(data.count == 6 && data.featureCount == 2)
        #expect(Set(data.targets) == ["setosa", "versicolor", "virginica"])
    }

    @Test("The pipeline sample classifies held-out iris samples")
    func pipeline() throws {
        let report = try scaledClassifier()
        #expect(report.accuracy >= 0.9)
        #expect(report.confusionMatrix.total == 45)
    }

    @Test("The regression sample predicts a price between its neighbours")
    func regression() throws {
        let price = try predictPrice()
        #expect(price > 236_000 && price < 350_000)
    }

    @Test("The cross-validation sample scores three models")
    func crossValidation() throws {
        let results = try compareModels()
        #expect(results.count == 3)
        #expect(results.values.allSatisfy { $0.scores.count == 5 && $0.mean > 0.9 })
    }

    @Test("The saved forest predicts like the original")
    func saveAndLoadSample() throws {
        let loaded = try saveAndLoad()
        let original = try RandomForestClassifier.fit(Dataset.iris, treeCount: 50, seed: 7)
        #expect(loaded == original)
    }

    @Test("The clustering sample finds three groups in two components")
    func clusters() throws {
        let (clusters, explained) = try findClusters()
        #expect(clusters.count == 150 && Set(clusters).count == 3)
        #expect(explained.count == 2 && explained[0] > 0.9)
    }
}
