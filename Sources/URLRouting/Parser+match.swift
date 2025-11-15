//
//  Parser+match.swift
//  swift-url-routing
//
//  Created by Coen ten Thije Boonkkamp on 15/11/2025.
//

import Foundation
import Parsing
import RFC_3986

#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif

extension Parser where Input == RFC_3986.URI.Request.Data {
    /// Matches a Foundation URLRequest to a route.
    ///
    /// Example:
    /// ```swift
    /// let request = URLRequest(url: URL(string: "https://api.example.com/books/42")!)
    /// let route = try router.match(request: request)
    /// ```
    @inlinable
    public func match(request: URLRequest) throws -> Output {
        guard let data = RFC_3986.URI.Request.Data(request: request)
        else { throw RFC_3986.URI.Routing.Error() }
        return try self.parse(data)
    }

    /// Matches a Foundation URL to a route.
    ///
    /// Example:
    /// ```swift
    /// let url = URL(string: "https://api.example.com/books/42")!
    /// let route = try router.match(url: url)
    /// ```
    @inlinable
    public func match(url: URL) throws -> Output {
        guard let data = RFC_3986.URI.Request.Data(url: url)
        else { throw RFC_3986.URI.Routing.Error() }
        return try self.parse(data)
    }

    /// Matches a URI string to a route.
    ///
    /// Example:
    /// ```swift
    /// let route = try router.match(path: "/books/42")
    /// ```
    @inlinable
    public func match(path: String) throws -> Output {
        let data = try RFC_3986.URI.Request.Data(uriString: path)
        return try self.parse(data)
    }
}
