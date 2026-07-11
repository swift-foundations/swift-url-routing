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
    /// Route(.case(\.login)) {
    ///   RFC_7231.Method.Parser.post  // Only route POST requests
    ///   ...
    /// }
    /// ```
    public struct Parser: Parser.Bidirectional, Sendable {
        public typealias Input = RFC_3986.URI.Request.Data
        public typealias Output = Void
        public typealias Failure = RFC_3986.URI.Routing.Error

        @usableFromInline
        let method: RFC_7231.Method

        /// A parser of GET requests.
        ///
        /// Recognizes both HEAD and GET HTTP methods.
        ///
        /// > Note: If you are using a ``Route`` parser you do not need to specify `Method.get` (it is the
        /// > default).
        public static let get = Get()

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
        public func parse(_ input: inout RFC_3986.URI.Request.Data) throws(RFC_3986.URI.Routing.Error) {
            guard let inputMethod = input.method else {
                throw RFC_3986.URI.Routing.Error(
                    component: .method,
                    failure: .missing
                )
            }
            guard inputMethod == self.method else {
                throw RFC_3986.URI.Routing.Error(
                    component: .method,
                    failure: .mismatch(
                        expected: self.method.rawValue,
                        actual: inputMethod.rawValue
                    )
                )
            }
            input.method = nil
        }

        @inlinable
        public func print(_ output: Void, into input: inout RFC_3986.URI.Request.Data) {
            input.method = self.method
        }
    }
}

// MARK: - GET (HEAD-or-GET alternative)

extension RFC_7231.Method.Parser {
    /// A parser-printer that recognizes HEAD or GET and prints GET.
    ///
    /// `Parser.OneOf` requires an `Input.Protocol` linear cursor (parity friction
    /// F1); `RFC_3986.URI.Request.Data` is a structured carrier, not one, so the
    /// two-way choice is hand-rolled: `parse` tries HEAD then GET (a failing
    /// method matcher leaves the input untouched, so no backtracking is needed),
    /// and `print` writes GET.
    public struct Get: Parser.Bidirectional, Sendable {
        public typealias Input = RFC_3986.URI.Request.Data
        public typealias Output = Void
        public typealias Failure = RFC_3986.URI.Routing.Error

        @inlinable
        public init() {}

        @inlinable
        public func parse(_ input: inout RFC_3986.URI.Request.Data) throws(RFC_3986.URI.Routing.Error) {
            if (try? RFC_7231.Method.Parser(.head).parse(&input)) != nil { return }
            if (try? RFC_7231.Method.Parser(.get).parse(&input)) != nil { return }
            throw RFC_3986.URI.Routing.Error(
                component: .method,
                failure: .mismatch(
                    expected: "GET",
                    actual: input.method?.rawValue ?? "nil"
                )
            )
        }

        @inlinable
        public func print(_ output: Void, into input: inout RFC_3986.URI.Request.Data) {
            // NB: Prefer printing "GET"
            input.method = .get
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
