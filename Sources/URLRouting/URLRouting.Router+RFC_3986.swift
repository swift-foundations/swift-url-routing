import RFC_3986
//import RFC_6570

extension URLRouting.Router where Input == RFC_3986.URI.Request.Data {
    /// Matches an RFC 3986 URI to a route.
    ///
    /// Parses the URI into request data and runs the router's parser.
    ///
    /// Example:
    /// ```swift
    /// let uri = try RFC_3986.URI("/books/42")
    /// let route = try router.match(uri: uri)
    /// ```
    ///
    /// - Parameter uri: An RFC 3986 URI reference
    /// - Returns: The parsed route output
    /// - Throws: Parsing errors if the URI doesn't match any route
    public func match(uri: RFC_3986.URI) throws -> Output {
        var data = try RFC_3986.URI.Request.Data(uri: uri)
        return try self.parse(&data)
    }

    /// Matches an RFC 3986 URI string to a route.
    ///
    /// Convenience method that parses the URI string and matches it.
    ///
    /// Example:
    /// ```swift
    /// let route = try router.match(uriString: "/books/42")
    /// ```
    ///
    /// - Parameter uriString: A URI string
    /// - Returns: The parsed route output
    /// - Throws: RFC_3986.Error if the string is invalid, or parsing errors
    public func match(uriString: String) throws -> Output {
        let uri = try RFC_3986.URI(uriString)
        return try self.match(uri: uri)
    }

    /// Prints a route to an RFC 3986 URI.
    ///
    /// Runs the router's printer and constructs an RFC-compliant URI.
    ///
    /// Example:
    /// ```swift
    /// let uri = try router.uri(for: .book(id: 42))
    /// // Result: RFC_3986.URI("/books/42")
    /// ```
    ///
    /// - Parameter output: The route to print
    /// - Returns: An RFC 3986 URI reference
    /// - Throws: Printing errors or RFC_3986.Error if construction fails
    public func uri(for output: Output) throws -> RFC_3986.URI {
        var data = RFC_3986.URI.Request.Data()
        try self.print(output, into: &data)
        return try data.uri()
    }

    /// Prints a route to an RFC 3986 URI string.
    ///
    /// Convenience method that returns the URI value as a string.
    ///
    /// Example:
    /// ```swift
    /// let path = try router.path(for: .book(id: 42))
    /// // Result: "/books/42"
    /// ```
    ///
    /// - Parameter output: The route to print
    /// - Returns: A URI string
    /// - Throws: Printing errors or RFC_3986.Error if construction fails
    public func path(for output: Output) throws -> String {
        try self.uri(for: output).value
    }
}
