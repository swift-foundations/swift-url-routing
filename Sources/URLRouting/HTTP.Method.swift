import Parsing
import RFC_7231

// MARK: - RFC 7231 Method Extension

extension RFC_7231.Method {
    /// Parser for HTTP request methods (RFC 7231 section 4)
    ///
    /// Used to require a particular HTTP method at a particular endpoint.
    ///
    /// Example:
    /// ```swift
    /// Route(.case(SiteRoute.login)) {
    ///   RFC_7231.Method.Parser.post  // Only route POST requests
    ///   ...
    /// }
    /// ```
    public struct Parser: ParserPrinter, Sendable {
        @usableFromInline
        let name: String

        /// A parser of GET requests.
        ///
        /// Recognizes both HEAD and GET HTTP methods.
        ///
        /// > Note: If you are using a ``Route`` parser you do not need to specify `Method.get` (it is the
        /// > default).
        nonisolated(unsafe) public static let get = OneOf {
            Self("HEAD")
            Self("GET")  // NB: Prefer printing "GET"
        }

        /// A parser of POST requests.
        public static let post = Self("POST")

        /// A parser of PUT requests.
        public static let put = Self("PUT")

        /// A parser of PATCH requests.
        public static let patch = Self("PATCH")

        /// A parser of DELETE requests.
        public static let delete = Self("DELETE")

        /// Initializes a request method parser with a method name.
        ///
        /// - Parameter name: A method name (e.g., "GET", "POST", "PUT", "PATCH", "DELETE")
        @inlinable
        public init(_ name: String) {
            self.name = name.uppercased()
        }

        @inlinable
        public func parse(_ input: inout URIRequestData) throws {
            guard let method = input.method else { throw RoutingError() }
            try self.name.parse(method)
            input.method = nil
        }

        @inlinable
        public func print(_ output: (), into input: inout URIRequestData) {
            input.method = self.name
        }
    }
}

// MARK: - Convenience Type Alias

/// Convenience type alias for `RFC_7231.Method.Parser`
///
/// For cleaner code, you can use `Method` instead of the fully qualified name:
/// ```swift
/// Method.post  // equivalent to RFC_7231.Method.Parser.post
/// ```
public typealias Method = RFC_7231.Method.Parser
