import RFC_3986

// MARK: - RFC 3986 URI Routing Extension

extension RFC_3986.URI {
    /// URI routing namespace
    public enum Routing {}
}

// MARK: - RFC 3986 URI Routing Error

extension RFC_3986.URI.Routing {
    /// Routing error with detailed context about what failed
    public struct Error: Swift.Error {
        /// The component that failed during routing
        public let component: Component

        /// The type of failure that occurred
        public let failure: Failure

        /// Additional context about the failure
        public let context: String?

        /// Creates a routing error for a specific request component and failure.
        @inlinable
        public init(component: Component, failure: Failure, context: String? = nil) {
            self.component = component
            self.failure = failure
            self.context = context
        }

        /// Component type that failed
        public enum Component: Sendable {
            case method
            case scheme
            case host
            case port
            case path
            case query
            case fragment
            case header(name: String)
            case cookie(name: String)
            case body
            case request
            case url
        }

        /// Type of failure
        public enum Failure: Sendable {
            case missing
            case mismatch(expected: String, actual: String)
            case invalid(String)
            case parseFailed(String)
        }
    }
}

// MARK: - Convenience Type Alias

/// Convenience type alias for `RFC_3986.URI.Routing.Error`
@usableFromInline
typealias RoutingError = RFC_3986.URI.Routing.Error

// MARK: - Description

extension RFC_3986.URI.Routing.Error: CustomStringConvertible {
    public var description: String {
        var message = "Routing failed for \(componentDescription): \(failureDescription)"
        if let context = context {
            message += " - \(context)"
        }
        return message
    }

    @usableFromInline
    var componentDescription: String {
        switch component {
        case .method: return "HTTP method"
        case .scheme: return "URI scheme"
        case .host: return "host"
        case .port: return "port"
        case .path: return "path"
        case .query: return "query parameters"
        case .fragment: return "fragment"
        case .header(let name): return "header '\(name)'"
        case .cookie(let name): return "cookie '\(name)'"
        case .body: return "request body"
        case .request: return "URLRequest"
        case .url: return "URL"
        }
    }

    @usableFromInline
    var failureDescription: String {
        switch failure {
        case .missing:
            return "missing"
        case .mismatch(let expected, let actual):
            return "expected '\(expected)' but got '\(actual)'"
        case .invalid(let reason):
            return "invalid - \(reason)"
        case .parseFailed(let reason):
            return "parse failed - \(reason)"
        }
    }
}
