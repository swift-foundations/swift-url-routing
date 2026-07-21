//
//  ParserPrinter.swift
//  swift-url-routing
//
//  The consumer-facing authoring protocol: a bidirectional parser-printer whose
//  Input / Output are the primary associated types, re-exposing the institute L1
//  `Parser.Bidirectional` engine under the pointfree-compatible `ParserPrinter`
//  spelling.
//

import RFC_3986

// MARK: - ParserPrinter

/// A type that can both parse an `Input` into an `Output` and print an `Output`
/// back into an `Input`.
///
/// `ParserPrinter` is the pointfree-compatible authoring surface over the institute
/// L1 engine: it refines ``Parser/Bidirectional`` and re-exposes `Input` / `Output`
/// as its primary associated types, so a router can be stored as the two-parameter
/// existential `any ParserPrinter<Input, Output>`.
///
/// ## Fixed error domain
///
/// `Failure` is pinned to `RFC_3986.URI.Routing.Error` — the single error domain of
/// the routing surface (every combinator and `Method` matcher already fails into
/// it; so do the credential routers now vended by swift-url-routing-authentication). Pinning it is not merely a convenience: `Input` / `Output`
/// are primary associated types with no default, so associated-type inference derives
/// them from `body`; the `Failure` associated type, however, inherits a `Never` default
/// from ``Parser/Protocol`` that would short-circuit inference to `Never` and leave a
/// declarative router non-conforming (the engine's declarative `parse` default requires
/// `Body.Failure == Failure`). Fixing `Failure` to the domain error removes the default's
/// interference and lets `body`-only routers conform with no per-type `typealias`.
///
/// A router declares its grammar declaratively via ``Parser/Protocol/body-swift.property``:
///
/// ```swift
/// struct AppRouter: ParserPrinter {
///     var body: some URLRouting.Router<AppRoute> {
///         OneOf {
///             Route(.case(\.home))
///             Route(.case(\.detail)) { Path { Int.parser() } }
///         }
///     }
/// }
/// ```
///
/// The engine supplies the default `parse` (delegating to `body`); the declarative
/// `serialize` default below completes the pair.
public protocol ParserPrinter<Input, Output>: Parser.Bidirectional
where Failure == RFC_3986.URI.Routing.Error {}

// MARK: - Declarative Serializer Default

extension ParserPrinter
where
    Body: Parser.Bidirectional,
    Body.Input == Input,
    Body.Output == Output,
    Body.Failure == Failure
{
    /// Default `serialize` implementation that delegates to ``Parser/Protocol/body-swift.property``.
    ///
    /// This is the emission-side counterpart to the engine's declarative `parse`
    /// default: a router that declares a bidirectional `body` serializes by
    /// delegating to that body, so leaf routers need only declare their grammar
    /// once. Forward-order append emission per the coder-unification spike
    /// (byte-equal to the retired prepend `print` algebra).
    @inlinable
    public borrowing func serialize(
        _ output: Output,
        into buffer: inout Input
    ) throws(Failure) {
        try body.serialize(output, into: &buffer)
    }
}
