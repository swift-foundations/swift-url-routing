import Foundation
import OrderedCollections

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

extension Parser where Input == URIRequestData {
  /// Matches a Foundation URLRequest to a route.
  ///
  /// Example:
  /// ```swift
  /// let request = URLRequest(url: URL(string: "https://api.example.com/books/42")!)
  /// let route = try router.match(request: request)
  /// ```
  @inlinable
  public func match(request: URLRequest) throws -> Output {
    guard let data = URIRequestData(request: request)
    else { throw RoutingError() }
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
    guard let data = URIRequestData(url: url)
    else { throw RoutingError() }
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
    let data = try URIRequestData(uriString: path)
    return try self.parse(data)
  }
}

extension ParserPrinter where Input == URIRequestData {
  /// Prints a route to a Foundation URLRequest.
  ///
  /// Example:
  /// ```swift
  /// let request = try router.request(for: .book(id: 42))
  /// // URLRequest with URL: /books/42
  /// ```
  @inlinable
  public func request(for route: Output) throws -> URLRequest {
    var data = URIRequestData()
    try self.print(route, into: &data)
    guard let request = URLRequest(data: data)
    else { throw RoutingError() }
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
      var data = URIRequestData()
      try self.print(route, into: &data)
      return URLComponents(data: data).url ?? URL(string: "#route-not-found")!
    } catch {
      breakpoint(
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
      var data = URIRequestData()
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
      breakpoint(
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
