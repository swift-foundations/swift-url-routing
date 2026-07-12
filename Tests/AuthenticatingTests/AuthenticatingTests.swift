//
//  AuthenticatingTests.swift
//  swift-url-routing — Authenticating
//
//  W2/S2 wrapper smoke coverage. Isolated target (depends only on Authenticating).
//  Full-suite coverage is the S3 wave gate; this is the build-verification smoke.
//

import Dependencies
import Foundation
import Testing

@testable import Authenticating

@Suite("Authenticating")
struct AuthenticatingTests {

    // MARK: BearerAuth.Router

    @Test("Bearer router prints then parses the Authorization header round-trip")
    func bearerRoundTrip() throws {
        let router = BearerAuth.Router()
        let credential = try BearerAuth(token: "abc123")

        var data = URLRequestData()
        try router.print(credential, into: &data)

        #expect(data.headers["Authorization"]?.first ?? nil == "Bearer abc123")

        var toParse = data
        let parsed = try router.parse(&toParse)
        #expect(parsed.token == "abc123")
    }

    // MARK: BasicAuth.Router

    @Test("Basic router prints then parses the Authorization header round-trip")
    func basicRoundTrip() throws {
        let router = BasicAuth.Router()
        let credential = try BasicAuth(username: "Aladdin", password: "open sesame")

        var data = URLRequestData()
        try router.print(credential, into: &data)

        // RFC 7617 §2 example vector.
        #expect(data.headers["Authorization"]?.first ?? nil == "Basic QWxhZGRpbjpvcGVuIHNlc2FtZQ==")

        var toParse = data
        let parsed = try router.parse(&toParse)
        #expect(parsed.userID == "Aladdin")
        #expect(parsed.password == "open sesame")
    }

    // MARK: Compat aliases

    @Test("Compat aliases resolve to the durable RFC credential types")
    func compatAliases() throws {
        #expect(BearerAuth.self == RFC_6750.Bearer.self)
        #expect(BasicAuth.self == RFC_7617.Basic.self)

        // Compat `username:` label forwards to the spec-mirroring `userID:`.
        let basic = try BasicAuth(username: "u", password: "p")
        #expect(basic.userID == "u")
    }

    // MARK: Authenticating wrapper

    /// A trivial API router used only to exercise the wrapper's composition + init.
    struct EchoRouter: Parser.Bidirectional {
        typealias Input = URLRequestData
        typealias Output = Route
        typealias Failure = RFC_3986.URI.Routing.Error

        struct Route: Equatable, Sendable {}

        func parse(_ input: inout Input) throws(Failure) -> Output { Route() }
        func print(_ output: Output, into input: inout Input) throws(Failure) {}
    }

    @Test("Wrapper composes auth + routers + client builder")
    func wrapperComposition() throws {
        let auth = try BearerAuth(token: "tok")
        let wrapper = Authenticating(
            baseURL: URL(string: "https://api.example.com/v1")!,
            auth: auth,
            apiRouter: EchoRouter(),
            authRouter: BearerAuth.Router(),
            buildClient: { (client: URLRouting.Client<EchoRouter.Route>) in client }
        )

        #expect(wrapper.auth.token == "tok")
        #expect(wrapper.baseURL.absoluteString == "https://api.example.com/v1")
        // ClientOutput is the composed URLRouting client type fed to buildClient.
        #expect(type(of: wrapper.client) == Authenticating<
            BearerAuth, BearerAuth.Router, EchoRouter.Route, EchoRouter, URLRouting.Client<EchoRouter.Route>
        >.ClientOutput.self)
    }

    // MARK: Convenience constructors (W3 E3)

    /// Binding `Client` to the `makeRequest` function type lets the tests drive the
    /// closure the convenience constructors hand to `buildClient`.
    typealias MakeRequest = @Sendable (EchoRouter.Route) throws -> URLRequest

    @Test("Five-label init with makeRequest-shaped buildClient (Basic contract)")
    func basicMakeRequestConstruction() throws {
        let auth = try BasicAuth(username: "Aladdin", password: "open sesame")
        let wrapper = Authenticating(
            baseURL: URL(string: "https://api.example.com/v1")!,
            auth: auth,
            apiRouter: EchoRouter(),
            authRouter: BasicAuth.Router(),
            buildClient: { (makeRequest: @escaping MakeRequest) in makeRequest }
        )

        let request = try wrapper.client(EchoRouter.Route())
        #expect(request.url?.absoluteString == "https://api.example.com/v1")
        // RFC 7617 §2 example vector, printed by the auth router into every request.
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Basic QWxhZGRpbjpvcGVuIHNlc2FtZQ==")
    }

    @Test("Bearer init(baseURL:token:buildClient:) resolves router via @Dependency")
    func bearerTokenConstruction() throws {
        let wrapper = try Authenticating<
            BearerAuth, BearerAuth.Router, EchoRouter.Route, EchoRouter, MakeRequest
        >(
            baseURL: URL(string: "https://api.example.com/v1")!,
            token: "tok123"
        ) { makeRequest in makeRequest }

        #expect(wrapper.auth.token == "tok123")

        let request = try wrapper.client(EchoRouter.Route())
        #expect(request.url?.absoluteString == "https://api.example.com/v1")
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer tok123")
    }

    // MARK: Sendable (W3 E4)

    @Test("Authenticating is Sendable at the Dependency.Key Value shape")
    func sendableAtDependencyKeyShape() throws {
        typealias Wrapper = Authenticating<
            BearerAuth, BearerAuth.Router, EchoRouter.Route, EchoRouter, MakeRequest
        >

        // Compile-time proof of the consumer shape that hard-errored on 6.3.3:
        // `Witness.Key` (= `Dependency.Key`) requires `Value: Sendable`, so this
        // local key conforms ONLY if the Authenticating specialization is Sendable.
        enum WrapperKey: Dependency.Key {
            static var liveValue: Wrapper {
                // swiftlint:disable:next force_try
                try! Wrapper(
                    baseURL: URL(string: "https://api.example.com/v1")!,
                    token: "tok"
                ) { makeRequest in makeRequest }
            }
        }

        func requireSendable<T: Sendable>(_ value: T) -> T { value }

        let wrapper = requireSendable(WrapperKey.liveValue)
        #expect(wrapper.auth.token == "tok")

        // Behavioral: the stored client still produces authenticated requests.
        let request = try wrapper.client(EchoRouter.Route())
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer tok")
    }

    @Test("Bearer convenience throws the typed credential error on an invalid token")
    func bearerTokenValidation() {
        #expect(throws: RFC_6750.Bearer.Error.self) {
            _ = try Authenticating<
                BearerAuth, BearerAuth.Router, EchoRouter.Route, EchoRouter, MakeRequest
            >(
                baseURL: URL(string: "https://api.example.com/v1")!,
                token: ""
            ) { makeRequest in makeRequest }
        }
    }
}

// MARK: - EchoRouter dependency registration (W3 E3)

extension AuthenticatingTests.EchoRouter: Dependency.Key {
    static var liveValue: Self { Self() }
}
