import RFC_3986

// MARK: - RFC 3986 URI Scheme Extension
//
// `RFC_3986.URI.Scheme` is the upstream typed scheme component (rfc-3986 tip);
// this file nests the routing parser inside it. (The former local
// `public enum Scheme {}` namespace collided with the upstream type.)

extension RFC_3986.URI.Scheme {
    /// Parser for URI scheme components
    ///
    /// Parses the scheme component per RFC 3986 section 3.1.
    /// Used to require a particular scheme at a particular endpoint.
    ///
    /// Example:
    /// ```swift
    /// Route(.case(\.custom)) {
    ///   RFC_3986.URI.Scheme.Parser("custom")  // Only route custom:// requests
    ///   ...
    /// }
    /// ```
    public struct Parser: Parser_Primitive.Parser.Bidirectional, Sendable {
        public typealias Input = RFC_3986.URI.Request.Data
        public typealias Output = Void
        public typealias Failure = RFC_3986.URI.Routing.Error
        public typealias Body = Never

        @usableFromInline
        let name: String

        /// A parser of the `http` scheme.
        public static let http = Self("http")

        /// A parser of the `https` scheme.
        public static let https = Self("https")

        /// Initializes a scheme parser with a scheme name.
        ///
        /// - Parameter name: A scheme name per RFC 3986 (ALPHA *( ALPHA / DIGIT / "+" / "-" / "." ))
        @inlinable
        public init(_ name: String) {
            self.name = name
        }

        @inlinable
        public func parse(_ input: inout RFC_3986.URI.Request.Data) throws(RFC_3986.URI.Routing.Error) {
            guard let scheme = input.scheme else {
                throw RFC_3986.URI.Routing.Error(
                    component: .scheme,
                    failure: .missing
                )
            }
            var remaining = scheme[...]
            do {
                try self.name.parse(&remaining)
            } catch {
                throw RFC_3986.URI.Routing.Error(
                    component: .scheme,
                    failure: .mismatch(expected: self.name, actual: scheme)
                )
            }
            input.scheme = nil
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
            input.scheme = self.name
        }
    }
}

// MARK: - Convenience Type Alias

/// Convenience type alias for `RFC_3986.URI.Scheme.Parser`
///
/// For cleaner code, you can use `URIScheme` instead of the fully qualified name:
/// ```swift
/// URIScheme("https")  // equivalent to RFC_3986.URI.Scheme.Parser("https")
/// ```
public typealias URIScheme = RFC_3986.URI.Scheme.Parser
