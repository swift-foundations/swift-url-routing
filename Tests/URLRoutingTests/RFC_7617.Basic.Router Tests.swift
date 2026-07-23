//
//  RFC_7617.Basic.Router Tests.swift
//  swift-url-routing — URLRoutingTests
//

import Testing

@testable import URLRouting

extension RFC_7617.Basic.Router {
    @Suite
    struct Test {
        @Suite struct Unit {}
        @Suite struct `Edge Case` {}
        @Suite struct Integration {}
    }
}

extension RFC_7617.Basic.Router.Test.Unit {
    @Test
    func `print then parse round-trips the RFC 7617 example vector`() throws {
        let router = RFC_7617.Basic.Router()
        let credential = try RFC_7617.Basic(userID: "Aladdin", password: "open sesame")

        var data = RFC_3986.URI.Request.Data()
        try router.print(credential, into: &data)

        // RFC 7617 §2 example vector.
        #expect(data.headers["Authorization"]?.first ?? nil == "Basic QWxhZGRpbjpvcGVuIHNlc2FtZQ==")

        var toParse = data
        let parsed = try router.parse(&toParse)
        #expect(parsed.userID == "Aladdin")
        #expect(parsed.password == "open sesame")
    }
}

extension RFC_7617.Basic.Router.Test.`Edge Case` {
    @Test
    func `parse fails on request data without an Authorization header`() {
        let router = RFC_7617.Basic.Router()
        var data = RFC_3986.URI.Request.Data()
        #expect(throws: RFC_3986.URI.Routing.Error.self) {
            _ = try router.parse(&data)
        }
    }
}

extension RFC_7617.Basic.Router.Test.Integration {
    @Test
    func `router output prints via the credential's own header-value serialization`() throws {
        let credential = try RFC_7617.Basic(userID: "u", password: "p")
        let router = RFC_7617.Basic.Router()

        var data = RFC_3986.URI.Request.Data()
        try router.print(credential, into: &data)

        let printed = data.headers["Authorization"]?.first ?? nil
        #expect(printed == Substring(credential.authorizationHeaderValue()))
    }
}
