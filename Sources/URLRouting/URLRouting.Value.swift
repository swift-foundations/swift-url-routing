//
//  URLRouting.Value.swift
//  swift-url-routing
//
//  A bidirectional leaf that reads a whole component `Substring` losslessly into a
//  typed value, backing the pointfree `.parser()` factories (`Int.parser()`,
//  `Bool.parser()`, `UUID.parser()`, `RawRepresentable.parser()`).
//

import RFC_3986

extension URLRouting {
    /// A bidirectional parser-printer that reads an entire `Substring` into a typed
    /// `Output` (and prints it back as its string form).
    ///
    /// Parsing consumes the whole input — a routing component is atomic, so a partial
    /// match (e.g. `Int.parser()` against `"123-foo"`) is a failure, not a prefix
    /// consumption.
    public struct Value<Output>: Parser.`Protocol` {
        public typealias Input = Substring
        public typealias Failure = RFC_3986.URI.Routing.Error
        public typealias Body = Never

        @usableFromInline
        let label: Swift.String

        @usableFromInline
        let _parse: @Sendable (Substring) -> Output?

        @usableFromInline
        let _print: @Sendable (Output) -> Swift.String

        /// Creates a whole-component parser-printer from parse and print operations.
        @inlinable
        public init(
            label: Swift.String,
            parse: @escaping @Sendable (Substring) -> Output?,
            print: @escaping @Sendable (Output) -> Swift.String
        ) {
            self.label = label
            self._parse = parse
            self._print = print
        }

        @inlinable
        public func parse(_ input: inout Substring) throws(RFC_3986.URI.Routing.Error) -> Output {
            guard let output = self._parse(input) else {
                throw RFC_3986.URI.Routing.Error(
                    component: .path,
                    failure: .invalid("Could not parse \(self.label) from \"\(input)\"")
                )
            }
            input = input[input.endIndex...]
            return output
        }
    }
}

extension URLRouting.Value: Parser.Bidirectional {
    /// The emission buffer type — `Parser.Bidirectional` pins `Buffer == Input`.
    public typealias Buffer = Substring

    /// Explicit leaf body: both `Parser.Protocol` and `Serializer.Protocol`
    /// supply a `Body == Never` default getter; the explicit override
    /// disambiguates between the two inherited candidates (the Coder.Witness
    /// precedent).
    @inlinable
    public var body: Never {
        borrowing get { return fatalError("leaf router — serialize(_:into:) is implemented directly") }
    }

    @inlinable
    public func serialize(_ output: Output, into input: inout Substring) throws(RFC_3986.URI.Routing.Error) {
        input.append(contentsOf: self._print(output))
    }
}

extension URLRouting.Value: Sendable {}
