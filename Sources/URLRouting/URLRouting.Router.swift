import RFC_3986

// MARK: - Router

extension URLRouting {
    /// A router is a bidirectional parser-printer over a URI request carrier.
    ///
    /// `URLRouting.Router<Output>` names the constrained ``Parser/Bidirectional``
    /// protocol pinned to the routing carrier (`RFC_3986.URI.Request.Data`) and the
    /// unified routing failure (`RFC_3986.URI.Routing.Error`). Because it names a
    /// protocol — not an existential — it is usable in every position the authoring
    /// DSL needs:
    ///
    /// - as an **opaque body type**: `var body: some URLRouting.Router<Route>`
    /// - as a **generic constraint**: `<R: URLRouting.Router<Route>>`
    /// - as an **existential** where erasure is needed: `any URLRouting.Router<Route>`
    ///   (see ``AnyParserPrinter`` for the concrete eraser).
    ///
    /// Any concrete parser-printer over the routing carrier — `RFC_3986.URI.Route`,
    /// `Parser.OneOf.Sequence`, a `.map`-converted router — satisfies it structurally,
    /// so no per-type conformance is required.
    ///
    /// The `body` requirement is inherited from ``Parser/Protocol``: a router type
    /// declares its grammar declaratively and the engine's default `parse` (plus the
    /// declarative `print` default on ``ParserPrinter``) delegate to that body.
    public typealias Router<Output> = Parser.Bidirectional<
        RFC_3986.URI.Request.Data,
        Output,
        RFC_3986.URI.Routing.Error
    >
}
