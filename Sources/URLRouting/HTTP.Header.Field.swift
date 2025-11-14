import OrderedCollections
import Parsing
import RFC_3986
import RFC_7230

// MARK: - RFC 7230 HTTP Header Field

extension RFC_7230.Header {
    /// Parses a named field's value for HTTP headers.
    ///
    /// Example:
    /// ```swift
    /// HTTP.Header.Parser {
    ///   Field("Content-Type", .string)
    ///   Field("Content-Length") { Int.parser() }
    /// }
    /// ```
    public struct Field<Value: Parsing.Parser>: Parsing.Parser where Value.Input == Substring {
        @usableFromInline
        let defaultValue: Value.Output?

        @usableFromInline
        let name: String

        @usableFromInline
        let valueParser: Value

        /// Initializes a named field parser.
        ///
        /// - Parameters:
        ///   - name: The name of the field.
        ///   - defaultValue: A default value if the field is absent. Prefer specifying a default over
        ///     applying `Parser.replaceError(with:)` if parsing should fail for invalid values.
        ///   - value: A parser that parses the field's substring value into something more
        ///     well-structured.
        @inlinable
        public init(
            _ name: String,
            default defaultValue: Value.Output? = nil,
            @ParserBuilder<Substring> _ value: () -> Value
        ) {
            self.defaultValue = defaultValue
            self.name = name
            self.valueParser = value()
        }

        /// Initializes a named field parser with a throwing closure.
        ///
        /// This overload allows using throwing factory functions within the parser builder.
        ///
        /// - Parameters:
        ///   - name: The name of the field.
        ///   - defaultValue: A default value if the field is absent. Prefer specifying a default over
        ///     applying `Parser.replaceError(with:)` if parsing should fail for invalid values.
        ///   - value: A throwing closure that creates a parser for the field's substring value.
        @_disfavoredOverload
        @inlinable
        public init(
            _ name: String,
            default defaultValue: Value.Output? = nil,
            @ParserBuilder<Substring> _ value: () throws -> Value
        ) rethrows {
            self.defaultValue = defaultValue
            self.name = name
            self.valueParser = try value()
        }

        /// Initializes a named field parser.
        ///
        /// - Parameters:
        ///   - name: The name of the field.
        ///   - value: A conversion that transforms the field's substring value into something more
        ///     well-structured.
        ///   - defaultValue: A default value if the field is absent. Prefer specifying a default over
        ///     applying `Parser.replaceError(with:)` if parsing should fail for invalid values.
        @inlinable
        public init<C>(
            _ name: String,
            _ value: C,
            default defaultValue: Value.Output? = nil
        ) where Value == Parsers.MapConversion<Parsers.ReplaceError<Rest<Substring>>, C> {
            self.defaultValue = defaultValue
            self.name = name
            self.valueParser = Rest().replaceError(with: "").map(value)
        }

        @inlinable
        public init(
            _ name: String,
            default defaultValue: Value.Output? = nil
        )
        where
            Value == Parsers.MapConversion<
                Parsers.ReplaceError<Rest<Substring>>, Conversions.SubstringToString
            > {
            self.defaultValue = defaultValue
            self.name = name
            self.valueParser = Rest().replaceError(with: "").map(.string)
        }

        /// Initializes a named field parser with an RFC_2045.ContentType value.
        ///
        /// - Parameters:
        ///   - name: The name of the field
        ///   - contentType: The ContentType value to match/print
        ///   - defaultValue: A default value if the field is absent
        @inlinable
        public init(
            _ name: String,
            _ contentType: RFC_2045.ContentType,
            default defaultValue: Value.Output? = nil
        )
        where
            Value == Parsers.MapConversion<
                Parsers.ReplaceError<Rest<Substring>>, Conversions.SubstringToString
            > {
            self.defaultValue = defaultValue
            self.name = name
            self.valueParser = Rest().replaceError(with: "").map(.string)
        }

        @inlinable
        public func parse(_ input: inout RFC_3986.URI.Request.Fields) throws -> Value.Output {
            guard
                let wrapped = input[self.name]?.first,
                var value = wrapped
            else {
                guard let defaultValue = self.defaultValue
                else { throw RFC_3986.URI.Routing.Error() }
                return defaultValue
            }

            let output = try self.valueParser.parse(&value)
            input[self.name]?.removeFirst()
            if input[self.name]?.isEmpty ?? true {
                input[self.name] = nil
            }
            return output
        }
    }
}

extension RFC_7230.Header.Field: ParserPrinter where Value: ParserPrinter {
    @inlinable
    public func print(_ output: Value.Output, into input: inout RFC_3986.URI.Request.Fields) rethrows {
        if let defaultValue = self.defaultValue, Internal.isEqual(output, defaultValue) { return }
        try input.fields.updateValue(
            forKey: input.isCaseSensitive ? self.name : self.name.lowercased(),
            insertingDefault: [],
            at: 0,
            with: { $0.prepend(try self.valueParser.print(output)) }
        )
    }
}

// MARK: - ContentType Convenience Parser

extension RFC_7230.Header {
    /// Convenience parser for Content-Type header field.
    ///
    /// Use this within a `Headers` block to parse the Content-Type header.
    ///
    /// ## Example
    ///
    /// ```swift
    /// Headers {
    ///     ContentType { "multipart/form-data" }
    ///     ContentType { multipart.contentType.headerValue }
    ///     ContentType { Prefix { $0 != ";" } }
    /// }
    /// ```
    public struct ContentType<Value: Parsing.Parser>: Parsing.Parser where Value.Input == Substring {
        @usableFromInline
        let valueParser: RFC_7230.Header.Field<Value>

        /// Initializes a Content-Type header parser.
        ///
        /// - Parameter value: A parser builder closure for the content type value
        @inlinable
        public init(@ParserBuilder<Substring> _ value: () -> Value) {
            self.valueParser = RFC_7230.Header.Field("Content-Type", value)
        }

        /// Initializes a Content-Type header parser with a throwing closure.
        ///
        /// - Parameter value: A throwing parser builder closure for the content type value
        @_disfavoredOverload
        @inlinable
        public init(@ParserBuilder<Substring> _ value: () throws -> Value) rethrows {
            self.valueParser = try RFC_7230.Header.Field("Content-Type", value)
        }

        @inlinable
        public func parse(_ input: inout RFC_3986.URI.Request.Fields) throws -> Value.Output {
            try self.valueParser.parse(&input)
        }
    }
}

extension RFC_7230.Header.ContentType: ParserPrinter where Value: ParserPrinter {
    @inlinable
    public func print(_ output: Value.Output, into input: inout RFC_3986.URI.Request.Fields) rethrows {
        try self.valueParser.print(output, into: &input)
    }
}

/// Convenience typealias for `RFC_7230.Header.ContentType`
///
/// For cleaner code within Headers blocks:
/// ```swift
/// Headers {
///     ContentType { "multipart/form-data" }
/// }
/// ```
public typealias ContentType = RFC_7230.Header.ContentType
