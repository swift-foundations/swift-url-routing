//
//  URI.Route.Builder.swift
//  swift-url-routing
//
//  A bidirectional sequential parser builder for routing combinators.
//
//  The engine's `Parser.Builder` prefers a parameter-pack tuple-flatten
//  (`Parser.Take.Two.Map`) that is PARSE-ONLY — so a two-value route / query /
//  cookie parser would parse but not print. This builder produces `Parser.Take.Two`
//  directly for the value pair (its `(A, B)` output round-trips), and `Skip.First` /
//  `Skip.Second` for Void-output path literals and matchers. Combinators that must
//  round-trip multi-value output (`RFC_3986.URI.Route`, `RFC_3986.URI.Query.Parser`,
//  `RFC_6265.Cookie.Parser`) opt into it in place of `Parser.Builder`.
//

extension URLRouting {
    /// Namespace for the bidirectional sequential parser builder used by routing
    /// combinators.
    public enum Take {}
}

extension URLRouting.Take {
    /// A bidirectional sequential parser builder over a shared `Input`.
    @resultBuilder
    public enum Builder<Input> {}
}

extension URLRouting.Take.Builder {
    @inlinable
    public static func buildExpression<P: Parser.`Protocol`>(_ parser: P) -> P
    where P.Input == Input {
        parser
    }

    @inlinable
    public static func buildPartialBlock<P: Parser.`Protocol`>(first: P) -> P
    where P.Input == Input {
        first
    }

    /// Skips both a Void-output leading AND trailing parser (two literals / matchers
    /// in a row, e.g. `Method.post` then `Path { "create" }`). More specialized than
    /// either single-`Void` overload below, so it disambiguates their overlap when
    /// both outputs are `Void`; the composite output stays `Void`.
    @inlinable
    public static func buildPartialBlock<Accumulated: Parser.`Protocol`, Next: Parser.`Protocol`>(
        accumulated: Accumulated,
        next: Next
    ) -> Parser.Skip.First<Accumulated, Next>
    where
        Accumulated.Input == Input,
        Next.Input == Input,
        Accumulated.Output == Void,
        Next.Output == Void
    {
        Parser.Skip.First(accumulated, next)
    }

    /// Skips a Void-output leading parser (a path literal / method matcher).
    @inlinable
    public static func buildPartialBlock<Accumulated: Parser.`Protocol`, Next: Parser.`Protocol`>(
        accumulated: Accumulated,
        next: Next
    ) -> Parser.Skip.First<Accumulated, Next>
    where Accumulated.Input == Input, Next.Input == Input, Accumulated.Output == Void {
        Parser.Skip.First(accumulated, next)
    }

    /// Skips a Void-output trailing parser.
    @inlinable
    public static func buildPartialBlock<Accumulated: Parser.`Protocol`, Next: Parser.`Protocol`>(
        accumulated: Accumulated,
        next: Next
    ) -> Parser.Skip.Second<Accumulated, Next>
    where Accumulated.Input == Input, Next.Input == Input, Next.Output == Void {
        Parser.Skip.Second(accumulated, next)
    }

    /// Combines two value-producing parsers bidirectionally.
    @_disfavoredOverload
    @inlinable
    public static func buildPartialBlock<Accumulated: Parser.`Protocol`, Next: Parser.`Protocol`>(
        accumulated: Accumulated,
        next: Next
    ) -> Parser.Take.Two<Accumulated, Next>
    where Accumulated.Input == Input, Next.Input == Input {
        Parser.Take.Two(accumulated, next)
    }
}
