//
//  PointFree.Transform.swift
//  swift-url-routing
//
//  Pointfree-compat `transform` shim: seeds an empty request-data value, hands it to
//  the caller's transformation, and folds the result in as base request data (via
//  `baseRequestData`) so it is merged into everything the router prints.
//
//  Institute-typed re-expression of pointfree's `extension ParserPrinter where
//  Input == URLRequestData`. Hosted on `Parser.Bidirectional` — the engine the
//  `ParserPrinter` compat surface re-exposes, and the same home as the sibling
//  `baseURL` / `baseRequestData` operations — so it is callable on ordinary combinator
//  routers (e.g. `OneOf`), not only on explicit `ParserPrinter` conformers.
//

import RFC_3986

extension Parser.Bidirectional where Input == RFC_3986.URI.Request.Data {
    /// Transforms base request data and prepends it to a router for printing.
    ///
    /// Seeds an empty request-data value, applies `transform`, and uses the result as
    /// default request data — merged into whatever this router prints. This is the
    /// transform-driven counterpart to `baseRequestData(_:)`.
    ///
    /// ```swift
    /// let apiRouter = router
    ///   .transform { data in
    ///     data.scheme = "https"
    ///     data.host = "api.example.com"
    ///     return data
    ///   }
    /// ```
    ///
    /// - Parameter transform: A function that receives a fresh, empty request-data value
    ///   and returns the base request data to merge into printed output.
    /// - Returns: A parser-printer that prints into the transformed base request data.
    public func transform(
        _ transform: @escaping (inout RFC_3986.URI.Request.Data) -> RFC_3986.URI.Request.Data
    ) -> RFC_3986.URI.BaseURLPrinter<Self> {
        var requestData = RFC_3986.URI.Request.Data()
        requestData = transform(&requestData)
        return self.baseRequestData(requestData)
    }
}
