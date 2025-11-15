//
//  ParserPrinter+request.swift
//  swift-url-routing
//
//  Created by Coen ten Thije Boonkkamp on 15/11/2025.
//

import Foundation
import IssueReporting
import OrderedCollections
import Parsing
import RFC_3986

#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif

extension ParserPrinter where Input == RFC_3986.URI.Request.Data {
    /// Prints a route to a Foundation URLRequest.
    ///
    /// Example:
    /// ```swift
    /// let request = try router.request(for: .book(id: 42))
    /// // URLRequest with URL: /books/42
    /// ```
    @inlinable
    public func request(for route: Output) throws -> URLRequest {
        var data = RFC_3986.URI.Request.Data()
        try self.print(route, into: &data)
        guard let request = URLRequest(data: data)
        else {
            throw RFC_3986.URI.Routing.Error(
                component: .request,
                failure: .parseFailed("Unable to convert URI.Request.Data to URLRequest")
            )
        }
        return request
    }

    /// Prints a route to a Foundation URL.
    ///
    /// Example:
    /// ```swift
    /// let url = router.url(for: .book(id: 42))
    /// // URL: /books/42
    /// ```
    @inlinable
    public func url(for route: Output) -> URL {
        do {
            var data = RFC_3986.URI.Request.Data()
            try self.print(route, into: &data)
            return URLComponents(data: data).url ?? URL(string: "#route-not-found")!
        } catch {
            reportIssue(
                """
                ---
                Could not generate a URL for route:

                  \(route)

                The router has not been configured to parse this output and so it cannot print it back \
                into a URL. A '#route-not-found' fragment has been printed instead.

                \(error)
                ---
                """
            )
            return URL(string: "#route-not-found")!
        }
    }

    @inlinable
    public func urlPath(for route: Output) -> String {
        do {
            var data = RFC_3986.URI.Request.Data()
            try self.print(route, into: &data)
            var components = URLComponents()
            components.path = "/\(data.path.joined(separator: "/"))"
            if !data.query.isEmpty {
                components.queryItems = data.query.fields
                    .flatMap { name, values in
                        values.map { URLQueryItem(name: name, value: $0.map(String.init)) }
                    }
            }
            return components.string ?? "#route-not-found"
        } catch {
            reportIssue(
                """
                ---
                Could not generate a URL for route:

                  \(route)

                The router has not been configured to parse this output and so it cannot print it back \
                into a URL. A '#route-not-found' fragment has been printed instead.

                \(error)
                ---
                """
            )
            return "#route-not-found"
        }
    }
}
