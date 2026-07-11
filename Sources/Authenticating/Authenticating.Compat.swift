//
//  Authenticating.Compat.swift
//  swift-url-routing — Authenticating
//
//  Compat spellings for the legacy `swift-authenticating` surface. The DURABLE
//  credential value types are the RFC ones (`RFC_6750.Bearer`, `RFC_7617.Basic`,
//  vended as-is by swift-rfc-6750 / swift-rfc-7617); these are compat aliases so
//  `import Authenticating` gives W3 consumers a drop-in `BearerAuth` / `BasicAuth`
//  (and `BearerAuth.Router` / `BasicAuth.Router`) spelling. Not a reimplementation.
//
//  W2/S2 decision (compat-alias, ledger-endorsed "compat spellings belong to the
//  wrapper" + "username→userID spec-mirroring", HANDOFF-routing-w2 RUN LEDGER).
//

import RFC_6750
import RFC_7617

/// Compat spelling for RFC 6750 Bearer credentials.
///
/// The durable type is ``RFC_6750/Bearer``; `BearerAuth` (and `BearerAuth.Router`)
/// is the drop-in name for `import Authenticating` consumers.
public typealias BearerAuth = RFC_6750.Bearer

/// Compat spelling for RFC 7617 Basic credentials.
///
/// The durable type is ``RFC_7617/Basic``; `BasicAuth` (and `BasicAuth.Router`)
/// is the drop-in name for `import Authenticating` consumers.
public typealias BasicAuth = RFC_7617.Basic

extension RFC_7617.Basic {
    /// Compat initializer mirroring the legacy `BasicAuth(username:password:)` label.
    ///
    /// Forwards to the spec-mirroring ``RFC_7617/Basic/init(userID:password:)`` — the
    /// durable RFC 7617 surface uses `userID`; `username` is the compat spelling only.
    public init(username: String, password: String) throws(RFC_7617.Basic.Error) {
        try self.init(userID: username, password: password)
    }
}
