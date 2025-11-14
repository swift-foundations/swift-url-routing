//
//  RFC_2045.ContentType+Extensions.swift
//  swift-url-routing
//
//  Created by Coen ten Thije Boonkkamp on 14/01/2025.
//

import RFC_2045

// MARK: - String Convenience Methods

extension RFC_2045.ContentType {
    /// Checks if the header value representation contains the specified string.
    ///
    /// This convenience method allows using ContentType directly in string matching operations
    /// without explicitly calling `.headerValue`.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let contentType = RFC_2045.ContentType(type: "multipart", subtype: "form-data")
    /// #expect(contentType.contains("multipart/form-data"))
    /// ```
    ///
    /// - Parameter string: The string to search for
    /// - Returns: `true` if the header value contains the string, `false` otherwise
    public func contains(_ string: String) -> Bool {
        headerValue.contains(string)
    }
}
