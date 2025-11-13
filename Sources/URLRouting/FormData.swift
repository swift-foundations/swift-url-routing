import Foundation
import OrderedCollections
import Parsing

// MARK: - HTML FormData Extension

public enum HTML {
  /// Form-encoded data (application/x-www-form-urlencoded)
  public enum FormData {}
}


extension HTML.FormData {
  /// Parser for form-encoded data (application/x-www-form-urlencoded)
  ///
  /// Parses form-encoded data using field parsers.
  ///
  /// Note: While often associated with RFC 1867, the application/x-www-form-urlencoded
  /// encoding is actually defined in the HTML Living Standard.
  ///
  /// Example:
  /// ```swift
  /// HTML.FormData.Parser {
  ///   Field("username", .string)
  ///   Field("age") { Int.parser() }
  /// }
  /// ```
  public struct Parser<FieldParsers: Parsing.Parser>: Parsing.Parser
  where FieldParsers.Input == URIRequestData.Fields {
    @usableFromInline
    let fieldParsers: FieldParsers

    @inlinable
    public init(@ParserBuilder<URIRequestData.Fields> build: () -> FieldParsers) {
      self.fieldParsers = build()
    }

    @inlinable
    public func parse(_ input: inout Data) rethrows -> FieldParsers.Output {
      var fields: FieldParsers.Input = String(decoding: input, as: UTF8.self)
        .split(separator: "&")
        .reduce(into: .init([:], isCaseSensitive: true)) { fields, field in
          let pair =
            field
            .split(separator: "=", maxSplits: 1, omittingEmptySubsequences: false)
            .compactMap { $0.replacingOccurrences(of: "+", with: " ").removingPercentEncoding }
          let name = pair[0]
          let value = pair.count == 2 ? pair[1][...] : nil
          fields[name, default: []].append(value)
        }

      let output = try self.fieldParsers.parse(&fields)

      input = .init(encoding: fields)
      return output
    }
  }
}

extension HTML.FormData.Parser: ParserPrinter where FieldParsers: ParserPrinter {
  @inlinable
  public func print(_ output: FieldParsers.Output, into input: inout Data) rethrows {
    var fields = URIRequestData.Fields()
    try self.fieldParsers.print(output, into: &fields)
    input = .init(encoding: fields)
  }
}

// MARK: - Convenience Type Alias

/// Convenience type alias for `HTML.FormData.Parser`
///
/// For cleaner code, you can use `FormData` instead of the fully qualified name:
/// ```swift
/// FormData {
///   Field("username", .string)
/// }
/// ```
public typealias FormData = HTML.FormData.Parser

// MARK: - Data Encoding Extension

extension Data {
  @usableFromInline
  init(encoding fields: URIRequestData.Fields) {
    self.init(
      fields
        .flatMap { pair -> [String] in
          let (name, values) = pair
          guard let name = name.addingPercentEncoding(withAllowedCharacters: .urlQueryParamAllowed)
          else { return [] }

          return values.compactMap { value in
            guard let value = value
            else { return name }

            guard
              let value = value.addingPercentEncoding(withAllowedCharacters: .urlQueryParamAllowed)
            else { return nil }

            return "\(name)=\(value)"
          }
        }
        .joined(separator: "&")
        .utf8
    )
  }
}

extension CharacterSet {
  @usableFromInline
  static let urlQueryParamAllowed = CharacterSet
    .urlQueryAllowed
    .subtracting(Self(charactersIn: ":#[]@!$&'()*+,;="))
}
