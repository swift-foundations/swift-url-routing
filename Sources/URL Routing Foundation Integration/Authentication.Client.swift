//
//  Authentication.Client.swift
//  swift-url-routing — URL Routing Foundation Integration
//
//  A noun-form authenticated-client composition over `URLRouting.Client`,
//  with typed-throwing initializers. Lives in the Foundation Integration
//  target because its public surface bridges `Foundation.URL` / `URLRequest`.
//

public import Foundation
import RFC_3986
public import URLRouting

#if canImport(FoundationNetworking)
    public import FoundationNetworking
#endif

extension Authentication {
    /// Composes an authenticated `URLRouting` client from a credential, the
    /// router that prints it into the `Authorization` header, an API router,
    /// and a client builder.
    ///
    /// Given a `baseURL`, a fixed `credential` (printed into the
    /// `Authorization` header by `credentialRouter`), and an `apiRouter`
    /// mapping `API` routes to and from `RFC_3986.URI.Request.Data`, the
    /// canonical initializer builds a live `URLRouting.Client<API>` that
    /// prepends the base URL and the auth header to every request, then hands
    /// that client to `client` to produce the consumer-facing `Consumer`.
    ///
    /// Composition failures throw ``Authentication/Error`` — this composition
    /// never degrades to a silently unauthenticated client.
    public struct Client<Credential, CredentialRouter, API, APIRouter, Consumer>
    where
        CredentialRouter: Parser.Bidirectional,
        CredentialRouter.Input == RFC_3986.URI.Request.Data,
        CredentialRouter.Output == Credential,
        APIRouter: Parser.Bidirectional,
        APIRouter.Input == RFC_3986.URI.Request.Data,
        APIRouter.Output == API
    {
        /// The API base URL prepended to every printed route.
        public let baseURL: Foundation.URL

        /// The fixed credential printed into the `Authorization` header of
        /// every request.
        public let credential: Credential

        /// The router mapping `API` routes to and from request data.
        public let apiRouter: APIRouter

        /// The router printing and parsing `credential` to and from the
        /// `Authorization` header.
        public let credentialRouter: CredentialRouter

        /// The consumer-facing client produced by the `client` builder.
        public let client: Consumer

        /// Composes the authenticated client.
        ///
        /// - Parameters:
        ///   - baseURL: The API base URL (scheme/host/path prefix prepended on print).
        ///   - credential: The fixed credential authenticating every request.
        ///   - apiRouter: The `API` route parser-printer over request data.
        ///   - credentialRouter: The parser-printer that prints `credential`
        ///     into the `Authorization` header.
        ///   - client: Maps the composed ``Live`` client into the consumer's
        ///     `Consumer`.
        /// - Throws: ``Authentication/Error`` when the base URL fails to parse
        ///   as request data or the credential fails to print into the header.
        public init(
            baseURL: Foundation.URL,
            credential: Credential,
            apiRouter: APIRouter,
            credentialRouter: CredentialRouter,
            client: (Live) -> Consumer
        ) throws(Authentication.Error<CredentialRouter.Failure>) {
            self.baseURL = baseURL
            self.credential = credential
            self.apiRouter = apiRouter
            self.credentialRouter = credentialRouter
            let base = try Self.base(
                url: baseURL,
                credential: credential,
                credentialRouter: credentialRouter
            )
            self.client = client(.live(router: apiRouter.baseRequestData(base)))
        }
    }
}

extension Authentication.Client {
    /// The composed live routing client handed to the canonical
    /// initializer's `client` closure.
    public typealias Live = URLRouting.Client<API>

    /// Composes the base request data: the base URL's components plus the
    /// printed `Authorization` header for the fixed credential.
    ///
    /// The underlying reason a `Foundation.URL`'s `absoluteString` fails
    /// request-data parsing is deliberately dropped — the string itself is
    /// the diagnostic, and the upstream parse failure is untyped.
    static func base(
        url: Foundation.URL,
        credential: Credential,
        credentialRouter: CredentialRouter
    ) throws(Authentication.Error<CredentialRouter.Failure>) -> RFC_3986.URI.Request.Data {
        var base: RFC_3986.URI.Request.Data
        do {
            base = try RFC_3986.URI.Request.Data(uriString: url.absoluteString)
        } catch {
            throw .baseURL(url.absoluteString)
        }
        do throws(CredentialRouter.Failure) {
            try credentialRouter.print(credential, into: &base)
        } catch {
            throw .authorization(error)
        }
        return base
    }
}

// MARK: - Request construction

extension Authentication.Client where APIRouter: Sendable {
    /// Composes the authenticated wrapper, handing `client` a request-maker
    /// closure instead of a live ``Live`` client.
    ///
    /// The closure prints a route into request data, prepends the base URL
    /// and the printed `Authorization` header, and bridges to
    /// `Foundation.URLRequest` — for consumers that own their transport and
    /// only need request construction.
    ///
    /// - Parameters:
    ///   - baseURL: The API base URL (scheme/host/path prefix prepended on print).
    ///   - credential: The fixed credential authenticating every request.
    ///   - apiRouter: The `API` route parser-printer over request data.
    ///   - credentialRouter: The parser-printer that prints `credential`
    ///     into the `Authorization` header.
    ///   - client: Maps the request-maker closure into the consumer's `Consumer`.
    /// - Throws: ``Authentication/Error`` when the base URL fails to parse
    ///   as request data or the credential fails to print into the header.
    public init(
        baseURL: Foundation.URL,
        credential: Credential,
        apiRouter: APIRouter,
        credentialRouter: CredentialRouter,
        client: ((@escaping @Sendable (API) throws -> URLRequest)) -> Consumer
    ) throws(Authentication.Error<CredentialRouter.Failure>) {
        self.baseURL = baseURL
        self.credential = credential
        self.apiRouter = apiRouter
        self.credentialRouter = credentialRouter

        let base = try Self.base(
            url: baseURL,
            credential: credential,
            credentialRouter: credentialRouter
        )

        // `base` and `apiRouter` are immutable Sendable values captured by
        // copy, so the printer is composed per call and the closure stays
        // `@Sendable`.
        self.client = client { route in
            try apiRouter.baseRequestData(base).request(for: route)
        }
    }
}

// MARK: - Sendable

/// Honest conditional Sendable over the four stored generic parameters
/// (`API` is not stored — no bound needed). Consumers store the composition
/// as a `Dependency.Key` value, which requires `Value: Sendable`. Same-file
/// per Swift's rule for non-`@unchecked` conformances touching stored members.
extension Authentication.Client: Sendable
where
    Credential: Sendable,
    CredentialRouter: Sendable,
    APIRouter: Sendable,
    Consumer: Sendable
{}
