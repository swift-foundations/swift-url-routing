import OrderedCollections
import Parsing
import RFC_3986

// MARK: - RFC 3986 URI Query Field

extension RFC_3986.URI.Query {
    /// Parses a named field's value for URI query parameters.
    ///
    /// Useful for incrementally parsing values from various request fields, including query
    /// parameters, headers and cookies, and form data.
    ///
    /// For example, a search endpoint may include a few query items, which can be specified as fields:
    ///
    /// ```swift
    /// URI.Query.Parser {
    ///   Field("q", .string, default: "")
    ///   Field("page", default: 1) {
    ///     Digits()
    ///   }
    ///   Field("per_page", default: 20) {
    ///     Digits()
    ///   }
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

extension RFC_3986.URI.Query.Field: ParserPrinter where Value: ParserPrinter {
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

// MARK: - Sendable Conformance

/// Sendable conformance for Query.Field.
///
/// Query fields are conceptually thread-safe as they are immutable value types with no
/// shared mutable state. However, they are marked as @unchecked Sendable because the
/// generic Value parser may contain closures that cannot be verified by the compiler.
///
/// This conformance is safe because:
/// - Query.Field is a struct with immutable fields
/// - All parsing operations are stateless transformations
/// - No shared mutable state exists
/// - Fields are used as building blocks in query parsers
///
/// - Note: Required for Swift 6 strict concurrency mode in server-side applications
/// where routing types must cross actor boundaries.
extension RFC_3986.URI.Query.Field: @unchecked Sendable where Value: Sendable {}
