//
//  PointFree.Parse.swift
//  swift-url-routing
//
//  Top-level `Parse(…)` authoring surface — the pointfree spelling for applying a
//  conversion to consumed input. The institute L1 `Parser.Parse` is a different
//  concept (a parse-strategy accessor), so this top-level `Parse` is a distinct
//  consumer-owned combinator built on the L1 engine (`Rest` + `.map(conversion)`).
//

import RFC_3986

/// Applies a conversion to consumed input.
///
/// Two authoring forms are supported:
///
/// - `Parse(conversion)` consumes the remaining input (a path component's
///   `Substring`, a body's `Data`) and applies the conversion:
///   `Parse(.string)` yields the component as a `String`.
/// - `Parse(conversion) { … }` runs a builder over the routing carrier and maps its
///   output through the conversion: `Parse(.memberwise(Options.init, …)) { Query { … } }`.
public struct Parse<Parsers: Parser.`Protocol`>: Parser.`Protocol` {
    public typealias Input = Parsers.Input
    public typealias Output = Parsers.Output
    public typealias Failure = Parsers.Failure
    public typealias Body = Never

    @usableFromInline
    let parsers: Parsers

    @usableFromInline
    init(_ parsers: Parsers) {
        self.parsers = parsers
    }

    @inlinable
    public func parse(
        _ input: inout Parsers.Input
    ) throws(Parsers.Failure) -> Parsers.Output {
        try self.parsers.parse(&input)
    }
}

// MARK: - Conversion-only form

extension Parse {
    /// Consumes all remaining input and applies the given conversion.
    ///
    /// `Path { Parse(.string) }` reads a whole path component as a `String`.
    @inlinable
    public init<Downstream: Parser.Conversion.`Protocol`>(
        _ conversion: Downstream
    )
    where
        Parsers == Parser.Converted<URLRouting.Rest<Downstream.Input>, Downstream>,
        Downstream.Input: RangeReplaceableCollection
    {
        self.init(URLRouting.Rest<Downstream.Input>().map(conversion))
    }
}

// MARK: - Conversion + builder form

extension Parse {
    /// Runs a builder over the routing carrier and maps its output through the
    /// conversion.
    @inlinable
    public init<Upstream: Parser.`Protocol`, Downstream: Parser.Conversion.`Protocol`>(
        _ conversion: Downstream,
        @URLRouting.Take.Builder<RFC_3986.URI.Request.Data> with build: () -> Upstream
    )
    where
        Parsers == Parser.Converted<Upstream, Downstream>,
        Upstream.Input == RFC_3986.URI.Request.Data,
        Downstream.Input == Upstream.Output
    {
        self.init(build().map(conversion))
    }
}

// MARK: - Printer / Bidirectional

extension Parse: Parser.Printer, Parser.Bidirectional where Parsers: Parser.Bidirectional {
    @inlinable
    public func print(
        _ output: Parsers.Output,
        into input: inout Parsers.Input
    ) throws(Parsers.Failure) {
        try self.parsers.print(output, into: &input)
    }
}

extension Parse: Sendable where Parsers: Sendable {}
