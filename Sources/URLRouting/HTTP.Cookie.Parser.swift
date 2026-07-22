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
        public init(@URLRouting.Take.Builder<RFC_3986.URI.Request.Fields> build: () -> FieldParsers) {
            self.cookieParsers = build()
        }

        @_disfavoredOverload
        @inlinable
        public init(@URLRouting.Take.Builder<RFC_3986.URI.Request.Fields> build: () throws -> FieldParsers) rethrows {
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
                guard let field else { return }
                for pair in RFC_6265.Cookie.parse(skippingInvalidPairs: field).pairs {
                    fields[pair.name, default: []].append(pair.value[...])
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

extension RFC_6265.Cookie.Parser: Serializer.`Protocol`, Coder.`Protocol`, Parser_Primitive.Parser.Bidirectional where FieldParsers: Parser_Primitive.Parser.Bidirectional {
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
        var cookies = RFC_3986.URI.Request.Fields()
        do {
            try self.cookieParsers.print(output, into: &cookies)
        } catch {
            throw RFC_3986.URI.Routing.Error(
                component: .header(name: "cookie"),
                failure: .parseFailed("\(error)")
            )
        }

        let cookie = RFC_6265.Cookie(
            pairs: cookies.flatMap { name, values in
                values.map {
                    RFC_6265.Cookie.Pair(name: name, value: String($0 ?? ""))
                }
            }
        )
        input.headers["cookie", default: []].append(cookie.headerValue[...])
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
