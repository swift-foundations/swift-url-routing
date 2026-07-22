import HTTP_Standard
import RFC_3986

// MARK: - Request Header Routing

extension URLRouting {
    /// Composes HTTP field parsers over a routed request.
    ///
    /// Incrementally parses header fields from an HTTP request.
    ///
    /// ## Example
    ///
    /// ```swift
    /// Headers {
    ///   HTTP.Header.Field.Parser("Content-Type", .string)
    ///   HTTP.Header.Field.Parser("Authorization", .string)
    /// }
    /// ```
    public struct Headers<FieldParsers: Parser_Primitive.Parser.`Protocol`>: Parser_Primitive.Parser.`Protocol`
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

extension URLRouting.Headers: Serializer.`Protocol`, Coder.`Protocol`, Parser_Primitive.Parser.Bidirectional where FieldParsers: Parser_Primitive.Parser.Bidirectional {
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

/// The routing-owned aggregate HTTP header combinator.
///
/// Use `Headers` instead of the fully qualified ``URLRouting/URLRouting/Headers``:
/// ```swift
/// Headers {
///   HTTP.Header.Field.Parser("Content-Type", .string)
/// }
/// ```
public typealias Headers<FieldParsers> = URLRouting.Headers<FieldParsers>
where
    FieldParsers: Parser_Primitive.Parser.`Protocol`,
    FieldParsers.Input == RFC_3986.URI.Request.Fields
