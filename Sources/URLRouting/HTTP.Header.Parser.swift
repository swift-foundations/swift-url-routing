import RFC_3986
import RFC_7230

// MARK: - RFC 7230 Header Extension

extension RFC_7230.Header {
    /// Parser for HTTP header fields (RFC 7230 section 3.2)
    ///
    /// Incrementally parses header fields from an HTTP request.
    ///
    /// Example:
    /// ```swift
    /// RFC_7230.Header.Parser {
    ///   Field("Content-Type", .string)
    ///   Field("Authorization", .string)
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
                return try self.fieldParsers.parse(&input.headers)
            } catch {
                throw RFC_3986.URI.Routing.Error(component: .request, failure: .parseFailed("\(error)"))
            }
        }
    }
}

extension RFC_7230.Header.Parser: Serializer.`Protocol`, Coder.`Protocol`, Parser_Primitive.Parser.Bidirectional where FieldParsers: Parser_Primitive.Parser.Bidirectional {
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
        _ output: FieldParsers.Output,
        into input: inout RFC_3986.URI.Request.Data
    ) throws(RFC_3986.URI.Routing.Error) {
        do {
            try self.fieldParsers.print(output, into: &input.headers)
        } catch {
            throw RFC_3986.URI.Routing.Error(component: .request, failure: .parseFailed("\(error)"))
        }
    }
}

// MARK: - Convenience Type Alias

/// Convenience type alias for `RFC_7230.Header.Parser`
///
/// For cleaner code, you can use `Headers` instead of the fully qualified name:
/// ```swift
/// Headers {
///   Field("Content-Type", .string)
/// }
/// ```
public typealias Headers = RFC_7230.Header.Parser
