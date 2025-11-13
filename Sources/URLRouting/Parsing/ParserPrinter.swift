import Foundation
import OrderedCollections

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

extension Parser where Input == URIRequestData {
  @inlinable
  public func match(request: URLRequest) throws -> Output {
    // TODO: Add Foundation bridge URIRequestData(request:)
    fatalError("Foundation bridge not yet implemented")
  }

  @inlinable
  public func match(url: URL) throws -> Output {
    // TODO: Add Foundation bridge URIRequestData(url:)
    fatalError("Foundation bridge not yet implemented")
  }

  @inlinable
  public func match(path: String) throws -> Output {
    let data = try URIRequestData(uriString: path)
    return try self.parse(data)
  }
}

extension ParserPrinter where Input == URIRequestData {
  @inlinable
  public func request(for route: Output) throws -> URLRequest {
    // TODO: Add Foundation bridge URLRequest(data:)
    fatalError("Foundation bridge not yet implemented")
  }

  @inlinable
  public func url(for route: Output) -> URL {
    do {
      // TODO: Add Foundation bridge URLComponents(data:)
      fatalError("Foundation bridge not yet implemented")
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
