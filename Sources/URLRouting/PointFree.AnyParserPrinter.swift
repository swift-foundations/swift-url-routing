//
//  PointFree.AnyParserPrinter.swift
//  swift-url-routing
//
//  Consumer-side type erasure for bidirectional routers — the pointfree
//  `AnyParserPrinter` spelling, built by wrapping the L1 `parse` / `print`
//  operations in closures. No L1 type is introduced: erasure is a consumer concern.
//

import RFC_3986

/// A type-erased ``ParserPrinter``.
///
/// Wraps any concrete ``Parser/Bidirectional`` over the same `Input` / `Output`
/// whose `Failure` is the routing error domain, hiding its identity behind stored
/// `parse` / `print` closures. Use it to store heterogeneous routers uniformly
/// (`any ParserPrinter<Input, Output>`) or to break otherwise-unnameable opaque
/// router types at a composition boundary.
///
/// `Failure` is fixed to `RFC_3986.URI.Routing.Error` to match ``ParserPrinter``'s
/// pinned error domain.
///
/// `AnyParserPrinter` is unconditionally `Sendable` — the stored closures are
/// `@Sendable`, so erasure requires the wrapped router to be `Sendable` (W3 E4;
/// consumers store erased routers inside `Sendable` types and `Dependency.Key`
/// values). Erase a `Sendable` router struct (the production pattern); a composed
/// non-`Sendable` value (e.g. a `.map(.convert(…))` chain over closure-holding
/// conversions) must first be wrapped in a stateless declarative router struct.
///
/// ```swift
/// let erased = router.eraseToAnyParserPrinter()
/// let stored: any ParserPrinter<URLRequestData, Route> = erased
/// ```
public struct AnyParserPrinter<Input, Output>: ParserPrinter, Sendable {
    public typealias Failure = RFC_3986.URI.Routing.Error
    public typealias Body = Never

    @usableFromInline
    let _parse: @Sendable (inout Input) throws(Failure) -> Output

    @usableFromInline
    let _print: @Sendable (Output, inout Input) throws(Failure) -> Void

    @usableFromInline
    init(
        parse: @escaping @Sendable (inout Input) throws(Failure) -> Output,
        print: @escaping @Sendable (Output, inout Input) throws(Failure) -> Void
    ) {
        self._parse = parse
        self._print = print
    }

    @inlinable
    public func parse(_ input: inout Input) throws(Failure) -> Output {
        try self._parse(&input)
    }

    @inlinable
    public func print(_ output: Output, into input: inout Input) throws(Failure) {
        try self._print(output, &input)
    }
}

// MARK: - Erasing initializer

extension AnyParserPrinter {
    /// Erases a concrete bidirectional parser-printer over the routing error domain.
    ///
    /// The router must be `Sendable`: the eraser stores it inside `@Sendable`
    /// closures so the erased value is honestly `Sendable` (W3 E4).
    @inlinable
    public init<P: Parser.Bidirectional & Sendable>(
        _ parserPrinter: P
    ) where P.Input == Input, P.Output == Output, P.Failure == Failure {
        self.init(
            parse: { (input: inout Input) throws(Failure) -> Output in
                try parserPrinter.parse(&input)
            },
            print: { (output: Output, input: inout Input) throws(Failure) -> Void in
                try parserPrinter.print(output, into: &input)
            }
        )
    }
}

// MARK: - Erasure convenience

extension Parser.Bidirectional
where Self: Sendable, Input: Copyable & Escapable, Failure == RFC_3986.URI.Routing.Error {
    /// Erases this parser-printer to an ``AnyParserPrinter``.
    ///
    /// Available on `Sendable` routers only — the erased value stores the router
    /// inside `@Sendable` closures (W3 E4).
    @inlinable
    public func eraseToAnyParserPrinter() -> AnyParserPrinter<Input, Output> {
        AnyParserPrinter(self)
    }
}
