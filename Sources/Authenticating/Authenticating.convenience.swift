//
//  Authenticating.convenience.swift
//  swift-url-routing — Authenticating
//
//  Consumer-evidenced convenience constructors (W3 E3). Two additive shapes over
//  the untouched five-label ``Authenticating/init(baseURL:auth:apiRouter:authRouter:buildClient:)``:
//
//  1. The five-label overload whose `buildClient` receives a `makeRequest` closure
//     (`(API) throws -> URLRequest`) instead of a live ``Authenticating/ClientOutput``
//     — the legacy-`Authenticating` shape mailgun-live's `AuthenticatedClient`
//     composes on. Consumers that do their own transport use `Authenticating` purely
//     as a "print route → URLRequest with base URL + Authorization prepended" helper.
//
//  2. The Bearer `init(baseURL:token:buildClient:)` convenience — the shape all six
//     github-live construction sites call: the token string constructs the
//     `RFC_6750.Bearer` credential, the auth router defaults to `BearerAuth.Router()`,
//     and the API router resolves via `@Dependency(APIRouter.self)` (the consumers
//     declare `API.Router: @retroactive DependencyKey` for exactly this).
//
//  Built only from vended primitives: `baseRequestData(_:)` (URI.BaseURLPrinter) and
//  `request(for:)` (ParserPrinter+request → URLRequest(data:)).
//

import Dependencies
import Foundation
import RFC_6750
import URLRouting

#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif

// MARK: - makeRequest-shaped buildClient (five-label overload)

extension Authenticating where APIRouter: Sendable {
    /// Composes the authenticated wrapper, handing `buildClient` a `makeRequest`
    /// closure instead of a live ``ClientOutput``.
    ///
    /// The closure prints a route into `URLRequestData`, prepends the base URL and
    /// the printed `Authorization` header, and bridges to `Foundation.URLRequest` —
    /// for consumers that own their transport and only need request construction.
    ///
    /// - Parameters:
    ///   - baseURL: The API base URL (scheme/host/path prefix prepended on print).
    ///   - auth: The fixed credential authenticating every request.
    ///   - apiRouter: The `API` route parser-printer over `URLRequestData`.
    ///   - authRouter: The parser-printer that prints `auth` into the `Authorization` header.
    ///   - buildClient: Maps the `makeRequest` closure into the consumer's `Client`.
    public init(
        baseURL: Foundation.URL,
        auth: Auth,
        apiRouter: APIRouter,
        authRouter: AuthRouter,
        buildClient: (@escaping @Sendable (API) throws -> URLRequest) -> Client
    ) {
        self.baseURL = baseURL
        self.auth = auth
        self.apiRouter = apiRouter
        self.authRouter = authRouter

        // Base request data = the base URL's components + the Authorization header
        // for the fixed credential — the same composition as the five-label init.
        var composed = (try? URLRequestData(uriString: baseURL.absoluteString)) ?? URLRequestData()
        try? authRouter.print(auth, into: &composed)

        // `base` and `apiRouter` are immutable Sendable values captured by copy, so
        // the printer is composed per call and the closure stays `@Sendable`.
        let base = composed
        self.client = buildClient { route in
            try apiRouter.baseRequestData(base).request(for: route)
        }
    }
}

// MARK: - Bearer token convenience

extension Authenticating
where
    Auth == RFC_6750.Bearer,
    AuthRouter == RFC_6750.Bearer.Router,
    APIRouter: Sendable,
    APIRouter: Dependency.Key,
    APIRouter.Value == APIRouter
{
    /// Composes a Bearer-authenticated wrapper from a base URL and a token string.
    ///
    /// The token constructs the ``RFC_6750/Bearer`` credential (throwing on an
    /// invalid token), the auth router defaults to ``RFC_6750/Bearer/Router``, and
    /// the API router resolves via `@Dependency(APIRouter.self)` — consumers
    /// declare their `API.Router: Dependency.Key` conformance to supply it (the
    /// legacy `@retroactive DependencyKey` spelling migrates to `Dependency.Key`).
    ///
    /// - Parameters:
    ///   - baseURL: The API base URL (scheme/host/path prefix prepended on print).
    ///   - token: The RFC 6750 bearer token; validated into the credential.
    ///   - buildClient: Maps the `makeRequest` closure into the consumer's `Client`.
    public init(
        baseURL: Foundation.URL,
        token: String,
        buildClient: (@escaping @Sendable (API) throws -> URLRequest) -> Client
    ) throws(RFC_6750.Bearer.Error) {
        @Dependency(APIRouter.self) var apiRouter
        self.init(
            baseURL: baseURL,
            auth: try RFC_6750.Bearer(token: token),
            apiRouter: apiRouter,
            authRouter: RFC_6750.Bearer.Router(),
            buildClient: buildClient
        )
    }
}
