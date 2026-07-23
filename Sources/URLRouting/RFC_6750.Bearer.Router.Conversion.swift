//
//  RFC_6750.Bearer.Router.Conversion.swift
//  swift-url-routing — URLRouting
//
//  The Substring ⇄ RFC_6750.Bearer conversion backing the Bearer router's
//  `Authorization` header field.
//

import RFC_6750

extension RFC_6750.Bearer.Router {
    /// Converts the `Authorization` header value to/from an ``RFC_6750/Bearer``.
    ///
    /// Forward (parse): `RFC_6750.Bearer.parse(from:)` reads `"Bearer <token>"`.
    /// Reverse (print): ``RFC_6750/Bearer/authorizationHeaderValue()`` emits it.
    ///
    /// The conversion's `Failure` is the credential's own `RFC_6750.Bearer.Error`;
    /// the enclosing header-field parser re-wraps it into the unified
    /// `RFC_3986.URI.Routing.Error` at the router boundary.
    struct Conversion {}
}

extension RFC_6750.Bearer.Router.Conversion: Parser.Conversion.`Protocol` {
    typealias Input = Substring
    typealias Output = RFC_6750.Bearer
    typealias Failure = RFC_6750.Bearer.Error

    func apply(_ input: Substring) throws(RFC_6750.Bearer.Error) -> RFC_6750.Bearer {
        try RFC_6750.Bearer.parse(from: String(input))
    }

    func unapply(_ output: RFC_6750.Bearer) throws(RFC_6750.Bearer.Error) -> Substring {
        Substring(output.authorizationHeaderValue())
    }
}
