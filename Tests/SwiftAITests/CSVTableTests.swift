import Foundation
import Testing
@testable import SwiftAI

@Suite("CSVTable")
struct CSVTableTests {
    @Test("Reads a header, numeric features and a text target")
    func classification() throws {
        let table = try CSVTable("""
            length,width,species
            5.1,3.5,setosa
            7.0, 3.2 ,versicolor
            """)
        #expect(table.header == ["length", "width", "species"])
        let data = try table.classificationDataset(target: "species")
        #expect(data.features == [[5.1, 3.5], [7.0, 3.2]])
        #expect(data.targets == ["setosa", "versicolor"])
        #expect(table.featureNames(excluding: "species") == ["length", "width"])
    }

    @Test("The target column can be anywhere and numeric for regression")
    func regression() throws {
        let table = try CSVTable("price;size;rooms\r\n150000;50;1\r\n\r\n240000;80;2\r\n", separator: ";")
        let data = try table.regressionDataset(target: "price")
        #expect(data.features == [[50, 1], [80, 2]])
        #expect(data.targets == [150_000, 240_000])
    }

    @Test("Quoted fields may contain separators, doubled quotes and line breaks")
    func quoting() throws {
        let text = "\"name, full\",x,label\n\"Smith, \"\"J.\"\"\",1,\"two\nlines\"\nplain,2,\"\"\n"
        let table = try CSVTable(text)
        #expect(table.header == ["name, full", "x", "label"])
        #expect(table.rows == [["Smith, \"J.\"", "1", "two\nlines"], ["plain", "2", ""]])
    }

    @Test("Errors name the line and the column")
    func errors() throws {
        #expect(throws: SwiftAIError.invalidCSV(line: 1, reason: "there is no header row")) { try CSVTable("") }
        #expect(throws: SwiftAIError.invalidCSV(line: 3, reason: "the row has 1 fields, but the header has 2")) {
            try CSVTable("a,b\n1,2\n3\n")
        }
        #expect(throws: SwiftAIError.invalidCSV(line: 2, reason: "a quoted field is not closed")) { try CSVTable("a\n\"open\n") }
        #expect(throws: SwiftAIError.invalidCSV(line: 1, reason: "the column name \"a\" appears twice")) { try CSVTable("a,a\n1,2") }

        let table = try CSVTable("x,y\n1,2\nabc,3\n4,nan\n5,1e999\n")
        #expect(throws: SwiftAIError.invalidCSV(line: 3, reason: "the value \"abc\" in column \"x\" is not a finite number")) {
            try table.regressionDataset(target: "y")
        }
        let target = try CSVTable("x,y\n1,2\n2,nan\n")
        #expect(throws: SwiftAIError.invalidCSV(line: 3, reason: "the value \"nan\" in column \"y\" is not a finite number")) {
            try target.regressionDataset(target: "y")
        }
        let huge = try CSVTable("x,y\n1e999,a\n")
        #expect(throws: SwiftAIError.self) { try huge.classificationDataset(target: "y") }
        #expect(throws: SwiftAIError.self) { try table.regressionDataset(target: "missing") }
        #expect(throws: SwiftAIError.emptyDataset) { try CSVTable("y\na\n").classificationDataset(target: "y") }
        #expect(throws: SwiftAIError.self) { try CSVTable("a\n1", separator: "\"") }
    }

    @Test("Reads a UTF-8 file and rejects other encodings")
    func file() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("data.csv")
        try Data("x,label\n1,a\n2,b\n".utf8).write(to: url)
        #expect(try CSVTable(contentsOf: url).classificationDataset(target: "label").count == 2)
        try Data([0x78, 0x0A, 0xFF, 0xFE]).write(to: url)
        #expect(throws: SwiftAIError.self) { try CSVTable(contentsOf: url) }
    }
}
