//
//  RFC_6750.Bearer.Router.swift
//  swift-url-routing — URLRouting
//
//  A URLRouting parser-printer for `Authorization: Bearer <token>` ⇄ RFC_6750.Bearer.
//

import HTTP_Standard
import RFC_3986
import RFC_6750

extension RFC_6750.Bearer {
    /// A bidirectional `URLRouting` parser-printer for the `Authorization: Bearer
    /// <token>` request header (RFC 6750 §2.1).
    ///
    /// Parsing reads the `Authorization` header and produces an ``RFC_6750/Bearer``;
    /// printing serializes the credential back into the header. The credential value
    /// type is consumed as-vended — this router never reimplements it.
    ///
    /// ```swift
    /// let router = RFC_6750.Bearer.Router()
    /// var data = RFC_3986.URI.Request.Data()
    /// try router.print(RFC_6750.Bearer(token: "abc"), into: &data)  // Authorization: Bearer abc
    /// ```
    public struct Router {
        public init() {}
    }
}

extension RFC_6750.Bearer.Router: Parser.Bidirectional {
    public typealias Input = RFC_3986.URI.Request.Data
    public typealias Buffer = RFC_3986.URI.Request.Data
    public typealias Output = RFC_6750.Bearer
    public typealias Failure = RFC_3986.URI.Routing.Error

    /// The `Authorization` header field, mapped through ``Conversion``. Kept as an
    /// opaque `some Parser.Bidirectional<…>` computed member so `Router` stays a
    /// stateless (and therefore `Sendable`) value with no stored existential.
    private var authorizationField:
        some Parser.Bidirectional<
            RFC_3986.URI.Request.Data, RFC_6750.Bearer, RFC_3986.URI.Routing.Error
        >
    {
        URLRouting.Headers {
            HTTP.Header.Field.Parser("Authorization", Conversion())
        }
    }

    public func parse(_ input: inout Input) throws(Failure) -> Output {
        try authorizationField.parse(&input)
    }

    public func print(_ output: Output, into input: inout Input) throws(Failure) {
        try authorizationField.print(output, into: &input)
    }

    public borrowing func serialize(_ output: Output, into buffer: inout Input) throws(Failure) {
        try authorizationField.serialize(output, into: &buffer)
    }
}

// MARK: - Sendable (W3 E4)

/// Honest: the router is stateless (computed member only — documented above).
/// Explicit because public types get no implicit Sendable; required for
/// `Authentication.Client`'s conditional conformance to fire at consumer
/// specializations over `RFC_6750.Bearer.Router`.
extension RFC_6750.Bearer.Router: Sendable {}
