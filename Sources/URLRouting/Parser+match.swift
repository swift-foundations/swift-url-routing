//
//  Parser+match.swift
//  swift-url-routing
//

import RFC_3986

extension Parser.`Protocol` where Input == RFC_3986.URI.Request.Data {
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
