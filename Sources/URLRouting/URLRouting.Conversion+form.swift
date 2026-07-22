//
//  URLRouting.Conversion+form.swift
//  swift-url-routing
//
//  Created by Coen ten Thije Boonkkamp on 15/11/2025.
//

import Foundation
import URLFormCoding

// MARK: - Conversion Convenience Methods

extension URLRouting.Conversion {
    /// Creates a URL form data conversion for the specified Codable type.
    ///
    /// This static method provides a convenient way to create ``Form.Conversion``
    /// instances for use in URLRouting route definitions. Form coding handles
    /// standard web form data (application/x-www-form-urlencoded).
    ///
    /// - Parameters:
    ///   - type: The Codable type to convert to/from form data
    ///   - decoder: Optional custom URL form decoder (uses default if not provided)
    ///   - encoder: Optional custom URL form encoder (uses default if not provided)
    /// - Returns: A ``Form.Conversion`` instance
    ///
    /// ## Example
    ///
    /// ```swift
    /// struct LoginRequest: Codable {
    ///     let username: String
    ///     let password: String
    /// }
    ///
    /// // Create conversion with default encoder/decoder
    /// let loginConversion = Conversion.form(LoginRequest.self)
    ///
    /// // Create conversion with custom configuration
    /// let decoder = Form.Decoder()
    /// decoder.arrayParsingStrategy = .brackets
    /// let encoder = Form.Encoder()
    /// encoder.dateEncodingStrategy = .iso8601
    ///
    /// let customConversion = Conversion.form(
    ///     LoginRequest.self,
    ///     decoder: decoder,
    ///     encoder: encoder
    /// )
    /// ```
    ///
    /// ## Usage in Routes
    ///
    /// ```swift
    /// Route {
    ///     Method.post
    ///     Path { "login" }
    ///     Body(.form(LoginRequest.self))
    /// }
    /// ```
    @available(
        *,
        deprecated,
        message: "Use URLRouting.Body(coding: .form(...)) so Content-Type is emitted."
    )
    public static func form<Value>(
        _ type: Value.Type,
        decoder: Form.Decoder = .init(),
        encoder: Form.Encoder = .init()
    ) -> Self where Self == Form.Conversion<Value> {
        .init(type, decoder: decoder, encoder: encoder)
    }
}
