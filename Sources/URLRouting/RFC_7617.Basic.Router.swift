//
//  RFC_7617.Basic.Router.swift
//  swift-url-routing — URLRouting
//
//  A URLRouting parser-printer for `Authorization: Basic <base64>` ⇄ RFC_7617.Basic.
//

import HTTP_Standard
import RFC_3986
import RFC_7617

extension RFC_7617.Basic {
    /// A bidirectional `URLRouting` parser-printer for the `Authorization: Basic
    /// <base64(user-id:password)>` request header (RFC 7617 §2).
    ///
    /// Parsing reads the `Authorization` header and produces an ``RFC_7617/Basic``;
    /// printing serializes the credential back into the header. The credential value
    /// type is consumed as-vended — this router never reimplements it.
    ///
    /// ```swift
    /// let router = RFC_7617.Basic.Router()
    /// var data = RFC_3986.URI.Request.Data()
    /// try router.print(RFC_7617.Basic(userID: "Aladdin", password: "open sesame"), into: &data)
    /// // Authorization: Basic QWxhZGRpbjpvcGVuIHNlc2FtZQ==
    /// ```
    public struct Router {
        public init() {}
    }
}

extension RFC_7617.Basic.Router: Parser.Bidirectional {
    public typealias Input = RFC_3986.URI.Request.Data
    public typealias Buffer = RFC_3986.URI.Request.Data
    public typealias Output = RFC_7617.Basic
    public typealias Failure = RFC_3986.URI.Routing.Error

    /// The `Authorization` header field, mapped through ``Conversion``. Kept as an
    /// opaque `some Parser.Bidirectional<…>` computed member so `Router` stays a
    /// stateless (and therefore `Sendable`) value with no stored existential.
    private var authorizationField:
        some Parser.Bidirectional<
            RFC_3986.URI.Request.Data, RFC_7617.Basic, RFC_3986.URI.Routing.Error
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
/// specializations over `RFC_7617.Basic.Router`.
extension RFC_7617.Basic.Router: Sendable {}
