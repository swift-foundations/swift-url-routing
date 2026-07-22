import Foundation
import OrderedCollections
import RFC_3986
import RFC_7231

// MARK: - RFC 3986 URI Request Extension

extension RFC_3986.URI {
    /// HTTP request namespace
    public enum Request {}
}

// MARK: - URI Request Data

extension RFC_3986.URI.Request {
    /// A parseable URI request optimized for incremental parsing.
    ///
    /// Models an HTTP request with URI components stored as subsequences for efficient parser
    /// consumption. Built on RFC 3986 principles with proper percent-encoding and validation.
    ///
    /// Example:
    /// ```swift
    /// let data = RFC_3986.URI.Request.Data(
    ///   method: .GET,
    ///   scheme: "https",
    ///   host: "api.example.com",
    ///   path: "/users/123",
    ///   query: ["page": ["1"]]
    /// )
    /// ```
    public struct Data: Sendable, Equatable {
        /// The HTTP method (e.g., .GET, .POST)
        public var method: RFC_7231.Method?

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
        public var body: Foundation.Data?

        /// Creates an empty URI request
        public init() {
            self.path = []
            self.query = Fields([:], isCaseSensitive: true)
            self.headers = Fields([:], isCaseSensitive: false)
        }

        /// Creates a URI request with the specified components
        public init(
            method: RFC_7231.Method? = nil,
            scheme: String? = nil,
            userinfo: String? = nil,
            host: String? = nil,
            port: Int? = nil,
            path: String = "",
            query: OrderedDictionary<String, [String?]> = [:],
            fragment: String? = nil,
            headers: OrderedDictionary<String, [String?]> = [:],
            body: Foundation.Data? = nil
        ) {
            self.method = method
            self.scheme = scheme
            self.userinfo = userinfo
            self.host = host
            self.port = port
            // RFC 3986 engine truth: split the RAW path on "/" BEFORE
            // percent-decoding each segment, so "%2F" inside a segment does
            // not split (plan §Batch 3, fork F2).
            self.path =
                path.split(separator: "/", omittingEmptySubsequences: true)
                .map { RFC_3986.percentDecode(String($0))[...] }[...]
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
    }
}

// MARK: - URI Request Fields

extension RFC_3986.URI.Request {
    /// A collection of fields for efficient incremental parsing
    ///
    /// Used for query parameters (case-sensitive) and headers (case-insensitive).
    public struct Fields: Sendable, Equatable {
        @usableFromInline
        var storage: OrderedDictionary<String, ArraySlice<Substring?>>

        @usableFromInline
        var order: [String]

        public var fields: OrderedDictionary<String, ArraySlice<Substring?>> {
            @inlinable
            _read {
                yield self.storage
            }
            @inlinable
            _modify {
                guard self.isCaseSensitive else {
                    yield &self.storage
                    return
                }
                var fields = self.storage
                let previous = self.storage
                defer {
                    self.storage = fields
                    self.reconcile(from: previous)
                }
                yield &fields
            }
        }

        @usableFromInline
        var isCaseSensitive: Bool

        @inlinable
        public init(
            _ fields: OrderedDictionary<String, ArraySlice<Substring?>> = [:],
            isCaseSensitive: Bool
        ) {
            self.storage = [:]
            self.order = []
            self.storage.reserveCapacity(fields.count)
            self.isCaseSensitive = isCaseSensitive
            for (key, value) in fields {
                let key = isCaseSensitive ? key : key.lowercased()
                self.storage[key] = value
            }
            for (key, value) in self.storage {
                self.order.append(contentsOf: repeatElement(key, count: value.count))
            }
        }

        @usableFromInline
        init(_ parameters: [(String, String?)], isCaseSensitive: Bool) {
            self.storage = [:]
            self.order = []
            self.storage.reserveCapacity(parameters.count)
            self.order.reserveCapacity(parameters.count)
            self.isCaseSensitive = isCaseSensitive
            for (name, value) in parameters {
                let name = isCaseSensitive ? name : name.lowercased()
                self.storage[name, default: []].append(value?[...])
                self.order.append(name)
            }
        }

        @usableFromInline
        var parameters: [(name: String, value: Substring?)] {
            var positions: [String: Int] = [:]
            positions.reserveCapacity(self.storage.count)
            return self.order.map { name in
                let position = positions[name, default: 0]
                positions[name] = position + 1
                guard let values = self.storage[name], position < values.count
                else { preconditionFailure("Field order and storage are inconsistent") }
                return (name, values[values.index(values.startIndex, offsetBy: position)])
            }
        }

        @usableFromInline
        mutating func reconcile(
            from previous: OrderedDictionary<String, ArraySlice<Substring?>>
        ) {
            for (name, values) in previous {
                let current = self.storage[name] ?? []
                let removed = values.count - current.count
                guard removed > 0 else { continue }

                if current.elementsEqual(values.dropFirst(removed)) {
                    for _ in 0..<removed {
                        guard let index = self.order.firstIndex(of: name) else { break }
                        self.order.remove(at: index)
                    }
                } else {
                    for _ in 0..<removed {
                        guard let index = self.order.lastIndex(of: name) else { break }
                        self.order.remove(at: index)
                    }
                }
            }

            for (name, values) in self.storage {
                let previousValues = previous[name] ?? []
                let inserted = values.count - previousValues.count
                guard inserted > 0 else { continue }

                if previousValues.elementsEqual(values.suffix(previousValues.count)),
                    let index = self.order.firstIndex(of: name)
                {
                    self.order.insert(contentsOf: repeatElement(name, count: inserted), at: index)
                } else {
                    self.order.append(contentsOf: repeatElement(name, count: inserted))
                }
            }
        }

        @usableFromInline
        mutating func prepend(_ fields: Self) {
            self.storage.merge(fields.storage) { current, incoming in
                ArraySlice(incoming + current)
            }
            self.order.insert(contentsOf: fields.order, at: self.order.startIndex)
        }

        @inlinable
        public subscript(name: String) -> ArraySlice<Substring?>? {
            _read { yield self.storage[self.isCaseSensitive ? name : name.lowercased()] }
            _modify { yield &self.fields[self.isCaseSensitive ? name : name.lowercased()] }
        }

        @inlinable
        public subscript(
            name: String, default defaultValue: @autoclosure () -> ArraySlice<Substring?>
        ) -> ArraySlice<Substring?> {
            _read {
                yield self.storage[
                    self.isCaseSensitive ? name : name.lowercased(),
                    default: defaultValue()
                ]
            }
            _modify {
                yield &self.fields[
                    self.isCaseSensitive ? name : name.lowercased(),
                    default: defaultValue()
                ]
            }
        }

        @inlinable
        public var isEmpty: Bool {
            self.storage.isEmpty
        }
    }
}

// MARK: - Codable

extension RFC_3986.URI.Request.Data: Swift.Codable {
    @inlinable
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            method: try container.decodeIfPresent(RFC_7231.Method.self, forKey: .method),
            scheme: try container.decodeIfPresent(String.self, forKey: .scheme),
            userinfo: try container.decodeIfPresent(String.self, forKey: .userinfo),
            host: try container.decodeIfPresent(String.self, forKey: .host),
            port: try container.decodeIfPresent(Int.self, forKey: .port),
            path: try container.decodeIfPresent(String.self, forKey: .path) ?? "",
            query: try container.decodeIfPresent(
                OrderedDictionary<String, [String?]>.self,
                forKey: .query
            ) ?? [:],
            fragment: try container.decodeIfPresent(String.self, forKey: .fragment),
            headers: try container.decodeIfPresent(
                OrderedDictionary<String, [String?]>.self,
                forKey: .headers
            ) ?? [:],
            body: try container.decodeIfPresent(Foundation.Data.self, forKey: .body)
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

extension RFC_3986.URI.Request.Data: Hashable {
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

extension RFC_3986.URI.Request.Fields: Swift.Collection {
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

extension RFC_3986.URI.Request.Fields: ExpressibleByDictionaryLiteral {
    @inlinable
    public init(dictionaryLiteral elements: (String, ArraySlice<Substring?>)...) {
        self.init(.init(elements) { $0 + $1 }, isCaseSensitive: true)
    }
}

extension RFC_3986.URI.Request.Fields: Hashable {
    @inlinable
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.storage)
    }
}

extension RFC_3986.URI.Request.Fields {
    // Occurrence order is an internal wire detail; the public grouped-fields
    // equality contract remains based on field names and values.
    @inlinable
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.storage == rhs.storage && lhs.isCaseSensitive == rhs.isCaseSensitive
    }
}

// MARK: - Convenience Type Alias

/// Convenience type alias for `RFC_3986.URI.Request.Data`
///
/// For cleaner code, you can use `URIRequestData` instead of `RFC_3986.URI.Request.Data`:
/// ```swift
/// var data = URIRequestData(method: "GET", path: "/users")
/// ```
public typealias URIRequestData = RFC_3986.URI.Request.Data
