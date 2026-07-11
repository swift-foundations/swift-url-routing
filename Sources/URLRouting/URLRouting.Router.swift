import RFC_3986

// MARK: - Router Type Alias

extension URLRouting {
    /// A router is a bidirectional parser-printer over a URI request carrier.
    ///
    /// The failure surface is unified on the concrete `RFC_3986.URI.Routing.Error`
    /// at this router boundary (routing W2 typed-throws unification, R4).
    public typealias Router<Output> = any Parser.Bidirectional<RFC_3986.URI.Request.Data, Output, RFC_3986.URI.Routing.Error>
}
