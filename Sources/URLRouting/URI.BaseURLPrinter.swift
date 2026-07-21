import Foundation
import OrderedCollections
import RFC_3986

extension Parser.Bidirectional where Input == RFC_3986.URI.Request.Data {
    /// Prepends a router with a base URL for the purpose of printing.
    ///
    /// Useful for printing absolute URLs to a specific scheme, domain, and path prefix.
    ///
    /// ```swift
    /// let apiRouter = router.baseURL("https://api.example.com/v1")
    ///
    /// try apiRouter.print(.episodes(.episode(1, .index))
    /// // https://api.example.com/v1/episodes/1
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
    ///   .baseRequestData(.init(headers: ["X-Session": ["deadbeef"]]))
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
    /// let apiRouter = router.baseURL("https://api.example.com/v1")
    ///
    /// apiRouter.url(for: .episodes(.episode(1, .index)))
    /// // https://api.example.com/v1/episodes/1
    /// ```
    public struct BaseURLPrinter<Upstream: Parser.Bidirectional>: Parser.`Protocol`
    where Upstream.Input == RFC_3986.URI.Request.Data {
        public typealias Failure = RFC_3986.URI.Routing.Error

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
        public func parse(
            _ input: inout RFC_3986.URI.Request.Data
        ) throws(RFC_3986.URI.Routing.Error) -> Upstream.Output {
            do {
                return try self.upstream.parse(&input)
            } catch {
                throw RFC_3986.URI.Routing.Error(component: .request, failure: .parseFailed("\(error)"))
            }
        }
    }
}

extension RFC_3986.URI.BaseURLPrinter: Parser.Bidirectional {
    /// The emission buffer type — `Parser.Bidirectional` pins `Buffer == Input`.
    public typealias Buffer = RFC_3986.URI.Request.Data

    /// Explicit leaf body: both `Parser.Protocol` and `Serializer.Protocol`
    /// supply a `Body == Never` default getter; the explicit override
    /// disambiguates between the two inherited candidates (the Coder.Witness
    /// precedent).
    @inlinable
    public var body: Never {
        borrowing get { return fatalError("leaf router — serialize(_:into:) is implemented directly") }
    }

    @inlinable
    public func serialize(
        _ output: Upstream.Output,
        into input: inout RFC_3986.URI.Request.Data
    ) throws(RFC_3986.URI.Routing.Error) {
        do {
            try self.upstream.print(output, into: &input)
        } catch {
            throw RFC_3986.URI.Routing.Error(component: .request, failure: .parseFailed("\(error)"))
        }
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
