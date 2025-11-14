import Parsing
import RFC_3986

// MARK: - RFC 3986 URI Fragment Extension

extension RFC_3986.URI {
    /// Fragment component of a URI (RFC 3986 section 3.5)
    ///
    /// The fragment identifier identifies a secondary resource within a primary resource.
    public enum Fragment {}
}

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
    public struct Parser<ValueParser: Parsing.Parser>: Parsing.Parser
    where ValueParser.Input == Substring {

        @usableFromInline
        let valueParser: ValueParser

        /// Initializes a fragment parser that parses the fragment as a string in its entirety.
        @inlinable
        public init()
        where
            ValueParser == Parsers.MapConversion<
                Parsers.ReplaceError<Rest<Substring>>, Conversions.SubstringToString
            > {
            self.valueParser = Rest().replaceError(with: "").map(.string)
        }

        /// Initializes a fragment parser.
        ///
        /// - Parameter value: A parser that parses the fragment's substring value into something
        ///   more well-structured.
        @inlinable
        public init(@ParserBuilder<Substring> value: () -> ValueParser) {
            self.valueParser = value()
        }

        /// Initializes a fragment parser with a throwing closure.
        ///
        /// - Parameter value: A throwing closure that creates a parser for the fragment's substring
        ///   value.
        @inlinable
        public init(@ParserBuilder<Substring> value: () throws -> ValueParser) rethrows {
            self.valueParser = try value()
        }

        /// Initializes a fragment parser.
        ///
        /// - Parameter value: A conversion that transforms the fragment's substring value into
        ///   some other type.
        @inlinable
        public init<C>(_ value: C)
        where ValueParser == Parsers.MapConversion<Parsers.ReplaceError<Rest<Substring>>, C> {
            self.valueParser = Rest().replaceError(with: "").map(value)
        }

        @inlinable
        public func parse(_ input: inout RFC_3986.URI.Request.Data) throws -> ValueParser.Output {
            guard var fragment = input.fragment?[...] else { throw RFC_3986.URI.Routing.Error() }
            let output = try self.valueParser.parse(&fragment)
            input.fragment = String(fragment)
            return output
        }
    }
}

extension RFC_3986.URI.Fragment.Parser: ParserPrinter where ValueParser: ParserPrinter {
    @inlinable
    public func print(_ output: ValueParser.Output, into input: inout RFC_3986.URI.Request.Data) rethrows {
        input.fragment = String(try self.valueParser.print(output))
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
