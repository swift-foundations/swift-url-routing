//
//  PointFree.OneOf.swift
//  swift-url-routing
//
//  Top-level `OneOf { … }` ordered-choice authoring surface.
//
//  The institute L1 `Parser.OneOf` combinator requires an `Input.Protocol` linear
//  cursor to backtrack (parity friction F1); the routing carrier
//  `RFC_3986.URI.Request.Data` is a structured value, not a cursor. So this OneOf is
//  consumer-owned: it backtracks by value copy (the carrier is `Copyable`) — save the
//  input, try an alternative, restore on failure and try the next. Printing likewise
//  tries each alternative's printer until one accepts the output (a `.case` router
//  whose conversion rejects the output raises, prompting the next alternative).
//

/// Runs a number of parsers as ordered alternatives, trying each until one succeeds.
///
/// ```swift
/// OneOf {
///     Route(.case(Route.cases.home))
///     Route(.case(Route.cases.detail)) { Path { Int.parser() } }
/// }
/// ```
public struct OneOf<Input, Output, Alternatives: Parser.`Protocol`>: Parser.`Protocol`
where Alternatives.Input == Input, Alternatives.Output == Output {
    public typealias Failure = Alternatives.Failure
    public typealias Body = Never

    @usableFromInline
    let alternatives: Alternatives

    @inlinable
    public init(
        @URLRouting.OrderedChoice.Builder<Input, Output> _ build: () -> Alternatives
    ) {
        self.alternatives = build()
    }

    @inlinable
    public func parse(_ input: inout Input) throws(Alternatives.Failure) -> Output {
        try self.alternatives.parse(&input)
    }
}

extension OneOf: Serializer.`Protocol`, Coder.`Protocol`, Parser.Bidirectional where Alternatives: Parser.Bidirectional {
    /// The emission buffer type — `Parser.Bidirectional` pins `Buffer == Input`.
    public typealias Buffer = Input

    /// Explicit leaf body: both `Parser.Protocol` and `Serializer.Protocol`
    /// supply a `Body == Never` default getter; the explicit override
    /// disambiguates between the two inherited candidates (the Coder.Witness
    /// precedent).
    @inlinable
    public var body: Never {
        borrowing get { return fatalError("leaf router — serialize(_:into:) is implemented directly") }
    }

    @inlinable
    public func serialize(_ output: Output, into input: inout Input) throws(Alternatives.Failure) {
        try self.alternatives.print(output, into: &input)
    }
}

extension OneOf: Sendable where Alternatives: Sendable {}

// MARK: - Ordered-choice machinery

extension URLRouting {
    /// Namespace for the value-backtracking ordered-choice combinator that backs
    /// ``OneOf``.
    public enum OrderedChoice {}
}

extension URLRouting.OrderedChoice {
    /// A two-way ordered choice that backtracks by value copy.
    public struct Of<P0: Parser.`Protocol`, P1: Parser.`Protocol`>: Parser.`Protocol`
    where
        P0.Input == P1.Input,
        P0.Output == P1.Output,
        P0.Failure == P1.Failure,
        P0.Input: Copyable
    {
        public typealias Input = P0.Input
        public typealias Output = P0.Output
        public typealias Failure = P0.Failure
        public typealias Body = Never

        @usableFromInline let p0: P0
        @usableFromInline let p1: P1

        @usableFromInline
        init(_ p0: P0, _ p1: P1) {
            self.p0 = p0
            self.p1 = p1
        }

        @inlinable
        public func parse(_ input: inout P0.Input) throws(P0.Failure) -> P0.Output {
            let saved = input
            do {
                return try self.p0.parse(&input)
            } catch {
                input = saved
                return try self.p1.parse(&input)
            }
        }
    }
}

extension URLRouting.OrderedChoice.Of: Serializer.`Protocol`, Coder.`Protocol`, Parser.Bidirectional
where P0: Parser.Bidirectional, P1: Parser.Bidirectional {
    /// The emission buffer type — `Parser.Bidirectional` pins `Buffer == Input`.
    public typealias Buffer = P0.Input

    /// Explicit leaf body: both `Parser.Protocol` and `Serializer.Protocol`
    /// supply a `Body == Never` default getter; the explicit override
    /// disambiguates between the two inherited candidates (the Coder.Witness
    /// precedent).
    @inlinable
    public var body: Never {
        borrowing get { return fatalError("leaf router — serialize(_:into:) is implemented directly") }
    }

    @inlinable
    public func serialize(_ output: P0.Output, into input: inout P0.Input) throws(P0.Failure) {
        let saved = input
        do {
            try self.p0.print(output, into: &input)
        } catch {
            input = saved
            try self.p1.print(output, into: &input)
        }
    }
}

extension URLRouting.OrderedChoice.Of: Sendable where P0: Sendable, P1: Sendable {}

extension URLRouting.OrderedChoice {
    /// Result builder combining ordered-choice alternatives.
    @resultBuilder
    public enum Builder<Input, Output> {}
}

extension URLRouting.OrderedChoice.Builder {
    @inlinable
    public static func buildPartialBlock<P: Parser.`Protocol`>(
        first: P
    ) -> P where P.Input == Input, P.Output == Output {
        first
    }

    @inlinable
    public static func buildPartialBlock<Accumulated: Parser.`Protocol`, Next: Parser.`Protocol`>(
        accumulated: Accumulated,
        next: Next
    ) -> URLRouting.OrderedChoice.Of<Accumulated, Next>
    where
        Accumulated.Input == Input,
        Next.Input == Input,
        Accumulated.Output == Output,
        Next.Output == Output,
        Accumulated.Failure == Next.Failure,
        Input: Copyable
    {
        .init(accumulated, next)
    }
}
