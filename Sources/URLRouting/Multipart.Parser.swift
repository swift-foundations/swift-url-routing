//
//  Multipart.Parser.swift
//  swift-url-routing
//
//  Created by Coen ten Thije Boonkkamp on 15/11/2025.
//

import Foundation
import Parsing
import RFC_2046
import RFC_3986
import RFC_7230

/// A parser that handles multipart/form-data for Codable types.
///
/// `Multipart<Value>` provides a clean parser that automatically handles both
/// Content-Type headers and multipart body encoding/decoding.
///
/// ## Example
///
/// ```swift
/// struct UpdateRequest: Codable {
///     let name: String
///     let subscribed: Bool
/// }
///
/// Route(.case(API.update)) {
///     Method.post
///     Path { "v3" / "domain" / "members" }
///     Multipart(UpdateRequest.self, arrayEncodingStrategy: .brackets)
/// }
/// ```
///
/// ## Usage
///
/// The parser combines Content-Type header parsing with body conversion:
/// ```swift
/// // Before (verbose):
/// let conversion = RFC_2046.Multipart.Conversion(UpdateRequest.self)
/// Headers {
///     Field("Content-Type") { conversion.contentType.headerValue }
/// }
/// Body(conversion)
///
/// // After (concise):
/// Multipart(UpdateRequest.self, arrayEncodingStrategy: .brackets)
/// ```
public struct Multipart<Value: Codable>  {
    public typealias Input = RFC_3986.URI.Request.Data
    public typealias Output = Value

    let type: Value.Type
    let arrayEncodingStrategy: RFC_2046.Multipart.Array.EncodingStrategy

    /// Creates a multipart parser for the specified Codable type.
    ///
    /// - Parameters:
    ///   - type: The Codable type to parse/print
    ///   - arrayEncodingStrategy: How to encode array fields (default: accumulate values)
    public init(
        _ type: Value.Type,
        arrayEncodingStrategy: RFC_2046.Multipart.Array.EncodingStrategy = .accumulateValues
    ) {
        self.type = type
        self.arrayEncodingStrategy = arrayEncodingStrategy
    }
}

extension Multipart: ParserPrinter {
    public func parse(_ input: inout RFC_3986.URI.Request.Data) throws -> Value {
        let conversion = RFC_2046.Multipart.Conversion(type, arrayEncodingStrategy: arrayEncodingStrategy)

        // Parse Content-Type header
        try Parse {
            Headers {
                RFC_7230.Header.Field("Content-Type") { conversion.contentType.headerValue }
            }
        }.parse(&input)

        // Parse body
        return try Body(conversion).parse(&input)
    }

    public func print(_ output: Value, into input: inout RFC_3986.URI.Request.Data) throws {
        let conversion = RFC_2046.Multipart.Conversion(type, arrayEncodingStrategy: arrayEncodingStrategy)

        // Print Content-Type header
        try Parse {
            Headers {
                RFC_7230.Header.Field("Content-Type") { conversion.contentType.headerValue }
            }
        }.print((), into: &input)

        // Print body
        try Body(conversion).print(output, into: &input)
    }
}
