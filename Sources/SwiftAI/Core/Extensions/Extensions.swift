//
//  Extensions.swift
//  SwiftAI
//
//  Created by Muhittin Camdali on 17/08/2024.
//

import Foundation
import SwiftUI
import Combine
import CryptoKit

// MARK: - Data Extensions

extension Data {
    /// Converts Data to hex string representation
    var hexString: String {
        return map { String(format: "%02hhx", $0) }.joined()
    }
    
    /// Creates Data from hex string
    init?(hexString: String) {
        let length = hexString.count / 2
        var data = Data(capacity: length)
        
        for i in 0..<length {
            let start = hexString.index(hexString.startIndex, offsetBy: i * 2)
            let end = hexString.index(start, offsetBy: 2)
            let substring = String(hexString[start..<end])
            
            if let byte = UInt8(substring, radix: 16) {
                data.append(byte)
            } else {
                return nil
            }
        }
        
        self = data
    }
    
    /// Computes SHA-256 hash
    var sha256Hash: String {
        let hash = SHA256.hash(data: self)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    /// Securely overwrites data in memory
    mutating func secureErase() {
        self.withUnsafeMutableBytes { bytes in
            memset(bytes.baseAddress, 0, bytes.count)
        }
    }
    
    /// Compresses data using zlib
    func compressed() throws -> Data {
        return try (self as NSData).compressed(using: .zlib) as Data
    }
    
    /// Decompresses data using zlib
    func decompressed() throws -> Data {
        return try (self as NSData).decompressed(using: .zlib) as Data
    }
}

// MARK: - String Extensions

extension String {
    /// Validates email format
    var isValidEmail: Bool {
        let emailRegex = "^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: self)
    }
    
    /// Validates if string contains only alphanumeric characters
    var isAlphanumeric: Bool {
        return !isEmpty && range(of: "[^a-zA-Z0-9]", options: .regularExpression) == nil
    }
    
    /// Removes whitespaces and newlines
    var trimmed: String {
        return trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// Converts to Data using UTF-8 encoding
    var data: Data {
        return Data(utf8)
    }
    
    /// Capitalizes first letter of each word
    var titleCased: String {
        return replacingOccurrences(of: "([A-Z])", with: " $1", options: .regularExpression, range: range(of: self))
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .capitalized
    }
    
    /// Converts camelCase to snake_case
    var snakeCased: String {
        let acronymPattern = "([A-Z]+)([A-Z][a-z])"
        let normalPattern = "([a-z\\d])([A-Z])"
        return self.processCamelCaseRegex(pattern: acronymPattern)?
            .processCamelCaseRegex(pattern: normalPattern)?
            .lowercased() ?? self.lowercased()
    }
    
    private func processCamelCaseRegex(pattern: String) -> String? {
        let regex = try? NSRegularExpression(pattern: pattern, options: [])
        let range = NSRange(location: 0, length: count)
        return regex?.stringByReplacingMatches(in: self, options: [], range: range, withTemplate: "$1_$2")
    }
    
    /// Validates if string is strong password
    var isStrongPassword: Bool {
        let minLength = 8
        let hasUpperCase = range(of: "[A-Z]", options: .regularExpression) != nil
        let hasLowerCase = range(of: "[a-z]", options: .regularExpression) != nil
        let hasDigit = range(of: "\\d", options: .regularExpression) != nil
        let hasSpecialChar = range(of: "[!@#$%^&*(),.?\":{}|<>]", options: .regularExpression) != nil
        
        return count >= minLength && hasUpperCase && hasLowerCase && hasDigit && hasSpecialChar
    }
    
    /// Sanitizes string for file names
    var sanitizedForFileName: String {
        let invalidChars = CharacterSet(charactersIn: "/<>:\"|?*\\")
        return components(separatedBy: invalidChars).joined(separator: "_")
    }
}

// MARK: - Date Extensions

extension Date {
    /// ISO 8601 string representation
    var iso8601String: String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.string(from: self)
    }
    
    /// Creates date from ISO 8601 string
    init?(iso8601String: String) {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        if let date = formatter.date(from: iso8601String) {
            self = date
        } else {
            // Try without fractional seconds
            formatter.formatOptions = [.withInternetDateTime]
            guard let date = formatter.date(from: iso8601String) else {
                return nil
            }
            self = date
        }
    }
    
    /// Time ago string representation
    var timeAgoString: String {
        let now = Date()
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: self, to: now)
        
        if let years = components.year, years > 0 {
            return "\(years) year\(years == 1 ? "" : "s") ago"
        } else if let months = components.month, months > 0 {
            return "\(months) month\(months == 1 ? "" : "s") ago"
        } else if let days = components.day, days > 0 {
            return "\(days) day\(days == 1 ? "" : "s") ago"
        } else if let hours = components.hour, hours > 0 {
            return "\(hours) hour\(hours == 1 ? "" : "s") ago"
        } else if let minutes = components.minute, minutes > 0 {
            return "\(minutes) minute\(minutes == 1 ? "" : "s") ago"
        } else {
            return "Just now"
        }
    }
    
    /// Checks if date is today
    var isToday: Bool {
        return Calendar.current.isDateInToday(self)
    }
    
    /// Checks if date is yesterday
    var isYesterday: Bool {
        return Calendar.current.isDateInYesterday(self)
    }
    
    /// Start of day
    var startOfDay: Date {
        return Calendar.current.startOfDay(for: self)
    }
    
    /// End of day
    var endOfDay: Date {
        var components = DateComponents()
        components.day = 1
        components.second = -1
        return Calendar.current.date(byAdding: components, to: startOfDay) ?? self
    }
}

// MARK: - DateFormatter Extensions

extension DateFormatter {
    /// Standard ISO 8601 formatter
    static let iso8601Full: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()
    
    /// ISO 8601 formatter without timezone
    static let iso8601WithoutTimezone: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()
    
    /// Standard date formatter
    static let standard: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
    
    /// File-safe date formatter
    static let fileSafe: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        return formatter
    }()
}

// MARK: - URL Extensions

extension URL {
    /// Documents directory URL
    static var documentsDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    /// Caches directory URL
    static var cachesDirectory: URL {
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
    }
    
    /// Temporary directory URL
    static var temporaryDirectory: URL {
        FileManager.default.temporaryDirectory
    }
    
    /// Application support directory URL
    static var applicationSupportDirectory: URL {
        let urls = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        return urls[0]
    }
    
    /// Validates if URL is reachable
    var isReachable: Bool {
        do {
            return try checkResourceIsReachable()
        } catch {
            return false
        }
    }
    
    /// Gets file size in bytes
    var fileSize: Int64 {
        do {
            let resources = try resourceValues(forKeys: [.fileSizeKey])
            return Int64(resources.fileSize ?? 0)
        } catch {
            return 0
        }
    }
    
    /// Gets file creation date
    var creationDate: Date? {
        do {
            let resources = try resourceValues(forKeys: [.creationDateKey])
            return resources.creationDate
        } catch {
            return nil
        }
    }
    
    /// Gets file modification date
    var modificationDate: Date? {
        do {
            let resources = try resourceValues(forKeys: [.contentModificationDateKey])
            return resources.contentModificationDate
        } catch {
            return nil
        }
    }
}

// MARK: - Array Extensions

extension Array {
    /// Safe subscript that returns nil for out-of-bounds indices
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
    
    /// Chunks array into smaller arrays of specified size
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
    
    /// Removes duplicate elements while preserving order
    func removingDuplicates<T: Hashable>(by keyPath: KeyPath<Element, T>) -> [Element] {
        var seen = Set<T>()
        return filter { seen.insert($0[keyPath: keyPath]).inserted }
    }
}

extension Array where Element: Equatable {
    /// Removes all occurrences of element
    mutating func removeAll(_ element: Element) {
        removeAll { $0 == element }
    }
    
    /// Removes duplicate elements
    func removingDuplicates() -> [Element] {
        var result = [Element]()
        for element in self {
            if !result.contains(element) {
                result.append(element)
            }
        }
        return result
    }
}

// MARK: - Dictionary Extensions

extension Dictionary {
    /// Safely gets value by key
    subscript(safe key: Key) -> Value? {
        return self[key]
    }
    
    /// Merges with another dictionary, preferring values from other
    func merging(_ other: [Key: Value]) -> [Key: Value] {
        return merging(other) { _, new in new }
    }
    
    /// Compacts dictionary by removing nil values
    func compactMapValues<T>(_ transform: (Value) throws -> T?) rethrows -> [Key: T] {
        return try compactMapValues(transform)
    }
}

// MARK: - Collection Extensions

extension Collection {
    /// Checks if collection is not empty
    var isNotEmpty: Bool {
        return !isEmpty
    }
    
    /// Safe subscript for indices
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

// MARK: - Publisher Extensions

extension Publisher {
    /// Assigns publisher output to a property with weak capture
    func assignWeak<Root: AnyObject>(
        to keyPath: ReferenceWritableKeyPath<Root, Output>,
        on object: Root
    ) -> AnyCancellable {
        return sink { [weak object] value in
            object?[keyPath: keyPath] = value
        }
    }
    
    /// Retries with exponential backoff
    func retryWithBackoff(
        maxRetries: Int = 3,
        delay: TimeInterval = 1.0,
        multiplier: Double = 2.0
    ) -> AnyPublisher<Output, Failure> {
        return self.catch { error -> AnyPublisher<Output, Failure> in
            guard maxRetries > 0 else {
                return Fail(error: error).eraseToAnyPublisher()
            }
            
            return Just(())
                .delay(for: .seconds(delay), scheduler: DispatchQueue.global())
                .flatMap { _ in
                    self.retryWithBackoff(
                        maxRetries: maxRetries - 1,
                        delay: delay * multiplier,
                        multiplier: multiplier
                    )
                }
                .eraseToAnyPublisher()
        }
        .eraseToAnyPublisher()
    }
    
    /// Debounces and throttles combined
    func debounceAndThrottle<S: Scheduler>(
        for interval: S.SchedulerTimeType.Stride,
        scheduler: S
    ) -> AnyPublisher<Output, Failure> {
        return self
            .debounce(for: interval, scheduler: scheduler)
            .throttle(for: interval, scheduler: scheduler, latest: true)
            .eraseToAnyPublisher()
    }
}

// MARK: - SwiftUI Extensions

extension View {
    /// Applies conditional modifier
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
    
    /// Applies conditional modifier with else clause
    @ViewBuilder
    func `if`<TrueContent: View, FalseContent: View>(
        _ condition: Bool,
        if trueTransform: (Self) -> TrueContent,
        else falseTransform: (Self) -> FalseContent
    ) -> some View {
        if condition {
            trueTransform(self)
        } else {
            falseTransform(self)
        }
    }
    
    /// Hides view based on condition
    @ViewBuilder
    func hidden(_ hidden: Bool) -> some View {
        if hidden {
            self.hidden()
        } else {
            self
        }
    }
    
    /// Adds corner radius to specific corners
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
    
    /// Adds shadow with default parameters
    func defaultShadow() -> some View {
        shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    /// Adds loading overlay
    func loadingOverlay(_ isLoading: Bool) -> some View {
        overlay(
            Group {
                if isLoading {
                    ZStack {
                        Color.black.opacity(0.3)
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.2)
                    }
                }
            }
        )
    }
    
    /// Adds shimmer effect
    func shimmer(active: Bool = true) -> some View {
        modifier(ShimmerModifier(active: active))
    }
}

// MARK: - Color Extensions

extension Color {
    /// Creates color from hex string
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
    
    /// Converts color to hex string
    var hexString: String {
        guard let components = UIColor(self).cgColor.components else { return "#000000" }
        
        let r = Float(components[0])
        let g = Float(components[1])
        let b = Float(components[2])
        
        return String(format: "#%02lX%02lX%02lX",
                     lroundf(r * 255),
                     lroundf(g * 255),
                     lroundf(b * 255))
    }
    
    /// AI-themed colors
    static let aiPrimary = Color(hex: "007AFF")
    static let aiSecondary = Color(hex: "5856D6")
    static let aiAccent = Color(hex: "FF9500")
    static let aiSuccess = Color(hex: "34C759")
    static let aiWarning = Color(hex: "FF9500")
    static let aiDanger = Color(hex: "FF3B30")
    static let aiNeutral = Color(hex: "8E8E93")
}

// MARK: - Supporting Types

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

struct ShimmerModifier: ViewModifier {
    let active: Bool
    @State private var isAnimating = false
    
    func body(content: Content) -> some View {
        content
            .overlay(
                Rectangle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.clear,
                                Color.white.opacity(0.4),
                                Color.clear
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .scaleEffect(x: 3, y: 1)
                    .offset(x: isAnimating ? UIScreen.main.bounds.width : -UIScreen.main.bounds.width)
                    .animation(
                        Animation.linear(duration: 1.5)
                            .repeatForever(autoreverses: false),
                        value: isAnimating
                    )
                    .opacity(active ? 1 : 0)
            )
            .onAppear {
                if active {
                    isAnimating = true
                }
            }
            .onChange(of: active) { newValue in
                isAnimating = newValue
            }
    }
}

// MARK: - UserDefaults Extensions

extension UserDefaults {
    /// Safely stores codable objects
    func setCodable<T: Codable>(_ value: T, forKey key: String) throws {
        let data = try JSONEncoder().encode(value)
        set(data, forKey: key)
    }
    
    /// Safely retrieves codable objects
    func getCodable<T: Codable>(_ type: T.Type, forKey key: String) throws -> T? {
        guard let data = data(forKey: key) else { return nil }
        return try JSONDecoder().decode(type, from: data)
    }
    
    /// Removes value for key
    func removeValue(forKey key: String) {
        removeObject(forKey: key)
    }
}

// MARK: - Bundle Extensions

extension Bundle {
    /// App version string
    var appVersion: String {
        return infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    }
    
    /// Build number string
    var buildNumber: String {
        return infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
    }
    
    /// App name
    var appName: String {
        return infoDictionary?["CFBundleDisplayName"] as? String ??
               infoDictionary?["CFBundleName"] as? String ?? "Unknown"
    }
    
    /// Bundle identifier
    var bundleId: String {
        return bundleIdentifier ?? "Unknown"
    }
}

// MARK: - FileManager Extensions

extension FileManager {
    /// Creates directory if it doesn't exist
    func createDirectoryIfNeeded(at url: URL) throws {
        if !fileExists(atPath: url.path) {
            try createDirectory(at: url, withIntermediateDirectories: true)
        }
    }
    
    /// Gets file size
    func fileSize(at url: URL) -> Int64 {
        do {
            let attributes = try attributesOfItem(atPath: url.path)
            return attributes[.size] as? Int64 ?? 0
        } catch {
            return 0
        }
    }
    
    /// Safely removes item
    func safeRemoveItem(at url: URL) {
        try? removeItem(at: url)
    }
    
    /// Directory size
    func directorySize(at url: URL) -> Int64 {
        guard let enumerator = enumerator(
            at: url,
            includingPropertiesForKeys: [.fileSizeKey],
            options: [],
            errorHandler: nil
        ) else { return 0 }
        
        var totalSize: Int64 = 0
        for case let fileURL as URL in enumerator {
            totalSize += fileSize(at: fileURL)
        }
        
        return totalSize
    }
}

// MARK: - Notification Extensions

extension Notification.Name {
    static let aiModelLoaded = Notification.Name("aiModelLoaded")
    static let aiTrainingStarted = Notification.Name("aiTrainingStarted")
    static let aiTrainingCompleted = Notification.Name("aiTrainingCompleted")
    static let aiInferenceCompleted = Notification.Name("aiInferenceCompleted")
    static let networkStatusChanged = Notification.Name("networkStatusChanged")
    static let performanceMetricsUpdated = Notification.Name("performanceMetricsUpdated")
}

// MARK: - Error Extensions

extension Error {
    /// User-friendly error description
    var userFriendlyDescription: String {
        if let localizedError = self as? LocalizedError {
            return localizedError.errorDescription ?? localizedDescription
        }
        return localizedDescription
    }
    
    /// Error code if available
    var code: Int {
        return (self as NSError).code
    }
    
    /// Error domain
    var domain: String {
        return (self as NSError).domain
    }
}

// MARK: - DispatchQueue Extensions

extension DispatchQueue {
    /// Executes after delay
    static func after(_ delay: TimeInterval, execute work: @escaping () -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: work)
    }
    
    /// Throttles execution
    func throttle(delay: TimeInterval, action: @escaping () -> Void) -> () -> Void {
        var lastFireTime: DispatchTime = .now()
        return {
            let currentTime: DispatchTime = .now()
            if currentTime > lastFireTime + delay {
                lastFireTime = currentTime
                self.async {
                    action()
                }
            }
        }
    }
}

// MARK: - Sequence Extensions

extension Sequence {
    /// Async forEach
    func asyncForEach(_ operation: (Element) async throws -> Void) async rethrows {
        for element in self {
            try await operation(element)
        }
    }
    
    /// Async map
    func asyncMap<T>(_ transform: (Element) async throws -> T) async rethrows -> [T] {
        var results: [T] = []
        for element in self {
            let result = try await transform(element)
            results.append(result)
        }
        return results
    }
    
    /// Async compactMap
    func asyncCompactMap<T>(_ transform: (Element) async throws -> T?) async rethrows -> [T] {
        var results: [T] = []
        for element in self {
            if let result = try await transform(element) {
                results.append(result)
            }
        }
        return results
    }
}