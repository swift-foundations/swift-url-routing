import OrderedCollections
import RFC_3986
import RFC_6265

// MARK: - RFC 6265 HTTP Cookie Field

extension RFC_6265.Cookie {
    /// Parses a named field's value for HTTP cookies.
    ///
    /// Useful for incrementally parsing values from HTTP cookies as defined in RFC 6265.
    ///
    /// For example, a cookie parser may include a few fields:
    ///
    /// ```swift
    /// RFC_6265.Cookie.Parser {
    ///   Field("session", .string)
    ///   Field("userId") { Int.parser() }
    ///   Field("page", default: 1) {
    ///     Digits()
    ///   }
    /// }
    /// ```
    public struct Field<Value: Parser_Primitive.Parser.`Protocol`>: Parser_Primitive.Parser.`Protocol` where Value.Input == Substring {
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
            @Parser_Primitive.Parser.Builder<Substring> _ value: () -> Value
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
            @Parser_Primitive.Parser.Builder<Substring> _ value: () throws -> Value
        ) rethrows {
            self.defaultValue = defaultValue
            self.name = name
            self.valueParser = try value()
        }

        /// Initializes a named field parser.
        @inlinable
        public init<C: Parser_Primitive.Parser.Conversion.`Protocol`>(
            _ name: String,
            _ value: C,
            default defaultValue: Value.Output? = nil
        ) where Value == Parser_Primitive.Parser.Converted<URLRouting.Rest<Substring>, C>, C.Input == Substring {
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
            Value == Parser_Primitive.Parser.Converted<URLRouting.Rest<Substring>, Parser_Primitive.Parser.Conversion.String> {
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
                        component: .cookie(name: self.name),
                        failure: .missing
                    )
                }
                return defaultValue
            }

            let output: Value.Output
            do {
                output = try self.valueParser.parse(&value)
            } catch {
                throw RFC_3986.URI.Routing.Error(
                    component: .cookie(name: self.name),
                    failure: .parseFailed("\(error)")
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

extension RFC_6265.Cookie.Field: Parser_Primitive.Parser.Bidirectional where Value: Parser_Primitive.Parser.Bidirectional {
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
                component: .cookie(name: self.name),
                failure: .parseFailed("\(error)")
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
