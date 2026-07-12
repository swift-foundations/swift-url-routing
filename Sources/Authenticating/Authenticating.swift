//
//  Authenticating.swift
//  swift-url-routing — Authenticating
//
//  The HTTP-auth-over-routing composition wrapper. Additive product on top of
//  the (S1-swapped, green) URLRouting engine; routing-coupled because it composes
//  `URLRouting` parser-printers over `URLRequestData`.
//

import Foundation
import URLRouting

/// Composes an authenticated `URLRouting` client from a credential, its
/// Authorization-header router, an API router, and a client builder.
///
/// Given a `baseURL`, a fixed `auth` credential (printed into the `Authorization`
/// header by `authRouter`), and an `apiRouter` mapping `API` routes to/from
/// `URLRequestData`, the initializer builds a live `URLRouting.Client<API>` that
/// prepends the base URL and the auth header to every request, then hands that
/// client to `buildClient` to produce the consumer-facing `Client`.
///
/// The generic parameters mirror the census surface
/// (`Authenticating<Auth, AuthRouter, API, APIRouter, Client>`) so the W3
/// consumers' `Authenticated<API, APIRouter, Client>` typealiases specialize it
/// unchanged.
public struct Authenticating<Auth, AuthRouter, API, APIRouter, Client>
where
    AuthRouter: Parser.Bidirectional,
    AuthRouter.Input == URLRequestData,
    AuthRouter.Output == Auth,
    APIRouter: Parser.Bidirectional,
    APIRouter.Input == URLRequestData,
    APIRouter.Output == API
{
    /// The `URLRouting` client the composed API router produces, and the input to
    /// `buildClient`.
    public typealias ClientOutput = URLRouting.Client<API>

    /// The API base URL prepended to every printed route.
    public let baseURL: Foundation.URL

    /// The fixed credential printed into the `Authorization` header of every request.
    public let auth: Auth

    /// The router mapping `API` routes to/from `URLRequestData`.
    public let apiRouter: APIRouter

    /// The router printing/parsing `auth` to/from the `Authorization` header.
    public let authRouter: AuthRouter

    /// The consumer-facing client produced by `buildClient`.
    public let client: Client

    /// Composes the authenticated client.
    ///
    /// - Parameters:
    ///   - baseURL: The API base URL (scheme/host/path prefix prepended on print).
    ///   - auth: The fixed credential authenticating every request.
    ///   - apiRouter: The `API` route parser-printer over `URLRequestData`.
    ///   - authRouter: The parser-printer that prints `auth` into the `Authorization` header.
    ///   - buildClient: Maps the composed ``ClientOutput`` into the consumer's `Client`.
    public init(
        baseURL: Foundation.URL,
        auth: Auth,
        apiRouter: APIRouter,
        authRouter: AuthRouter,
        buildClient: (ClientOutput) -> Client
    ) {
        self.baseURL = baseURL
        self.auth = auth
        self.apiRouter = apiRouter
        self.authRouter = authRouter

        // Base request data = the base URL's components + the Authorization header
        // for the fixed credential. Printing a validated credential into a header
        // does not fail in practice (the value type validated on construction), so
        // `try?` keeps this initializer non-throwing — the drop-in call-site shape.
        var base = (try? URLRequestData(uriString: baseURL.absoluteString)) ?? URLRequestData()
        try? authRouter.print(auth, into: &base)

        // Prepend `base` to every printed API route, then lift to a live client.
        let router = apiRouter.baseRequestData(base)
        self.client = buildClient(URLRouting.Client<API>.live(router: router))
    }
}

// MARK: - Sendable (W3 E4)

/// Honest conditional Sendable over the four STORED generic parameters (`API` is
/// not stored — no bound needed). Consumers store `Authenticating` as a
/// `Dependency.Key` value (`Witness.Key` requires `Value: Sendable`), which
/// hard-errors on 6.3.3 without this. Same-file per Swift's rule for
/// non-`@unchecked` conformances touching stored members.
extension Authenticating: Sendable
where Auth: Sendable, AuthRouter: Sendable, APIRouter: Sendable, Client: Sendable {}
