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
/// the routing surface (every combinator, `Method` matcher, and Authenticating router
/// already fails into it). Pinning it is not merely a convenience: `Input` / `Output`
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
/// `print` default below completes the pair.
public protocol ParserPrinter<Input, Output>: Parser.Bidirectional
where Failure == RFC_3986.URI.Routing.Error {}

// MARK: - Declarative Printer Default

extension ParserPrinter
where
    Body: Parser.Bidirectional,
    Body.Input == Input,
    Body.Output == Output,
    Body.Failure == Failure
{
    /// Default `print` implementation that delegates to ``Parser/Protocol/body-swift.property``.
    ///
    /// This is the printer-side counterpart to the engine's declarative `parse`
    /// default: a router that declares a bidirectional `body` prints by delegating
    /// to that body, so leaf routers need only declare their grammar once.
    @inlinable
    public borrowing func print(
        _ output: Output,
        into input: inout Input
    ) throws(Failure) {
        try body.print(output, into: &input)
    }
}
