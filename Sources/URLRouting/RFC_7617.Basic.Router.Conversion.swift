//
//  RFC_7617.Basic.Router.Conversion.swift
//  swift-url-routing — URLRouting
//
//  The Substring ⇄ RFC_7617.Basic conversion backing the Basic router's
//  `Authorization` header field.
//

import RFC_7617

extension RFC_7617.Basic.Router {
    /// Converts the `Authorization` header value to/from an ``RFC_7617/Basic``.
    ///
    /// Forward (parse): `RFC_7617.Basic(_:)` reads `"Basic <base64(user-id:password)>"`.
    /// Reverse (print): ``RFC_7617/Basic/authorizationHeaderValue()`` emits it.
    ///
    /// The conversion's `Failure` is the credential's own `RFC_7617.Basic.Error`;
    /// the enclosing header-field parser re-wraps it into the unified
    /// `RFC_3986.URI.Routing.Error` at the router boundary.
    struct Conversion {}
}

extension RFC_7617.Basic.Router.Conversion: Parser.Conversion.`Protocol` {
    typealias Input = Substring
    typealias Output = RFC_7617.Basic
    typealias Failure = RFC_7617.Basic.Error

    func apply(_ input: Substring) throws(RFC_7617.Basic.Error) -> RFC_7617.Basic {
        try RFC_7617.Basic(String(input))
    }

    func unapply(_ output: RFC_7617.Basic) throws(RFC_7617.Basic.Error) -> Substring {
        Substring(output.authorizationHeaderValue())
    }
}
