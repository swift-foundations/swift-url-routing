import RFC_3986

// MARK: - RFC 3986 URI Query Extension
//
// `RFC_3986.URI.Query` is the upstream typed query component (rfc-3986 tip);
// this file nests the routing parser inside it. (The former local
// `public enum Query {}` namespace collided with the upstream type.)

extension RFC_3986.URI.Query {
    /// Parser for URI query components
    ///
    /// Parses request query using RFC 3986 rules with field parsers.
    ///
    /// Example:
    /// ```swift
    /// RFC_3986.URI.Query.Parser {
    ///   Field("q", .string, default: "")
    ///   Field("page", default: 1) {
    ///     Digits()
    ///   }
    ///   Field("per_page", default: 20) {
    ///     Digits()
    ///   }
    /// }
    /// ```
    public struct Parser<FieldParsers: Parser_Primitive.Parser.`Protocol`>: Parser_Primitive.Parser.`Protocol`
    where FieldParsers.Input == RFC_3986.URI.Request.Fields {
        public typealias Failure = RFC_3986.URI.Routing.Error

        @usableFromInline
        let fieldParsers: FieldParsers

        @inlinable
        public init(@Parser_Primitive.Parser.Builder<RFC_3986.URI.Request.Fields> build: () -> FieldParsers) {
            self.fieldParsers = build()
        }

        @_disfavoredOverload
        @inlinable
        public init(@Parser_Primitive.Parser.Builder<RFC_3986.URI.Request.Fields> build: () throws -> FieldParsers) rethrows {
            self.fieldParsers = try build()
        }

        @inlinable
        public func parse(
            _ input: inout RFC_3986.URI.Request.Data
        ) throws(RFC_3986.URI.Routing.Error) -> FieldParsers.Output {
            do {
                return try self.fieldParsers.parse(&input.query)
            } catch {
                throw RFC_3986.URI.Routing.Error(component: .query, failure: .parseFailed("\(error)"))
            }
        }
    }
}

extension RFC_3986.URI.Query.Parser: Parser_Primitive.Parser.Printer, Parser_Primitive.Parser.Bidirectional where FieldParsers: Parser_Primitive.Parser.Bidirectional {
    @inlinable
    public func print(
        _ output: FieldParsers.Output,
        into input: inout RFC_3986.URI.Request.Data
    ) throws(RFC_3986.URI.Routing.Error) {
        do {
            try self.fieldParsers.print(output, into: &input.query)
        } catch {
            throw RFC_3986.URI.Routing.Error(component: .query, failure: .parseFailed("\(error)"))
        }
    }
}

// MARK: - Convenience Type Alias

/// Convenience type alias for `RFC_3986.URI.Query.Parser`
///
/// For cleaner code, you can use `URIQuery` instead of the fully qualified name:
/// ```swift
/// URIQuery {
///   Field("q", .string)
/// }
/// ```
public typealias URIQuery = RFC_3986.URI.Query.Parser

// MARK: - Sendable Conformance

/// Sendable conformance for Query.Parser.
///
/// Query parsers are conceptually thread-safe as they are immutable value types with no
/// shared mutable state. However, they are marked as @unchecked Sendable because the
/// generic FieldParsers may contain closures that cannot be verified by the compiler.
///
/// This conformance is safe because:
/// - Query.Parser is a struct with immutable fields
/// - All parsing operations are stateless transformations
/// - No shared mutable state exists
/// - Parsers are composed functionally without side effects
///
/// - Note: Required for Swift 6 strict concurrency mode in server-side applications
/// where routing types must cross actor boundaries.
extension RFC_3986.URI.Query.Parser: @unchecked Sendable where FieldParsers: Sendable {}
