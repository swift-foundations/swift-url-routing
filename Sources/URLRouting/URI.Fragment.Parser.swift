import RFC_3986

// MARK: - RFC 3986 URI Fragment Extension
//
// `RFC_3986.URI.Fragment` is the upstream typed fragment component (rfc-3986
// tip); this file nests the routing parser inside it. (The former local
// `public enum Fragment {}` namespace collided with the upstream type.)

extension RFC_3986.URI.Fragment {
    /// Parser for URI fragment components
    ///
    /// Parses the fragment subcomponent of a URI with a substring parser.
    ///
    /// Example:
    /// ```swift
    /// RFC_3986.URI.Fragment.Parser()  // Parses fragment as string
    /// RFC_3986.URI.Fragment.Parser {  // Parse structured fragment
    ///   "section"
    ///   Digits()
    /// }
    /// ```
    public struct Parser<ValueParser: Parser_Primitive.Parser.`Protocol`>: Parser_Primitive.Parser.`Protocol`
    where ValueParser.Input == Substring {
        public typealias Failure = RFC_3986.URI.Routing.Error

        @usableFromInline
        let valueParser: ValueParser

        /// Initializes a fragment parser that parses the fragment as a string in its entirety.
        @inlinable
        public init()
        where
            ValueParser == Parser_Primitive.Parser.Converted<URLRouting.Rest<Substring>, Parser_Primitive.Parser.Conversion.String> {
            self.valueParser = URLRouting.Rest().map(.string)
        }

        /// Initializes a fragment parser.
        ///
        /// - Parameter value: A parser that parses the fragment's substring value into something
        ///   more well-structured.
        @inlinable
        public init(@Parser_Primitive.Parser.Builder<Substring> value: () -> ValueParser) {
            self.valueParser = value()
        }

        /// Initializes a fragment parser with a throwing closure.
        ///
        /// - Parameter value: A throwing closure that creates a parser for the fragment's substring
        ///   value.
        @inlinable
        public init(@Parser_Primitive.Parser.Builder<Substring> value: () throws -> ValueParser) rethrows {
            self.valueParser = try value()
        }

        /// Initializes a fragment parser.
        ///
        /// - Parameter value: A conversion that transforms the fragment's substring value into
        ///   some other type.
        @inlinable
        public init<C: Parser_Primitive.Parser.Conversion.`Protocol`>(_ value: C)
        where ValueParser == Parser_Primitive.Parser.Converted<URLRouting.Rest<Substring>, C>, C.Input == Substring {
            self.valueParser = URLRouting.Rest().map(value)
        }

        @inlinable
        public func parse(
            _ input: inout RFC_3986.URI.Request.Data
        ) throws(RFC_3986.URI.Routing.Error) -> ValueParser.Output {
            guard var fragment = input.fragment?[...] else {
                throw RFC_3986.URI.Routing.Error(
                    component: .fragment,
                    failure: .missing
                )
            }
            let output: ValueParser.Output
            do {
                output = try self.valueParser.parse(&fragment)
            } catch {
                throw RFC_3986.URI.Routing.Error(component: .fragment, failure: .parseFailed("\(error)"))
            }
            input.fragment = String(fragment)
            return output
        }
    }
}

extension RFC_3986.URI.Fragment.Parser: Serializer.`Protocol`, Coder.`Protocol`, Parser_Primitive.Parser.Bidirectional where ValueParser: Parser_Primitive.Parser.Bidirectional {
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
        _ output: ValueParser.Output,
        into input: inout RFC_3986.URI.Request.Data
    ) throws(RFC_3986.URI.Routing.Error) {
        do {
            input.fragment = String(try self.valueParser.print(output))
        } catch {
            throw RFC_3986.URI.Routing.Error(component: .fragment, failure: .parseFailed("\(error)"))
        }
    }
}

// MARK: - Convenience Type Alias

/// Convenience type alias for `RFC_3986.URI.Fragment.Parser`
///
/// For cleaner code, you can use `URIFragment` instead of the fully qualified name:
/// ```swift
/// URIFragment()  // equivalent to RFC_3986.URI.Fragment.Parser()
/// ```
public typealias URIFragment = RFC_3986.URI.Fragment.Parser
