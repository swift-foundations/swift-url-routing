//
//  RFC_6750.Bearer.Router Tests.swift
//  swift-url-routing — URLRoutingTests
//

import Testing

@testable import URLRouting

extension RFC_6750.Bearer.Router {
    @Suite
    struct Test {
        @Suite struct Unit {}
        @Suite struct `Edge Case` {}
        @Suite struct Integration {}
    }
}

extension RFC_6750.Bearer.Router.Test.Unit {
    @Test
    func `print then parse round-trips the Authorization header`() throws {
        let router = RFC_6750.Bearer.Router()
        let credential = try RFC_6750.Bearer(token: "abc123")

        var data = RFC_3986.URI.Request.Data()
        try router.print(credential, into: &data)

        #expect(data.headers["Authorization"]?.first ?? nil == "Bearer abc123")

        var toParse = data
        let parsed = try router.parse(&toParse)
        #expect(parsed.token == "abc123")
    }
}

extension RFC_6750.Bearer.Router.Test.`Edge Case` {
    @Test
    func `parse fails on request data without an Authorization header`() {
        let router = RFC_6750.Bearer.Router()
        var data = RFC_3986.URI.Request.Data()
        #expect(throws: RFC_3986.URI.Routing.Error.self) {
            _ = try router.parse(&data)
        }
    }
}

extension RFC_6750.Bearer.Router.Test.Integration {
    @Test
    func `router output prints via the credential's own header-value serialization`() throws {
        let credential = try RFC_6750.Bearer(token: "tok-42")
        let router = RFC_6750.Bearer.Router()

        var data = RFC_3986.URI.Request.Data()
        try router.print(credential, into: &data)

        // The router never reimplements the credential: the header value is
        // the credential's own serialization.
        let printed = data.headers["Authorization"]?.first ?? nil
        #expect(printed == Substring(credential.authorizationHeaderValue()))
    }
}
