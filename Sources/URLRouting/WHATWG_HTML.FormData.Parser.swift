import Foundation
import OrderedCollections
import RFC_3986
import WHATWG_HTML_Forms
import WHATWG_HTML_FormData
import WHATWG_Form_URL_Encoded

// MARK: - Form.Data Extension

extension WHATWG_HTML_Forms.Form.Data {
    /// Parser for form-encoded data (application/x-www-form-urlencoded)
    ///
    /// Parses form-encoded data using field parsers.
    ///
    /// This implements the FormData API as defined in the WHATWG HTML Living Standard.
    /// The underlying encoding/decoding uses the application/x-www-form-urlencoded
    /// serialization algorithm from the WHATWG URL Standard.
    ///
    /// Example:
    /// ```swift
    /// Form.Data.Parser {
    ///   Field("username", .string)
    ///   Field("age") { Int.parser() }
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
        public func parse(_ input: inout Foundation.Data) throws(RFC_3986.URI.Routing.Error) -> FieldParsers.Output {
            var fields: FieldParsers.Input = String(decoding: input, as: UTF8.self)
                .split(separator: "&")
                .reduce(into: .init([:], isCaseSensitive: true)) { fields, field in
                    let pair =
                        field
                        .split(separator: "=", maxSplits: 1, omittingEmptySubsequences: false)
                        .compactMap {
                            WHATWG_Form_URL_Encoded.PercentEncoding.decodeOrNil(String($0), plusAsSpace: true)
                        }
                    let name = pair[0]
                    let value = pair.count == 2 ? pair[1][...] : nil
                    fields[name, default: []].append(value)
                }

            let output: FieldParsers.Output
            do {
                output = try self.fieldParsers.parse(&fields)
            } catch {
                throw RFC_3986.URI.Routing.Error(
                    component: .body,
                    failure: .parseFailed("\(error)"),
                    context: "Form data"
                )
            }

            input = .init(encoding: fields)
            return output
        }
    }
}

extension WHATWG_HTML_Forms.Form.Data.Parser: Parser_Primitive.Parser.Bidirectional where FieldParsers: Parser_Primitive.Parser.Bidirectional {
    @inlinable
    public func print(_ output: FieldParsers.Output, into input: inout Foundation.Data) throws(RFC_3986.URI.Routing.Error) {
        var fields = RFC_3986.URI.Request.Fields()
        do {
            try self.fieldParsers.print(output, into: &fields)
        } catch {
            throw RFC_3986.URI.Routing.Error(
                component: .body,
                failure: .parseFailed("\(error)"),
                context: "Form data"
            )
        }
        input = .init(encoding: fields)
    }
}

// MARK: - Convenience Type Alias

/// Convenience type alias for `Form.Data.Parser`
///
/// For cleaner code, you can use `FormData` instead of the fully qualified name:
/// ```swift
/// FormData {
///   Field("username", .string)
/// }
/// ```
public typealias FormData = WHATWG_HTML_Forms.Form.Data.Parser

// MARK: - Data Encoding Extension

extension Foundation.Data {
    @usableFromInline
    init(encoding fields: RFC_3986.URI.Request.Fields) {
        self.init(
            fields
                .flatMap { pair -> [String] in
                    let (name, values) = pair
                    let encodedName = WHATWG_Form_URL_Encoded.PercentEncoding.encode(name, spaceAsPlus: true)

                    return values.compactMap { value in
                        guard let value = value
                        else { return encodedName }

                        let encodedValue = WHATWG_Form_URL_Encoded.PercentEncoding.encode(String(value), spaceAsPlus: true)
                        return "\(encodedName)=\(encodedValue)"
                    }
                }
                .joined(separator: "&")
                .utf8
        )
    }
}
