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

        @inlinable
        init(
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

extension URLRouting.Value: Parser.Printer, Parser.Bidirectional {
    @inlinable
    public func print(_ output: Output, into input: inout Substring) throws(RFC_3986.URI.Routing.Error) {
        input.insert(contentsOf: self._print(output), at: input.startIndex)
    }
}

extension URLRouting.Value: Sendable {}
