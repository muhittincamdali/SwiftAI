import Foundation

/// A table read from comma-separated values, ready to become a ``Dataset``.
///
/// The first row names the columns. Fields may be quoted (`"Smith, J."`), a quote inside a
/// quoted field is doubled (`""`), and quoted fields may span lines. Lines may end in `\n` or
/// `\r\n`; empty lines are skipped.
///
/// ```swift
/// let table = try CSVTable(contentsOf: Bundle.main.url(forResource: "houses", withExtension: "csv")!)
/// let houses = try table.regressionDataset(target: "price")
/// table.featureNames(excluding: "price")   // ["size", "rooms"]
/// ```
public struct CSVTable: Sendable, Equatable {
    /// The column names from the first row.
    public let header: [String]
    /// The data rows, each with one field per column.
    public let rows: [[String]]

    /// Parses CSV text.
    ///
    /// - Parameters:
    ///   - text: The CSV text, header row first.
    ///   - separator: The field separator, for example `;` or a tab.
    /// - Throws: ``SwiftAIError/invalidCSV(line:reason:)`` for a missing header, an unterminated
    ///   quote, duplicate column names or a row with the wrong number of fields.
    public init(_ text: String, separator: Character = ",") throws {
        guard separator != "\"", !separator.isNewline else {
            throw SwiftAIError.invalidParameter(name: "separator", reason: "cannot be a quote or a line break")
        }
        var records = try Self.parse(text, separator: separator)
        guard !records.isEmpty else { throw SwiftAIError.invalidCSV(line: 1, reason: "there is no header row") }
        let header = records.removeFirst().fields.map { $0.trimmingCharacters(in: .whitespaces) }
        if let duplicate = Self.firstDuplicate(header) {
            throw SwiftAIError.invalidCSV(line: 1, reason: "the column name \"\(duplicate)\" appears twice")
        }
        for record in records where record.fields.count != header.count {
            throw SwiftAIError.invalidCSV(
                line: record.line, reason: "the row has \(record.fields.count) fields, but the header has \(header.count)"
            )
        }
        self.header = header
        self.rows = records.map(\.fields)
        self.lines = records.map(\.line)
    }

    /// Reads and parses a UTF-8 CSV file.
    public init(contentsOf url: URL, separator: Character = ",") throws {
        let data = try Data(contentsOf: url)
        guard let text = String(data: data, encoding: .utf8) else {
            throw SwiftAIError.invalidCSV(line: 1, reason: "the file is not UTF-8 text")
        }
        try self.init(text, separator: separator)
    }

    /// The line where each row starts, for error messages.
    private let lines: [Int]

    /// The names of all columns except `target`, in file order.
    public func featureNames(excluding target: String) -> [String] {
        header.filter { $0 != target }
    }

    /// A dataset whose targets are the text of the `target` column, for classification.
    ///
    /// - Throws: ``SwiftAIError/invalidParameter(name:reason:)`` when there is no such column,
    ///   ``SwiftAIError/invalidCSV(line:reason:)`` for a feature that is not a number, and the
    ///   errors of ``Dataset/init(features:targets:)-(Matrix,_)``.
    public func classificationDataset(target: String) throws -> Dataset<String> {
        let column = try columnIndex(target)
        return try Dataset(features: numericFeatures(excluding: column), targets: rows.map { $0[column].trimmingCharacters(in: .whitespaces) })
    }

    /// A dataset whose targets are the numbers in the `target` column, for regression.
    ///
    /// - Throws: The errors of ``classificationDataset(target:)``, also for a target that is not a number.
    public func regressionDataset(target: String) throws -> Dataset<Double> {
        let column = try columnIndex(target)
        // Every column is numeric, so the values are read in file order and the first bad one
        // is reported.
        let numbers = try rows.indices.map { row in try header.indices.map { try number(row: row, column: $0) } }
        let features = numbers.map { values in values.indices.filter { $0 != column }.map { values[$0] } }
        return try Dataset(features: features, targets: numbers.map { $0[column] })
    }

    private func columnIndex(_ name: String) throws -> Int {
        guard let index = header.firstIndex(of: name) else {
            throw SwiftAIError.invalidParameter(name: "target", reason: "there is no column \"\(name)\"; the columns are \(header)")
        }
        return index
    }

    private func numericFeatures(excluding target: Int) throws -> Matrix {
        let columns = header.indices.filter { $0 != target }
        let values = try rows.indices.flatMap { row in
            try columns.map { try number(row: row, column: $0) }
        }
        return Matrix(rows: rows.count, columns: columns.count, values: values)
    }

    /// Parses a finite number. `nan`, `inf` and values that overflow are rejected here with
    /// the line and column, rather than later as a non-finite value.
    private func number(row: Int, column: Int) throws -> Double {
        let text = rows[row][column].trimmingCharacters(in: .whitespaces)
        guard let value = Double(text), value.isFinite else {
            throw SwiftAIError.invalidCSV(
                line: lines[row], reason: "the value \"\(text)\" in column \"\(header[column])\" is not a finite number"
            )
        }
        return value
    }

    private static func firstDuplicate(_ names: [String]) -> String? {
        var seen: Set<String> = []
        return names.first { !seen.insert($0).inserted }
    }

    /// Splits text into records of fields, following RFC 4180. Runs once over the characters.
    private static func parse(_ text: String, separator: Character) throws -> [(line: Int, fields: [String])] {
        var records: [(line: Int, fields: [String])] = []
        var fields: [String] = []
        var field = ""
        var inQuotes = false
        var fieldWasQuoted = false
        var line = 1
        var recordLine = 1
        var characters = text.makeIterator()
        var pending: Character? = characters.next()

        func endRecord() {
            fields.append(field)
            if !(fields.count == 1 && fields[0].isEmpty && !fieldWasQuoted) {
                records.append((recordLine, fields))
            }
            fields = []
            field = ""
            fieldWasQuoted = false
        }

        while let character = pending {
            pending = characters.next()
            if inQuotes {
                if character == "\"" {
                    if pending == "\"" {
                        field.append("\"")
                        pending = characters.next()
                    } else {
                        inQuotes = false
                    }
                } else {
                    if character.isNewline { line += 1 }
                    field.append(character)
                }
            } else if character == "\"" && field.isEmpty {
                inQuotes = true
                fieldWasQuoted = true
            } else if character == separator {
                fields.append(field)
                field = ""
            } else if character.isNewline {
                endRecord()
                line += 1
                recordLine = line
            } else {
                field.append(character)
            }
        }
        guard !inQuotes else { throw SwiftAIError.invalidCSV(line: recordLine, reason: "a quoted field is not closed") }
        if !field.isEmpty || !fields.isEmpty || fieldWasQuoted {
            endRecord()
        }
        return records
    }
}
