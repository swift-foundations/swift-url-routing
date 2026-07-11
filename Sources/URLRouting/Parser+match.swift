//
//  Parser+match.swift
//  swift-url-routing
//
//  Created by Coen ten Thije Boonkkamp on 15/11/2025.
//

import Foundation
import RFC_3986

#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif

extension Parser.`Protocol` where Input == RFC_3986.URI.Request.Data {
    /// Matches a Foundation URLRequest to a route.
    ///
    /// Example:
    /// ```swift
    /// let request = URLRequest(url: URL(string: "https://api.example.com/books/42")!)
    /// let route = try router.match(request: request)
    /// ```
    @inlinable
    public func match(request: URLRequest) throws(RFC_3986.URI.Routing.Error) -> Output {
        guard var data = RFC_3986.URI.Request.Data(request: request)
        else {
            throw RFC_3986.URI.Routing.Error(
                component: .request,
                failure: .parseFailed("Unable to convert URLRequest to URI.Request.Data"),
                context: "URL: \(request.url?.absoluteString ?? "nil")"
            )
        }
        do {
            return try self.parse(&data)
        } catch {
            throw RFC_3986.URI.Routing.Error(
                component: .request,
                failure: .parseFailed("\(error)"),
                context: "URL: \(request.url?.absoluteString ?? "nil")"
            )
        }
    }

    /// Matches a Foundation URL to a route.
    ///
    /// Example:
    /// ```swift
    /// let url = URL(string: "https://api.example.com/books/42")!
    /// let route = try router.match(url: url)
    /// ```
    @inlinable
    public func match(url: URL) throws(RFC_3986.URI.Routing.Error) -> Output {
        guard var data = RFC_3986.URI.Request.Data(url: url)
        else {
            throw RFC_3986.URI.Routing.Error(
                component: .url,
                failure: .parseFailed("Unable to convert URL to URI.Request.Data"),
                context: "URL: \(url.absoluteString)"
            )
        }
        do {
            return try self.parse(&data)
        } catch {
            throw RFC_3986.URI.Routing.Error(
                component: .url,
                failure: .parseFailed("\(error)"),
                context: "URL: \(url.absoluteString)"
            )
        }
    }

    /// Matches a URI string to a route.
    ///
    /// Example:
    /// ```swift
    /// let route = try router.match(path: "/books/42")
    /// ```
    @inlinable
    public func match(path: String) throws(RFC_3986.URI.Routing.Error) -> Output {
        var data: RFC_3986.URI.Request.Data
        do {
            data = try RFC_3986.URI.Request.Data(uriString: path)
        } catch {
            throw RFC_3986.URI.Routing.Error(
                component: .url,
                failure: .parseFailed("\(error)"),
                context: "path: \(path)"
            )
        }
        do {
            return try self.parse(&data)
        } catch {
            throw RFC_3986.URI.Routing.Error(
                component: .request,
                failure: .parseFailed("\(error)"),
                context: "path: \(path)"
            )
        }
    }
}
