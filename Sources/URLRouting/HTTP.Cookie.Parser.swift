import Foundation
import OrderedCollections
import Parsing
import RFC_6265

// MARK: - RFC 6265 Cookie Extension

extension RFC_6265.Cookie {
    /// Parser for HTTP cookies (RFC 6265)
    ///
    /// Parses cookies from the Cookie header field.
    ///
    /// Example:
    /// ```swift
    /// RFC_6265.Cookie.Parser {
    ///   Field("session_id", .string)
    ///   Field("user_id") { Int.parser() }
    /// }
    /// ```
    public struct Parser<FieldParsers: Parsing.Parser>: Parsing.Parser
    where FieldParsers.Input == URIRequestData.Fields {
        @usableFromInline
        let cookieParsers: FieldParsers

        @inlinable
        public init(@ParserBuilder<URIRequestData.Fields> build: () -> FieldParsers) {
            self.cookieParsers = build()
        }

        @inlinable
        public init(@ParserBuilder<URIRequestData.Fields> build: () throws -> FieldParsers) rethrows {
            self.cookieParsers = try build()
        }

        @inlinable
        public func parse(_ input: inout URIRequestData) throws -> FieldParsers.Output {
            guard let cookie = input.headers["cookie"]
            else { throw RoutingError() }

            var fields: FieldParsers.Input = cookie.reduce(
                into: .init([:], isCaseSensitive: true)
            ) { fields, field in
                guard let cookies = field?.components(separatedBy: "; ")
                else { return }

                for cookie in cookies {
                    let pair = cookie.split(
                        separator: "=",
                        maxSplits: 1,
                        omittingEmptySubsequences: false
                    )
                    guard pair.count == 2 else { continue }
                    fields[String(pair[0]), default: []].append(pair[1])
                }
            }

            return try self.cookieParsers.parse(&fields)
        }
    }
}

extension RFC_6265.Cookie.Parser: ParserPrinter where FieldParsers: ParserPrinter {
    @inlinable
    public func print(_ output: FieldParsers.Output, into input: inout URIRequestData) rethrows {
        var cookies = URIRequestData.Fields()
        try self.cookieParsers.print(output, into: &cookies)

        input.headers["cookie", default: []].prepend(
            cookies
                .flatMap { name, values in values.map { "\(name)=\($0 ?? "")" } }
                .joined(separator: "; ")[...]
        )
    }
}

// MARK: - Convenience Type Alias

/// Convenience type alias for `RFC_6265.Cookie.Parser`
///
/// For cleaner code, you can use `Cookies` instead of the fully qualified name:
/// ```swift
/// Cookies {
///   Field("session_id", .string)
/// }
/// ```
public typealias Cookies = RFC_6265.Cookie.Parser
