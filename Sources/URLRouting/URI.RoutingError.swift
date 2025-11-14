import RFC_3986

// MARK: - RFC 3986 URI Routing Extension

extension RFC_3986.URI {
    /// URI routing namespace
    public enum Routing {}
}

// MARK: - RFC 3986 URI Routing Error

extension RFC_3986.URI.Routing {
    /// Generic routing error for URI parsing failures
    @usableFromInline
    struct Error: Swift.Error {
        @usableFromInline
        init() {}
    }
}

// MARK: - Convenience Type Alias

/// Convenience type alias for `RFC_3986.URI.Routing.Error`
@usableFromInline
typealias RoutingError = RFC_3986.URI.Routing.Error
