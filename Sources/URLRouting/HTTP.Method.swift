import HTTP_Standard
import RFC_3986

// MARK: - RFC 9110 Method Extension

extension HTTP.Method {
    /// Parser for HTTP request methods (RFC 9110 section 9)
    ///
    /// Used to require a particular HTTP method at a particular endpoint.
    ///
    /// ## Example
    ///
    /// ```swift
    /// Route(.case(\.login)) {
    ///   HTTP.Method.Parser.post  // Only route POST requests
    ///   ...
    /// }
    /// ```
    public struct Parser: Parser_Primitive.Parser.Bidirectional, Sendable {
        public typealias Input = RFC_3986.URI.Request.Data
        public typealias Output = Void
        public typealias Failure = RFC_3986.URI.Routing.Error
        public typealias Body = Never

        @usableFromInline
        let method: HTTP.Method

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
        public init(_ method: HTTP.Method) {
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

        /// The emission buffer type — `Parser.Bidirectional` pins `Buffer == Input`.
        public typealias Buffer = RFC_3986.URI.Request.Data

        /// Explicit leaf body: both `Parser.Protocol` and `Serializer.Protocol`
        /// supply a `Body == Never` default getter; the explicit override
        /// disambiguates between the two inherited candidates (the Coder.Witness
        /// precedent).
        @inlinable
        public var body: Never {
            borrowing get { return fatalError("leaf router — serialize(_:into:) is implemented directly") }
        }

        @inlinable
        public func serialize(_ output: Void, into input: inout RFC_3986.URI.Request.Data) {
            input.method = self.method
        }
    }
}

// MARK: - GET (HEAD-or-GET alternative)

extension HTTP.Method.Parser {
    /// A parser-printer that recognizes HEAD or GET and prints GET.
    ///
    /// `Parser.OneOf` requires an `Input.Protocol` linear cursor (parity friction
    /// F1); `RFC_3986.URI.Request.Data` is a structured carrier, not one, so the
    /// two-way choice is hand-rolled: `parse` tries HEAD then GET (a failing
    /// method matcher leaves the input untouched, so no backtracking is needed),
    /// and `print` writes GET.
    public struct Get: Parser_Primitive.Parser.Bidirectional, Sendable {
        public typealias Input = RFC_3986.URI.Request.Data
        public typealias Output = Void
        public typealias Failure = RFC_3986.URI.Routing.Error
        public typealias Body = Never

        @inlinable
        public init() {}

        @inlinable
        public func parse(_ input: inout RFC_3986.URI.Request.Data) throws(RFC_3986.URI.Routing.Error) {
            if (try? HTTP.Method.Parser(.head).parse(&input)) != nil { return }
            if (try? HTTP.Method.Parser(.get).parse(&input)) != nil { return }
            throw RFC_3986.URI.Routing.Error(
                component: .method,
                failure: .mismatch(
                    expected: "GET",
                    actual: input.method?.rawValue ?? "nil"
                )
            )
        }

        /// The emission buffer type — `Parser.Bidirectional` pins `Buffer == Input`.
        public typealias Buffer = RFC_3986.URI.Request.Data

        /// Explicit leaf body: both `Parser.Protocol` and `Serializer.Protocol`
        /// supply a `Body == Never` default getter; the explicit override
        /// disambiguates between the two inherited candidates (the Coder.Witness
        /// precedent).
        @inlinable
        public var body: Never {
            borrowing get { return fatalError("leaf router — serialize(_:into:) is implemented directly") }
        }

        @inlinable
        public func serialize(_ output: Void, into input: inout RFC_3986.URI.Request.Data) {
            // NB: Prefer printing "GET"
            input.method = .get
        }
    }
}

// MARK: - Convenience Type Alias

/// Convenience type alias for `HTTP.Method.Parser`
///
/// For cleaner code, you can use `Method` instead of the fully qualified name:
/// ```swift
/// Method.post  // equivalent to HTTP.Method.Parser.post
/// ```
public typealias Method = HTTP.Method.Parser
