import Foundation
import OrderedCollections
import RFC_3986
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
    public struct Parser<FieldParsers: Parser_Primitive.Parser.`Protocol`>: Parser_Primitive.Parser.`Protocol`
    where FieldParsers.Input == RFC_3986.URI.Request.Fields {
        public typealias Failure = RFC_3986.URI.Routing.Error

        @usableFromInline
        let cookieParsers: FieldParsers

        @inlinable
        public init(@Parser_Primitive.Parser.Builder<RFC_3986.URI.Request.Fields> build: () -> FieldParsers) {
            self.cookieParsers = build()
        }

        @_disfavoredOverload
        @inlinable
        public init(@Parser_Primitive.Parser.Builder<RFC_3986.URI.Request.Fields> build: () throws -> FieldParsers) rethrows {
            self.cookieParsers = try build()
        }

        @inlinable
        public func parse(
            _ input: inout RFC_3986.URI.Request.Data
        ) throws(RFC_3986.URI.Routing.Error) -> FieldParsers.Output {
            guard let cookie = input.headers["cookie"]
            else {
                throw RFC_3986.URI.Routing.Error(
                    component: .header(name: "cookie"),
                    failure: .missing
                )
            }

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

            do {
                return try self.cookieParsers.parse(&fields)
            } catch {
                throw RFC_3986.URI.Routing.Error(
                    component: .header(name: "cookie"),
                    failure: .parseFailed("\(error)")
                )
            }
        }
    }
}

extension RFC_6265.Cookie.Parser: Parser_Primitive.Parser.Bidirectional where FieldParsers: Parser_Primitive.Parser.Bidirectional {
    @inlinable
    public func print(
        _ output: FieldParsers.Output,
        into input: inout RFC_3986.URI.Request.Data
    ) throws(RFC_3986.URI.Routing.Error) {
        var cookies = RFC_3986.URI.Request.Fields()
        do {
            try self.cookieParsers.print(output, into: &cookies)
        } catch {
            throw RFC_3986.URI.Routing.Error(
                component: .header(name: "cookie"),
                failure: .parseFailed("\(error)")
            )
        }

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
