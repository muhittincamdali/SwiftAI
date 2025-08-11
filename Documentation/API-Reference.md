# API Reference

## Core Classes

### Main Framework

The main entry point for the SwiftAI framework.

```swift
public class SwiftAI {
    public init()
    public func configure()
    public func reset()
}
```

## Configuration

### Options

```swift
public struct Configuration {
    public var debugMode: Bool
    public var logLevel: LogLevel
    public var cacheEnabled: Bool
}
```

## Error Handling

```swift
public enum SwiftAIError: Error {
    case configurationFailed
    case initializationError
    case runtimeError(String)
}
