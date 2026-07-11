//
//  AuthenticatingTests.swift
//  swift-url-routing — Authenticating
//
//  W2/S2 wrapper smoke coverage. Isolated target (depends only on Authenticating).
//  Full-suite coverage is the S3 wave gate; this is the build-verification smoke.
//

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
}
