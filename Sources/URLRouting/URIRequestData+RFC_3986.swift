import RFC_3986

extension RFC_3986.URI.Request.Data {
    /// Initializes parseable request data from an RFC 3986 URI.
    ///
    /// Parses the URI using the RFC 3986 engine's typed components, properly handling:
    /// - Relative references (URIs without schemes)
    /// - Empty URIs (same document reference)
    /// - Percent-encoded components (the raw path is split on `/` BEFORE each
    ///   segment is percent-decoded, so `%2F` inside a segment does not split)
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
        self.init(
            method: nil,
            scheme: uri.scheme?.value,
            userinfo: uri.userinfo.map { RFC_3986.percentDecode($0.rawValue) },
            host: uri.host.map { RFC_3986.percentDecode($0.rawValue) },
            port: uri.port.map { Int($0.value) },
            // The raw (still percent-encoded) path: the memberwise initializer
            // splits it on "/" before decoding each segment.
            path: uri.path?.description ?? "",
            query: [:],
            fragment: uri.fragment.map { RFC_3986.percentDecode($0.value) }
        )
        self.query = RFC_3986.URI.Request.Fields(
            uri.query?.parameters.map { parameter in
                (
                    RFC_3986.percentDecode(parameter.key),
                    parameter.value.map(RFC_3986.percentDecode)
                )
            } ?? [],
            isCaseSensitive: true
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
        var uriString = ""

        if let scheme = self.scheme {
            uriString += "\(scheme):"
        }

        let hasAuthority = self.userinfo != nil || self.host != nil || self.port != nil
        if hasAuthority {
            uriString += "//"

            if let userinfo = self.userinfo {
                // The userinfo grammar admits ":" directly, so the whole
                // user:password value encodes as one component.
                uriString += "\(RFC_3986.percentEncode(userinfo, allowing: .userinfo))@"
            }

            if let host = self.host {
                // Valid hosts (including IP-literals like "[::1]") pass through
                // verbatim; anything else is percent-encoded as a reg-name.
                if (try? RFC_3986.URI.Host(host)) != nil {
                    uriString += host
                } else {
                    uriString += RFC_3986.percentEncode(host, allowing: .host)
                }
            }

            if let port = self.port {
                uriString += ":\(port)"
            }
        }

        if !self.path.isEmpty {
            uriString += "/"
            uriString += self.path
                .map { RFC_3986.percentEncode(String($0), allowing: .pathSegment) }
                .joined(separator: "/")
        }

        if !self.query.isEmpty {
            uriString += "?"
            uriString += self.query.parameters
                .map { name, value in
                    let encodedName = RFC_3986.percentEncode(name, allowing: .queryComponent)
                    guard let value else { return encodedName }
                    let encodedValue = RFC_3986.percentEncode(
                        String(value),
                        allowing: .queryComponent
                    )
                    return "\(encodedName)=\(encodedValue)"
                }
                .joined(separator: "&")
        }

        if let fragment = self.fragment {
            uriString += "#\(RFC_3986.percentEncode(fragment, allowing: .fragment))"
        }

        return try RFC_3986.URI(uriString)
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
