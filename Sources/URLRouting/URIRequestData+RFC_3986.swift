import Foundation
import RFC_3986

#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif

extension RFC_3986.URI.Request.Data {
    /// Initializes parseable request data from an RFC 3986 URI.
    ///
    /// Parses the URI using RFC 3986 compliant rules, properly handling:
    /// - Relative references (URIs without schemes)
    /// - Empty URIs (same document reference)
    /// - Percent-encoded components
    ///
    /// Example:
    /// ```swift
    /// let uri = try RFC_3986.URI("/users/123?page=1#section")
    /// let requestData = try RFC_3986.URI.Request.Data(uri: uri)
    /// ```
    ///
    /// - Parameter uri: An RFC 3986 URI reference
    /// - Throws: RFC_3986.Error if URI parsing fails
    public init(uri: RFC_3986.URI) throws {
        // Use Foundation's URLComponents for initial parsing
        // TODO: Replace with pure Swift RFC 3986 parser
        guard let components = URLComponents(string: uri.value)
        else {
            throw RFC_3986.Error.invalidURI("Failed to parse URI: \(uri.value)")
        }

        self.init(
            method: nil,
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
            fragment: components.fragment
        )
    }

    /// Initializes a parseable URI request from an RFC 3986 URI string.
    ///
    /// Convenience initializer that validates and parses the URI string.
    ///
    /// Example:
    /// ```swift
    /// let requestData = try RFC_3986.URI.Request.Data(uriString: "/api/users/123")
    /// ```
    ///
    /// - Parameter uriString: A URI string
    /// - Throws: RFC_3986.Error if the string is not a valid URI
    public init(uriString: String) throws {
        let uri = try RFC_3986.URI(uriString)
        try self.init(uri: uri)
    }

    /// Converts the request data to an RFC 3986 URI.
    ///
    /// Reconstructs a URI from the request data components using RFC-compliant
    /// percent-encoding. Returns a relative reference if no scheme is present.
    ///
    /// Example:
    /// ```swift
    /// let requestData = RFC_3986.URI.Request.Data(
    ///   scheme: "https",
    ///   host: "api.example.com",
    ///   path: "/users/123",
    ///   query: ["page": ["1"]]
    /// )
    /// let uri = try requestData.uri()
    /// // Result: RFC_3986.URI("https://api.example.com/users/123?page=1")
    /// ```
    ///
    /// - Returns: An RFC 3986 URI reference
    /// - Throws: RFC_3986.Error if URI construction fails
    public func uri() throws -> RFC_3986.URI {
        var components = URLComponents()
        components.scheme = self.scheme

        // Split userinfo into user and password
        if let userinfo = self.userinfo {
            let parts = userinfo.split(separator: ":", maxSplits: 1)
            components.user = String(parts[0])
            if parts.count > 1 {
                components.password = String(parts[1])
            }
        }

        components.host = self.host
        components.port = self.port

        // Reconstruct path
        if !self.path.isEmpty {
            components.path = "/\(self.path.joined(separator: "/"))"
        } else if self.scheme != nil || self.host != nil {
            // Absolute URIs with authority should have at least empty path
            components.path = ""
        }

        // Reconstruct query
        if !self.query.isEmpty {
            components.queryItems = self.query.fields
                .flatMap { name, values in
                    values.map { URLQueryItem(name: name, value: $0.map(String.init)) }
                }
        }

        components.fragment = self.fragment

        guard let urlString = components.url?.absoluteString ?? components.string else {
            throw RFC_3986.Error.invalidURI("Failed to construct URI from request data")
        }

        // Use unchecked initializer since URLComponents produces valid URIs
        return RFC_3986.URI(unchecked: urlString)
    }

    /// Converts the request data to an RFC 3986 URI string.
    ///
    /// Convenience property that returns the URI value as a string.
    ///
    /// Example:
    /// ```swift
    /// let requestData = RFC_3986.URI.Request.Data(path: "/users/123")
    /// let uriString = try requestData.uriString
    /// // Result: "/users/123"
    /// ```
    public var uriString: String {
        get throws {
            try uri().value
        }
    }
}
