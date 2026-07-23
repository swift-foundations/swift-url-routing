//
//  Authentication.swift
//  swift-url-routing — URL Routing Foundation Integration
//

/// The namespace for HTTP-authentication routing compositions.
///
/// `Authentication` composes the RFC credential value types
/// (``RFC_6750/Bearer``, ``RFC_7617/Basic``) with `URLRouting`
/// parser-printers: the credential routers (in the `URLRouting` core) parse
/// and print the `Authorization` request header, and ``Authentication/Error``
/// types the composition failures. ``Authentication/Client`` adds the client
/// composition over `Foundation.URL` / `URLRequest`.
public enum Authentication {}
