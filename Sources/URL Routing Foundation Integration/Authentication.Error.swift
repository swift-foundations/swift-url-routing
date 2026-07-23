//
//  Authentication.Error.swift
//  swift-url-routing — URL Routing Foundation Integration
//

extension Authentication {
    /// A failure composing an authenticated request surface.
    ///
    /// `Failure` is the credential router's own typed failure, preserved
    /// through the composition per typed-throws discipline.
    public enum Error<Failure: Swift.Error>: Swift.Error {
        /// The base URL string failed to parse as RFC 3986 request data.
        ///
        /// Carries the offending string; the upstream parse failure is
        /// untyped and the string itself is the diagnostic.
        case baseURL(String)

        /// The credential failed to print into the `Authorization` header.
        case authorization(Failure)
    }
}

extension Authentication.Error: Sendable where Failure: Sendable {}
