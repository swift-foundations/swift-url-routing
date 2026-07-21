import RFC_3986

// MARK: - RFC 3986 URI Path Extension
//
// `RFC_3986.URI.Path` is the upstream typed path component (rfc-3986 tip);
// this file nests the routing parser inside it. (The former local
// `public enum Path {}` namespace collided with the upstream type.)

extension RFC_3986.URI.Path {
    /// Parser for URI path components with path traversal protection
    ///
    /// Parses request path components using RFC 3986 rules with security validation.
    /// Incrementally consumes path components from the beginning of a URI path.
    ///
    /// ## Security
    ///
    /// By default, paths are validated to prevent directory traversal attacks:
    /// - Rejects paths containing `..` segments (e.g., `/files/../../etc/passwd`)
    /// - This prevents path traversal vulnerabilities in file system operations
    ///
    /// Use `Path.unchecked { }` to bypass validation for rare legitimate cases.
    ///
    /// ## Example
    ///
    /// ```swift
    /// // Secure by default - rejects ".." segments
    /// try RFC_3986.URI.Path.Parser {
    ///   "users"
    ///   Digits()
    /// }
    /// .match(uri: "/users/42")  // ✅ Works
    /// .match(uri: "/users/../admin")  // ❌ Throws error
    /// ```
    public struct Parser<ComponentParsers: Parser_Primitive.Parser.`Protocol`>: Parser_Primitive.Parser.`Protocol`
    where ComponentParsers.Input == RFC_3986.URI.Request.Data {
        public typealias Failure = RFC_3986.URI.Routing.Error

        @usableFromInline
        let componentParsers: ComponentParsers

        @usableFromInline
        let skipSecurityValidation: Bool

        @inlinable
        public init(@RFC_3986.URI.Path.Builder build: () -> ComponentParsers) {
            self.componentParsers = build()
            self.skipSecurityValidation = false
        }

        @_disfavoredOverload
        @inlinable
        public init(@RFC_3986.URI.Path.Builder build: () throws -> ComponentParsers) rethrows {
            self.componentParsers = try build()
            self.skipSecurityValidation = false
        }

        /// Creates a path parser with security validation disabled.
        ///
        /// - Warning: Only use this when you have a legitimate need for `..` in paths.
        ///   Bypassing validation may expose your application to directory traversal attacks
        ///   if you use path segments in file system operations.
        ///
        /// - Parameter build: A builder closure that constructs the component parsers
        /// - Returns: A parser with security validation disabled
        @inlinable
        public static func unchecked(@RFC_3986.URI.Path.Builder build: () -> ComponentParsers) -> Self {
            Self(componentParsers: build(), skipSecurityValidation: true)
        }

        @_disfavoredOverload
        @inlinable
        public static func unchecked(@RFC_3986.URI.Path.Builder build: () throws -> ComponentParsers) rethrows -> Self {
            Self(componentParsers: try build(), skipSecurityValidation: true)
        }

        @usableFromInline
        init(componentParsers: ComponentParsers, skipSecurityValidation: Bool) {
            self.componentParsers = componentParsers
            self.skipSecurityValidation = skipSecurityValidation
        }

        @inlinable
        public func parse(
            _ input: inout RFC_3986.URI.Request.Data
        ) throws(RFC_3986.URI.Routing.Error) -> ComponentParsers.Output {
            // Validate path security before parsing (unless explicitly bypassed)
            if !skipSecurityValidation {
                try validatePathSecurity(input.path)
            }

            do {
                return try self.componentParsers.parse(&input)
            } catch {
                throw RFC_3986.URI.Routing.Error(component: .path, failure: .parseFailed("\(error)"))
            }
        }

        @usableFromInline
        func validatePathSecurity(_ path: ArraySlice<Substring>) throws(RFC_3986.URI.Routing.Error) {
            for segment in path {
                // Reject parent directory traversal
                if segment == ".." {
                    throw RFC_3986.URI.Routing.Error(
                        component: .path,
                        failure: .invalid("Path contains '..' segment (directory traversal attempt)"),
                        context: "Path: /\(path.joined(separator: "/"))"
                    )
                }
            }
        }
    }
}

extension RFC_3986.URI.Path.Parser: Serializer.`Protocol`, Coder.`Protocol`, Parser_Primitive.Parser.Bidirectional where ComponentParsers: Parser_Primitive.Parser.Bidirectional {
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
    public func serialize(
        _ output: ComponentParsers.Output,
        into input: inout RFC_3986.URI.Request.Data
    ) throws(RFC_3986.URI.Routing.Error) {
        do {
            try self.componentParsers.print(output, into: &input)
        } catch {
            throw RFC_3986.URI.Routing.Error(component: .path, failure: .parseFailed("\(error)"))
        }

        // Validate printed path security (unless explicitly bypassed)
        if !skipSecurityValidation {
            try validatePathSecurity(input.path)
        }
    }
}

// MARK: - Convenience Type Alias

/// Convenience type alias for `RFC_3986.URI.Path.Parser`
///
/// For cleaner code, you can use `URIPath` instead of the fully qualified name:
/// ```swift
/// URIPath {
///   "users"
///   Digits()
/// }
/// ```
public typealias URIPath = RFC_3986.URI.Path.Parser

// MARK: - Sendable Conformance

/// Sendable conformance for Path.Parser.
///
/// Path parsers are conceptually thread-safe as they are immutable value types with no
/// shared mutable state. However, they are marked as @unchecked Sendable because the
/// generic ComponentParsers may contain closures that cannot be verified by the compiler.
///
/// This conformance is safe because:
/// - Path.Parser is a struct with immutable fields
/// - All parsing operations are stateless transformations
/// - No shared mutable state exists
/// - Parsers are composed functionally without side effects
///
/// - Note: Required for Swift 6 strict concurrency mode in server-side applications
/// where routing types must cross actor boundaries.
extension RFC_3986.URI.Path.Parser: @unchecked Sendable where ComponentParsers: Sendable {}
