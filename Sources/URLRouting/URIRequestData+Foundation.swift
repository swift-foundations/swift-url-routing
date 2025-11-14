import Foundation
import RFC_3986
import RFC_7231

#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif

// MARK: - Foundation URL/URLRequest Bridge

extension RFC_3986.URI.Request.Data {
    /// Initializes parseable request data from a Foundation URLRequest.
    ///
    /// Bridges Foundation URLRequest to RFC-compliant RFC_3986.URI.Request.Data.
    ///
    /// Example:
    /// ```swift
    /// let request = URLRequest(url: URL(string: "https://api.example.com/users/123")!)
    /// guard let requestData = RFC_3986.URI.Request.Data(request: request) else { return }
    /// let route = try router.parse(requestData)
    /// ```
    ///
    /// - Parameter request: A Foundation URL request
    public init?(request: URLRequest) {
        guard
            let url = request.url,
            let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        else { return nil }

        self.init(
            method: request.httpMethod.map { RFC_7231.Method(rawValue: $0) },
            scheme: components.scheme,
            userinfo: {
                // Reconstruct userinfo from user and password
                if let user = components.user {
                    if let password = components.password {
                        return "\(user):\(password)"
                    }
                    return user
                }
                return nil
            }(),
            host: components.host,
            port: components.port,
            path: components.path,
            query: components.queryItems?.reduce(into: [:]) { query, item in
                query[item.name, default: []].append(item.value)
            } ?? [:],
            fragment: components.fragment,
            headers: .init(
                request.allHTTPHeaderFields?.map { key, value in
                    (
                        key,
                        value.split(separator: ",", omittingEmptySubsequences: false).map {
                            String($0)
                        }
                    )
                } ?? [],
                uniquingKeysWith: { $1 }
            ),
            body: request.httpBody
        )
    }

    /// Initializes a parseable URL request from a Foundation URL.
    ///
    /// Example:
    /// ```swift
    /// let url = URL(string: "https://api.example.com/users/123")!
    /// guard let requestData = RFC_3986.URI.Request.Data(url: url) else { return }
    /// ```
    ///
    /// - Parameter url: A Foundation URL
    public init?(url: URL) {
        self.init(request: URLRequest(url: url))
    }

    /// Initializes a parseable URL request from a URL string using Foundation.
    ///
    /// Example:
    /// ```swift
    /// guard let requestData = RFC_3986.URI.Request.Data(string: "https://api.example.com/users/123")
    /// else { return }
    /// ```
    ///
    /// - Parameter string: A URL string
    public init?(string: String) {
        guard let url = URL(string: string)
        else { return nil }
        self.init(url: url)
    }
}

// MARK: - Foundation URLComponents Bridge

extension URLComponents {
    /// Initializes URLComponents from RFC-compliant RFC_3986.URI.Request.Data.
    ///
    /// Converts RFC_3986.URI.Request.Data back to Foundation types for compatibility.
    ///
    /// Example:
    /// ```swift
    /// let requestData = RFC_3986.URI.Request.Data(
    ///   scheme: "https",
    ///   host: "api.example.com",
    ///   path: "/users/123"
    /// )
    /// let components = URLComponents(data: requestData)
    /// let url = components.url
    /// ```
    ///
    /// - Parameter data: URI request data
    public init(data: RFC_3986.URI.Request.Data) {
        self.init()
        self.scheme = data.scheme

        // Split userinfo into user and password
        if let userinfo = data.userinfo {
            let parts = userinfo.split(separator: ":", maxSplits: 1)
            self.user = String(parts[0])
            if parts.count > 1 {
                self.password = String(parts[1])
            }
        }

        self.host = data.host
        self.port = data.port

        // Reconstruct path
        if !data.path.isEmpty {
            self.path = "/\(data.path.joined(separator: "/"))"
        } else if data.scheme != nil || data.host != nil {
            // Absolute URIs with authority should have at least empty path
            self.path = ""
        }

        // Reconstruct query
        if !data.query.isEmpty {
            self.queryItems = data.query.fields
                .flatMap { name, values in
                    values.map { URLQueryItem(name: name, value: $0.map(String.init)) }
                }
        }

        self.fragment = data.fragment
    }
}

// MARK: - Foundation URLRequest Bridge

extension URLRequest {
    /// Initializes a URLRequest from RFC-compliant RFC_3986.URI.Request.Data.
    ///
    /// Converts RFC_3986.URI.Request.Data back to Foundation URLRequest.
    ///
    /// Example:
    /// ```swift
    /// let requestData = RFC_3986.URI.Request.Data(
    ///   method: .post,
    ///   scheme: "https",
    ///   host: "api.example.com",
    ///   path: "/users",
    ///   body: jsonData
    /// )
    /// guard let request = URLRequest(data: requestData) else { return }
    /// ```
    ///
    /// - Parameter data: URI request data
    public init?(data: RFC_3986.URI.Request.Data) {
        guard let url = URLComponents(data: data).url else { return nil }
        self.init(url: url)
        self.httpMethod = data.method?.rawValue
        for (name, values) in data.headers {
            for value in values {
                if let value = value {
                    self.addValue(String(value), forHTTPHeaderField: name)
                }
            }
        }
        self.httpBody = data.body.map { Data($0) }
    }
}

// MARK: - RFC 3986 URI to Foundation URL Bridge

extension URL {
    /// Creates a Foundation URL from an RFC 3986 URI.
    ///
    /// Example:
    /// ```swift
    /// let uri = try RFC_3986.URI("https://api.example.com/users/123")
    /// let url = URL(uri: uri)
    /// ```
    ///
    /// - Parameter uri: An RFC 3986 URI
    /// - Throws: Error if the URI cannot be converted to a valid URL
    public init(uri: RFC_3986.URI) throws {
        guard let url = URL(string: uri.value) else {
            throw RFC_3986.Error.invalidURI("Cannot convert URI to Foundation URL: \(uri.value)")
        }
        self = url
    }
}
