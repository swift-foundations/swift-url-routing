import Foundation
import OrderedCollections

/// A parseable URI request optimized for incremental parsing.
///
/// Models an HTTP request with URI components stored as subsequences for efficient parser
/// consumption. Built on RFC 3986 principles with proper percent-encoding and validation.
///
/// Example:
/// ```swift
/// let data = URIRequestData(
///   method: "GET",
///   scheme: "https",
///   host: "api.example.com",
///   path: "/users/123",
///   query: ["page": ["1"]]
/// )
/// ```
public struct URIRequestData: Sendable, Equatable {
  /// The HTTP method (e.g., "GET", "POST")
  public var method: String?

  /// The URI scheme (e.g., "https", "http")
  public var scheme: String?

  /// The userinfo component (e.g., "user:password")
  public var userinfo: String?

  /// The host component
  public var host: String?

  /// The port number
  public var port: Int?

  /// The path segments for incremental parsing
  public var path: ArraySlice<Substring>

  /// The query fields for incremental parsing
  public var query: Fields

  /// The fragment component
  public var fragment: String?

  /// The request headers
  public var headers: Fields

  /// The request body
  public var body: Data?

  /// Creates an empty URI request
  public init() {
    self.path = []
    self.query = Fields([:], isCaseSensitive: true)
    self.headers = Fields([:], isCaseSensitive: false)
  }

  /// Creates a URI request with the specified components
  public init(
    method: String? = nil,
    scheme: String? = nil,
    userinfo: String? = nil,
    host: String? = nil,
    port: Int? = nil,
    path: String = "",
    query: OrderedDictionary<String, [String?]> = [:],
    fragment: String? = nil,
    headers: OrderedDictionary<String, [String?]> = [:],
    body: Data? = nil
  ) {
    self.method = method
    self.scheme = scheme
    self.userinfo = userinfo
    self.host = host
    self.port = port
    self.path = path.split(separator: "/", omittingEmptySubsequences: true)[...]
    self.query = Fields(
      query.mapValues { $0.map { $0?[...] }[...] },
      isCaseSensitive: true
    )
    self.fragment = fragment
    self.headers = Fields(
      headers.mapValues { $0.map { $0?[...] }[...] },
      isCaseSensitive: false
    )
    self.body = body
  }

  /// A collection of fields for efficient incremental parsing
  ///
  /// Used for query parameters (case-sensitive) and headers (case-insensitive).
  public struct Fields: Sendable, Equatable {
    public var fields: OrderedDictionary<String, ArraySlice<Substring?>>

    @usableFromInline
    var isCaseSensitive: Bool

    @inlinable
    public init(
      _ fields: OrderedDictionary<String, ArraySlice<Substring?>> = [:],
      isCaseSensitive: Bool
    ) {
      self.fields = [:]
      self.fields.reserveCapacity(fields.count)
      self.isCaseSensitive = isCaseSensitive
      for (key, value) in fields {
        self[key] = value
      }
    }

    @inlinable
    public subscript(name: String) -> ArraySlice<Substring?>? {
      _read { yield self.fields[self.isCaseSensitive ? name : name.lowercased()] }
      _modify { yield &self.fields[self.isCaseSensitive ? name : name.lowercased()] }
    }

    @inlinable
    public subscript(
      name: String, default defaultValue: @autoclosure () -> ArraySlice<Substring?>
    ) -> ArraySlice<Substring?> {
      _read {
        yield self.fields[
          self.isCaseSensitive ? name : name.lowercased(), default: defaultValue()
        ]
      }
      _modify {
        yield &self.fields[
          self.isCaseSensitive ? name : name.lowercased(), default: defaultValue()
        ]
      }
    }

    @inlinable
    public var isEmpty: Bool {
      self.fields.isEmpty
    }
  }
}

// MARK: - Codable

extension URIRequestData: Codable {
  @inlinable
  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    self.init(
      method: try container.decodeIfPresent(String.self, forKey: .method),
      scheme: try container.decodeIfPresent(String.self, forKey: .scheme),
      userinfo: try container.decodeIfPresent(String.self, forKey: .userinfo),
      host: try container.decodeIfPresent(String.self, forKey: .host),
      port: try container.decodeIfPresent(Int.self, forKey: .port),
      path: try container.decodeIfPresent(String.self, forKey: .path) ?? "",
      query: try container.decodeIfPresent(
        OrderedDictionary<String, [String?]>.self, forKey: .query
      ) ?? [:],
      fragment: try container.decodeIfPresent(String.self, forKey: .fragment),
      headers: try container.decodeIfPresent(
        OrderedDictionary<String, [String?]>.self, forKey: .headers
      ) ?? [:],
      body: try container.decodeIfPresent(Data.self, forKey: .body)
    )
  }

  @inlinable
  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encodeIfPresent(self.body.map(Array.init), forKey: .body)
    try container.encodeIfPresent(self.fragment, forKey: .fragment)
    if !self.headers.isEmpty {
      try container.encode(
        self.headers.fields.mapValues { $0.map { $0.map(String.init) } },
        forKey: .headers
      )
    }
    try container.encodeIfPresent(self.host, forKey: .host)
    try container.encodeIfPresent(self.method, forKey: .method)
    try container.encodeIfPresent(self.userinfo, forKey: .userinfo)
    if !self.path.isEmpty {
      try container.encode(self.path.joined(separator: "/"), forKey: .path)
    }
    try container.encodeIfPresent(self.port, forKey: .port)
    if !self.query.isEmpty {
      try container.encode(
        self.query.fields.mapValues { $0.map { $0.map(String.init) } },
        forKey: .query
      )
    }
    try container.encodeIfPresent(self.scheme, forKey: .scheme)
  }

  @usableFromInline
  enum CodingKeys: CodingKey {
    case body
    case fragment
    case headers
    case host
    case method
    case userinfo
    case path
    case port
    case query
    case scheme
  }
}

// MARK: - Hashable

extension URIRequestData: Hashable {
  @inlinable
  public func hash(into hasher: inout Hasher) {
    hasher.combine(self.body)
    hasher.combine(self.fragment)
    hasher.combine(self.method)
    hasher.combine(self.headers)
    hasher.combine(self.host)
    hasher.combine(self.userinfo)
    hasher.combine(self.path)
    hasher.combine(self.port)
    hasher.combine(self.query)
    hasher.combine(self.scheme)
  }
}

// MARK: - Fields Collection Conformance

extension URIRequestData.Fields: Collection {
  public typealias Element = OrderedDictionary<String, ArraySlice<Substring?>>.Element
  public typealias Index = OrderedDictionary<String, ArraySlice<Substring?>>.Index

  @inlinable
  public var startIndex: Index {
    self.fields.elements.startIndex
  }

  @inlinable
  public var endIndex: Index {
    self.fields.elements.endIndex
  }

  @inlinable
  public subscript(position: Index) -> Element {
    self.fields.elements[position]
  }

  @inlinable
  public func index(after i: Index) -> Index {
    self.fields.elements.index(after: i)
  }
}

extension URIRequestData.Fields: ExpressibleByDictionaryLiteral {
  @inlinable
  public init(dictionaryLiteral elements: (String, ArraySlice<Substring?>)...) {
    self.init(.init(elements) { $0 + $1 }, isCaseSensitive: true)
  }
}

extension URIRequestData.Fields: Hashable {
  @inlinable
  public func hash(into hasher: inout Hasher) {
    hasher.combine(self.fields)
  }
}

// MARK: - Empty Initializable

@usableFromInline
protocol _EmptyInitializable {
  init()
}

extension URIRequestData: _EmptyInitializable {}
