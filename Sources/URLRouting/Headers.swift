import Foundation
import Parsing
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
    public struct Parser<FieldParsers: Parsing.Parser>: Parsing.Parser
    where FieldParsers.Input == URIRequestData.Fields {
        @usableFromInline
        let fieldParsers: FieldParsers

        @inlinable
        public init(@ParserBuilder<URIRequestData.Fields> build: () -> FieldParsers) {
            self.fieldParsers = build()
        }

        @inlinable
        public init(@ParserBuilder<URIRequestData.Fields> build: () throws -> FieldParsers) rethrows {
            self.fieldParsers = try build()
        }

        @inlinable
        public func parse(_ input: inout URIRequestData) rethrows -> FieldParsers.Output {
            try self.fieldParsers.parse(&input.headers)
        }
    }
}

extension RFC_7230.Header.Parser: ParserPrinter where FieldParsers: ParserPrinter {
    @inlinable
    public func print(_ output: FieldParsers.Output, into input: inout URIRequestData) rethrows {
        try self.fieldParsers.print(output, into: &input.headers)
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
