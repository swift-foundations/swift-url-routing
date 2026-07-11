//
//  exports.swift
//  swift-url-routing — Authenticating
//
//  Re-exports so `import Authenticating` is a self-contained drop-in surface:
//  the routing vocabulary (via URLRouting) plus the RFC credential value types
//  the routers parse/print. This is what makes the W3 consumer migration
//  mechanical — consumers keep `import Authenticating` and reach `BearerAuth`,
//  `BasicAuth`, the routers, and the full URLRouting surface unqualified.
//

@_exported import URLRouting
@_exported import RFC_6750
@_exported import RFC_7617
