//
//  RFC_7617.Basic.Router.swift
//  swift-url-routing — Authenticating
//
//  A URLRouting parser-printer for `Authorization: Basic <base64>` ⇄ RFC_7617.Basic.
//

import RFC_7617
import URLRouting

extension RFC_7617.Basic {
    /// A bidirectional `URLRouting` parser-printer for the `Authorization: Basic
    /// <base64(user-id:password)>` request header (RFC 7617 §2).
    ///
    /// Parsing reads the `Authorization` header and produces an ``RFC_7617/Basic``;
    /// printing serializes the credential back into the header. The credential value
    /// type is consumed as-vended — this router never reimplements it.
    ///
    /// Surfaced to `import Authenticating` consumers as `BasicAuth.Router`.
    ///
    /// ```swift
    /// let router = BasicAuth.Router()   // == RFC_7617.Basic.Router()
    /// var data = URLRequestData()
    /// try router.print(BasicAuth(username: "Aladdin", password: "open sesame"), into: &data)
    /// // Authorization: Basic QWxhZGRpbjpvcGVuIHNlc2FtZQ==
    /// ```
    public struct Router: Parser.Bidirectional {
        public typealias Input = RFC_3986.URI.Request.Data
        public typealias Output = RFC_7617.Basic
        public typealias Failure = RFC_3986.URI.Routing.Error

        public init() {}

        /// The `Authorization` header field, mapped through ``Conversion``. Kept as an
        /// opaque `some Parser.Bidirectional<…>` computed member so `Router` stays a
        /// stateless (and therefore `Sendable`) value with no stored existential.
        private var authorizationField:
            some Parser.Bidirectional<
                RFC_3986.URI.Request.Data, RFC_7617.Basic, RFC_3986.URI.Routing.Error
            >
        {
            RFC_7230.Header.Parser {
                RFC_7230.Header.Field.Parser("Authorization", Conversion())
            }
        }

        public func parse(_ input: inout Input) throws(Failure) -> Output {
            try authorizationField.parse(&input)
        }

        public func print(_ output: Output, into input: inout Input) throws(Failure) {
            try authorizationField.print(output, into: &input)
        }
    }
}
