import OrderedCollections
import RFC_3986
import WHATWG_HTML_Forms
import WHATWG_HTML_FormData

// MARK: - Form.Data Field

extension WHATWG_HTML_Forms.Form.Data {
    /// Parses a named field's value for HTML form data.
    ///
    /// Useful for incrementally parsing values from various request fields, including ``Query``
    /// parameters, ``Headers`` and ``Cookies``, and ``FormData``.
    ///
    /// For example, a search endpoint may include a few query items, which can be specified as fields:
    ///
    /// ```swift
    /// Form.Data.Parser {
    ///   Field("name", .string)
    ///   Field("age") { Int.parser() }
    /// }
    /// ```
    public struct Field<Value: Parser.`Protocol`>: Parser.`Protocol` where Value.Input == Substring {
        public typealias Failure = RFC_3986.URI.Routing.Error

        @usableFromInline
        let defaultValue: Value.Output?

        @usableFromInline
        let name: String

        @usableFromInline
        let valueParser: Value

        /// Initializes a named field parser.
        @inlinable
        public init(
            _ name: String,
            default defaultValue: Value.Output? = nil,
            @Parser.Builder<Substring> _ value: () -> Value
        ) {
            self.defaultValue = defaultValue
            self.name = name
            self.valueParser = value()
        }

        /// Initializes a named field parser with a throwing closure.
        @_disfavoredOverload
        @inlinable
        public init(
            _ name: String,
            default defaultValue: Value.Output? = nil,
            @Parser.Builder<Substring> _ value: () throws -> Value
        ) rethrows {
            self.defaultValue = defaultValue
            self.name = name
            self.valueParser = try value()
        }

        /// Initializes a named field parser.
        @inlinable
        public init<C: Parser.Conversion.`Protocol`>(
            _ name: String,
            _ value: C,
            default defaultValue: Value.Output? = nil
        ) where Value == Parser.Converted<URLRouting.Rest<Substring>, C>, C.Input == Substring {
            self.defaultValue = defaultValue
            self.name = name
            self.valueParser = URLRouting.Rest().map(value)
        }

        @inlinable
        public init(
            _ name: String,
            default defaultValue: Value.Output? = nil
        )
        where
            Value == Parser.Converted<URLRouting.Rest<Substring>, Parser.Conversion.String> {
            self.defaultValue = defaultValue
            self.name = name
            self.valueParser = URLRouting.Rest().map(.string)
        }

        @inlinable
        public func parse(
            _ input: inout RFC_3986.URI.Request.Fields
        ) throws(RFC_3986.URI.Routing.Error) -> Value.Output {
            guard
                let wrapped = input[self.name]?.first,
                var value = wrapped
            else {
                guard let defaultValue = self.defaultValue
                else {
                    throw RFC_3986.URI.Routing.Error(
                        component: .body,
                        failure: .missing,
                        context: "Required form field '\(self.name)' not found"
                    )
                }
                return defaultValue
            }

            let output: Value.Output
            do {
                output = try self.valueParser.parse(&value)
            } catch {
                throw RFC_3986.URI.Routing.Error(
                    component: .body,
                    failure: .parseFailed("\(error)"),
                    context: "Form field '\(self.name)'"
                )
            }
            input[self.name]?.removeFirst()
            if input[self.name]?.isEmpty ?? true {
                input[self.name] = nil
            }
            return output
        }
    }
}

extension WHATWG_HTML_Forms.Form.Data.Field: Parser.Bidirectional where Value: Parser.Bidirectional {
    @inlinable
    public func print(
        _ output: Value.Output,
        into input: inout RFC_3986.URI.Request.Fields
    ) throws(RFC_3986.URI.Routing.Error) {
        if let defaultValue = self.defaultValue, Internal.isEqual(output, defaultValue) { return }
        let printed: Substring
        do {
            printed = try self.valueParser.print(output)
        } catch {
            throw RFC_3986.URI.Routing.Error(
                component: .body,
                failure: .parseFailed("\(error)"),
                context: "Form field '\(self.name)'"
            )
        }
        input.fields.updateValue(
            forKey: input.isCaseSensitive ? self.name : self.name.lowercased(),
            insertingDefault: [],
            at: 0,
            with: { $0.prepend(printed) }
        )
    }
}
