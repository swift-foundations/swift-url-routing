//
//  RFC_6750.Bearer.Router.swift
//  swift-url-routing — Authenticating
//
//  A URLRouting parser-printer for `Authorization: Bearer <token>` ⇄ RFC_6750.Bearer.
//

import RFC_6750
import URLRouting

extension RFC_6750.Bearer {
    /// A bidirectional `URLRouting` parser-printer for the `Authorization: Bearer
    /// <token>` request header (RFC 6750 §2.1).
    ///
    /// Parsing reads the `Authorization` header and produces an ``RFC_6750/Bearer``;
    /// printing serializes the credential back into the header. The credential value
    /// type is consumed as-vended — this router never reimplements it.
    ///
    /// Surfaced to `import Authenticating` consumers as `BearerAuth.Router`.
    ///
    /// ```swift
    /// let router = BearerAuth.Router()   // == RFC_6750.Bearer.Router()
    /// var data = URLRequestData()
    /// try router.print(BearerAuth(token: "abc"), into: &data)  // Authorization: Bearer abc
    /// ```
    public struct Router: Parser.Bidirectional {
        public typealias Input = RFC_3986.URI.Request.Data
        public typealias Output = RFC_6750.Bearer
        public typealias Failure = RFC_3986.URI.Routing.Error

        public init() {}

        /// The `Authorization` header field, mapped through ``Conversion``. Kept as an
        /// opaque `some Parser.Bidirectional<…>` computed member so `Router` stays a
        /// stateless (and therefore `Sendable`) value with no stored existential.
        private var authorizationField:
            some Parser.Bidirectional<
                RFC_3986.URI.Request.Data, RFC_6750.Bearer, RFC_3986.URI.Routing.Error
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

// MARK: - Sendable (W3 E4)

/// Honest: the router is stateless (computed member only — documented above).
/// Explicit because public types get no implicit Sendable; required for
/// `Authenticating`'s conditional conformance to fire at the consumer
/// specialization `Authenticating<BearerAuth, BearerAuth.Router, …>`.
extension RFC_6750.Bearer.Router: Sendable {}
