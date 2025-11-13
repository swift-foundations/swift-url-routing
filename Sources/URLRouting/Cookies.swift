import Foundation
import OrderedCollections

/// Parses a request's cookies using field parsers.
public struct Cookies<Parsers: Parser>: Parser where Parsers.Input == URIRequestData.Fields {
  @usableFromInline
  let cookieParsers: Parsers

  @inlinable
  public init(@ParserBuilder<URIRequestData.Fields> build: () -> Parsers) {
    self.cookieParsers = build()
  }

  @inlinable
  public func parse(_ input: inout URIRequestData) throws -> Parsers.Output {
    guard let cookie = input.headers["cookie"]
    else { throw RoutingError() }

    var fields: Parsers.Input = cookie.reduce(
      into: .init([:], isCaseSensitive: true)
    ) { fields, field in
      guard let cookies = field?.components(separatedBy: "; ")
      else { return }

      for cookie in cookies {
        let pair = cookie.split(separator: "=", maxSplits: 1, omittingEmptySubsequences: false)
        guard pair.count == 2 else { continue }
        fields[String(pair[0]), default: []].append(pair[1])
      }
    }

    return try self.cookieParsers.parse(&fields)
  }
}

extension Cookies: ParserPrinter where Parsers: ParserPrinter {
  @inlinable
  public func print(_ output: Parsers.Output, into input: inout URIRequestData) rethrows {
    var cookies = URIRequestData.Fields()
    try self.cookieParsers.print(output, into: &cookies)

    input.headers["cookie", default: []].prepend(
      cookies
        .flatMap { name, values in values.map { "\(name)=\($0 ?? "")" } }
        .joined(separator: "; ")[...]
    )
  }
}
