import Foundation
import Parsing
import RFC_3986
import RFC_7230

// MARK: - RFC 7230 Body Extension

extension RFC_7230.Body {
    /// Parser for HTTP message body (RFC 7230 section 3.3)
    ///
    /// Parses a request's body using a byte parser with optional size validation.
    ///
    /// ## Security
    ///
    /// By default, enforces a maximum body size of 10 MiB to prevent denial-of-service
    /// attacks through memory exhaustion. Configure per-route based on requirements.
    ///
    /// Example:
    /// ```swift
    /// struct Comment: Codable {
    ///   var author: String
    ///   var message: String
    /// }
    ///
    /// // Default 10 MiB limit
    /// RFC_7230.Body.Parser(.json(Comment.self))
    ///
    /// // Custom limit for large file uploads
    /// RFC_7230.Body.Parser(
    ///     .json(LargePayload.self),
    ///     maxSize: Measurement(value: 50, unit: .mebibytes)
    /// )
    /// ```
    public struct Parser<Bytes: Parsing.Parser>: Parsing.Parser where Bytes.Input == Data {
        @usableFromInline
        let bytesParser: Bytes

        @usableFromInline
        let maxSize: Measurement<UnitInformationStorage>

        /// Default maximum body size (10 MiB)
        public static var defaultMaxSize: Measurement<UnitInformationStorage> {
            Measurement(value: 10, unit: UnitInformationStorage.mebibytes)
        }

        @inlinable
        public init(
            @ParserBuilder<Data> _ bytesParser: () -> Bytes,
            maxSize: Measurement<UnitInformationStorage> = Parser.defaultMaxSize
        ) {
            self.bytesParser = bytesParser()
            self.maxSize = maxSize
        }

        @_disfavoredOverload
        @inlinable
        public init(
            @ParserBuilder<Data> _ bytesParser: () throws -> Bytes,
            maxSize: Measurement<UnitInformationStorage> = Parser.defaultMaxSize
        ) rethrows {
            self.bytesParser = try bytesParser()
            self.maxSize = maxSize
        }

        /// Initializes a body parser from a byte conversion.
        ///
        /// Useful for parsing a request body in its entirety, for example as a JSON payload.
        ///
        /// - Parameters:
        ///   - bytesConversion: A conversion that transforms bytes into some other type.
        ///   - maxSize: Maximum allowed body size (defaults to 10 MiB)
        @inlinable
        public init<C>(
            _ bytesConversion: C,
            maxSize: Measurement<UnitInformationStorage> = Parser.defaultMaxSize
        )
        where Bytes == Parsers.MapConversion<Parsers.ReplaceError<Rest<Data>>, C> {
            self.bytesParser = Rest().replaceError(with: .init()).map(bytesConversion)
            self.maxSize = maxSize
        }

        /// Initializes a body parser that parses the body as data in its entirety.
        ///
        /// - Parameter maxSize: Maximum allowed body size (defaults to 10 MiB)
        @inlinable
        public init(
            maxSize: Measurement<UnitInformationStorage> = Parser.defaultMaxSize
        ) where Bytes == Parsers.ReplaceError<Rest<Bytes.Input>> {
            self.bytesParser = Rest().replaceError(with: .init())
            self.maxSize = maxSize
        }

        @inlinable
        public func parse(_ input: inout RFC_3986.URI.Request.Data) throws -> Bytes.Output {
            guard var body = input.body
            else {
                throw RFC_3986.URI.Routing.Error(
                    component: .body,
                    failure: .missing
                )
            }

            // Validate body size to prevent DoS attacks
            let maxBytes = Int(maxSize.converted(to: .bytes).value)
            guard body.count <= maxBytes else {
                let actualSize = Measurement(value: Double(body.count), unit: UnitInformationStorage.bytes)
                let formatter = MeasurementFormatter()
                formatter.unitStyle = .short
                throw RFC_3986.URI.Routing.Error(
                    component: .body,
                    failure: .invalid("Body size \(formatter.string(from: actualSize)) exceeds maximum allowed size of \(formatter.string(from: maxSize))")
                )
            }

            let output = try self.bytesParser.parse(&body)
            input.body = body

            return output
        }
    }
}

extension RFC_7230.Body.Parser: ParserPrinter where Bytes: ParserPrinter {
    @inlinable
    public func print(_ output: Bytes.Output, into input: inout RFC_3986.URI.Request.Data) rethrows {
        input.body = try self.bytesParser.print(output)
    }
}

// MARK: - Convenience Type Alias

/// Convenience type alias for `RFC_7230.Body.Parser`
///
/// For cleaner code, you can use `Body` instead of the fully qualified name:
/// ```swift
/// Body(.json(Comment.self))
/// ```
public typealias Body = RFC_7230.Body.Parser

// MARK: - Parser Extension Compatibility

extension Parser where Input == RFC_3986.URI.Request.Data {
    public typealias Body = RFC_7230.Body.Parser
}
