import Foundation
import OrderedCollections
import Parsing
import RFC_3986

extension ParserPrinter where Input == RFC_3986.URI.Request.Data {
    /// Prepends a router with a base URL for the purpose of printing.
    ///
    /// Useful for printing absolute URLs to a specific scheme, domain, and path prefix.
    ///
    /// ```swift
    /// let apiRouter = router.baseURL("https://api.pointfree.co/v1")
    ///
    /// try apiRouter.print(.episodes(.episode(1, .index))
    /// // https://api.pointfree.co/v1/episodes/1
    /// ```
    ///
    /// - Parameter urlString: A base URL string.
    /// - Returns: A parser-printer that prepends a base URL to whatever this parser-printer prints.
    @inlinable
    public func baseURL(_ urlString: String) -> RFC_3986.URI.BaseURLPrinter<Self> {
        guard let defaultRequestData = try? RFC_3986.URI.Request.Data(uriString: urlString)
        else { fatalError("Invalid base URL: \(urlString.debugDescription)") }
        return RFC_3986.URI.BaseURLPrinter(defaultRequestData: defaultRequestData, upstream: self)
    }

    /// Prepends a router with default request data for the purpose of printing.
    ///
    /// ```swift
    /// let authenticatedRouter = router
    ///   .baseRequestData(.init(headers: ["X-PointFree-Session": ["deadbeef"]]))
    /// ```
    ///
    /// - Parameter requestData: Default request data to print into.
    /// - Returns: A parser-printer that prints into some default request data.
    @inlinable
    public func baseRequestData(_ requestData: RFC_3986.URI.Request.Data) -> RFC_3986.URI.BaseURLPrinter<Self> {
        RFC_3986.URI.BaseURLPrinter(defaultRequestData: requestData, upstream: self)
    }
}

extension RFC_3986.URI {
    /// Attaches base URL request data to a router.
    ///
    /// You will not typically need to interact with this type directly. Instead you will usually use
    /// the `baseURL` and `baseRequestData` operations on router, which constructs this type.
    ///
    /// ```swift
    /// let apiRouter = router.baseURL("https://api.pointfree.co/v1")
    ///
    /// apiRouter.url(for: .episodes(.episode(1, .index)))
    /// // https://api.pointfree.co/v1/episodes/1
    ///
    /// let authenticatedRouter = router
    ///   .baseRequestData(.init(headers: ["X-PointFree-Session": ["deadbeef"]]))
    ///
    /// try authenticatedRouter.request(for: .home)
    ///   .value(forHTTPHeaderField: "x-pointfree-session")
    /// // "deadbeef"
    /// ```
    public struct BaseURLPrinter<Upstream: ParserPrinter>: ParserPrinter
    where Upstream.Input == RFC_3986.URI.Request.Data {
        @usableFromInline
        let defaultRequestData: RFC_3986.URI.Request.Data

        @usableFromInline
        let upstream: Upstream

        @usableFromInline
        init(defaultRequestData: RFC_3986.URI.Request.Data, upstream: Upstream) {
            self.defaultRequestData = defaultRequestData
            self.upstream = upstream
        }

        @inlinable
        public func parse(_ input: inout RFC_3986.URI.Request.Data) rethrows -> Upstream.Output {
            try self.upstream.parse(&input)
        }

        @inlinable
        public func print(_ output: Upstream.Output, into input: inout RFC_3986.URI.Request.Data) rethrows {
            try self.upstream.print(output, into: &input)
            if let scheme = self.defaultRequestData.scheme { input.scheme = scheme }
            if let userinfo = self.defaultRequestData.userinfo { input.userinfo = userinfo }
            if let host = self.defaultRequestData.host { input.host = host }
            if let port = self.defaultRequestData.port { input.port = port }
            input.path.prepend(contentsOf: self.defaultRequestData.path)
            input.query.fields.merge(self.defaultRequestData.query.fields) { $1 + $0 }
            if let fragment = self.defaultRequestData.fragment { input.fragment = fragment }
            input.headers.fields.merge(self.defaultRequestData.headers.fields) { $1 + $0 }
        }
    }
}
