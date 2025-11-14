import Parsing
import RFC_3986
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
        let method: RFC_7231.Method

        /// A parser of GET requests.
        ///
        /// Recognizes both HEAD and GET HTTP methods.
        ///
        /// > Note: If you are using a ``Route`` parser you do not need to specify `Method.get` (it is the
        /// > default).
        nonisolated(unsafe) public static let get = OneOf {
            Self(.head)
            Self(.get)  // NB: Prefer printing "GET"
        }

        /// A parser of POST requests.
        public static let post = Self(.post)

        /// A parser of PUT requests.
        public static let put = Self(.put)

        /// A parser of PATCH requests.
        public static let patch = Self(.patch)

        /// A parser of DELETE requests.
        public static let delete = Self(.delete)

        /// Initializes a request method parser with a method.
        ///
        /// - Parameter method: An HTTP method (e.g., .get, .post, .put, .patch, .delete)
        @inlinable
        public init(_ method: RFC_7231.Method) {
            self.method = method
        }

        @inlinable
        public func parse(_ input: inout RFC_3986.URI.Request.Data) throws {
            guard let inputMethod = input.method else { throw RFC_3986.URI.Routing.Error() }
            guard inputMethod == self.method else { throw RFC_3986.URI.Routing.Error() }
            input.method = nil
        }

        @inlinable
        public func print(_ output: (), into input: inout RFC_3986.URI.Request.Data) {
            input.method = self.method
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
