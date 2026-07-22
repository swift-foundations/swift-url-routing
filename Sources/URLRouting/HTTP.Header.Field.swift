import OrderedCollections
import HTTP_Standard
import RFC_3986

// MARK: - RFC 9110 HTTP Header Field Parser

extension HTTP.Header.Field {
    /// Parses a named field's value for HTTP headers.
    ///
    /// ## Example
    ///
    /// ```swift
    /// Headers {
    ///   Field.Parser("Content-Type", .string)
    ///   Field.Parser("Content-Length") { Int.parser() }
    /// }
    /// ```
    public struct Parser<Value: Parser_Primitive.Parser.`Protocol`>: Parser_Primitive.Parser.`Protocol` where Value.Input == Substring {
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
                        component: .header(name: self.name),
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
                    component: .header(name: self.name),
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

extension HTTP.Header.Field.Parser: Serializer.`Protocol`, Coder.`Protocol`, Parser_Primitive.Parser.Bidirectional where Value: Parser_Primitive.Parser.Bidirectional {
    /// The emission buffer type — `Parser.Bidirectional` pins `Buffer == Input`.
    public typealias Buffer = RFC_3986.URI.Request.Fields

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
        _ output: Value.Output,
        into input: inout RFC_3986.URI.Request.Fields
    ) throws(RFC_3986.URI.Routing.Error) {
        if let defaultValue = self.defaultValue, Internal.isEqual(output, defaultValue) { return }

        // Print the value
        let printedValue: Substring
        do {
            printedValue = try self.valueParser.print(output)
        } catch {
            throw RFC_3986.URI.Routing.Error(
                component: .header(name: self.name),
                failure: .parseFailed("\(error)")
            )
        }

        // Validate against CRLF injection per RFC 9110 §5.5 (prevents header injection).
        do {
            _ = try HTTP.Header.Field.Value(String(printedValue))
        } catch {
            throw RFC_3986.URI.Routing.Error(
                component: .header(name: self.name),
                failure: .invalid("\(error)")
            )
        }

        input.fields.updateValue(
            forKey: input.isCaseSensitive ? self.name : self.name.lowercased(),
            insertingDefault: [],
            at: input.fields.count,
            with: { $0.append(printedValue) }
        )
    }
}

// MARK: - ContentType Convenience Parser

extension HTTP.Header {
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
    public struct ContentType<Value: Parser_Primitive.Parser.`Protocol`>: Parser_Primitive.Parser.`Protocol` where Value.Input == Substring {
        public typealias Failure = RFC_3986.URI.Routing.Error

        @usableFromInline
        let valueParser: HTTP.Header.Field.Parser<Value>

        /// Initializes a Content-Type header parser.
        @inlinable
        public init(@Parser_Primitive.Parser.Builder<Substring> _ value: () -> Value) {
            self.valueParser = HTTP.Header.Field.Parser("Content-Type", value)
        }

        /// Initializes a Content-Type header parser with a throwing closure.
        @_disfavoredOverload
        @inlinable
        public init(@Parser_Primitive.Parser.Builder<Substring> _ value: () throws -> Value) rethrows {
            self.valueParser = try HTTP.Header.Field.Parser("Content-Type", value)
        }

        @inlinable
        public func parse(
            _ input: inout RFC_3986.URI.Request.Fields
        ) throws(RFC_3986.URI.Routing.Error) -> Value.Output {
            try self.valueParser.parse(&input)
        }
    }
}

extension HTTP.Header.ContentType: Serializer.`Protocol`, Coder.`Protocol`, Parser_Primitive.Parser.Bidirectional where Value: Parser_Primitive.Parser.Bidirectional {
    /// The emission buffer type — `Parser.Bidirectional` pins `Buffer == Input`.
    public typealias Buffer = RFC_3986.URI.Request.Fields

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
        _ output: Value.Output,
        into input: inout RFC_3986.URI.Request.Fields
    ) throws(RFC_3986.URI.Routing.Error) {
        try self.valueParser.print(output, into: &input)
    }
}

/// Convenience typealias for `HTTP.Header.ContentType`
///
/// For cleaner code within Headers blocks:
/// ```swift
/// Headers {
///     ContentType { "multipart/form-data" }
/// }
/// ```
public typealias ContentType = HTTP.Header.ContentType
