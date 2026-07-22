//
//  ParserPrinter+request.swift
//  swift-url-routing
//
//  Created by Coen ten Thije Boonkkamp on 15/11/2025.
//

import Dependencies
public import Foundation
import Logger_Dependencies
import Logging
public import RFC_3986
public import URLRouting

#if canImport(FoundationNetworking)
    public import FoundationNetworking
#endif

extension Parser.Bidirectional where Input == RFC_3986.URI.Request.Data {
    /// Prints a route to a Foundation URLRequest.
    ///
    /// Example:
    /// ```swift
    /// let request = try router.request(for: .book(id: 42))
    /// // URLRequest with URL: /books/42
    /// ```
    @inlinable
    public func request(for route: Output) throws(RFC_3986.URI.Routing.Error) -> URLRequest {
        var data = RFC_3986.URI.Request.Data()
        do {
            try self.print(route, into: &data)
        } catch {
            throw RFC_3986.URI.Routing.Error(
                component: .request,
                failure: .parseFailed("\(error)")
            )
        }
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
            @Dependency(\.logger) var logger
            logger.error(
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

}
