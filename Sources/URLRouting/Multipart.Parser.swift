//
//  Multipart.Parser.swift
//  swift-url-routing
//
//  Created by Coen ten Thije Boonkkamp on 15/11/2025.
//

import Foundation
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
/// Route(.case(\.update)) {
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
/// RFC_7230.Body.Parser(conversion)
///
/// // After (concise):
/// Multipart(UpdateRequest.self, arrayEncodingStrategy: .brackets)
/// ```
public struct Multipart<Value: Swift.Codable>  {
    public typealias Input = RFC_3986.URI.Request.Data
    public typealias Output = Value
    public typealias Failure = RFC_3986.URI.Routing.Error

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

extension Multipart: Parser.Bidirectional {
    public func parse(_ input: inout RFC_3986.URI.Request.Data) throws(RFC_3986.URI.Routing.Error) -> Value {
        let conversion = RFC_2046.Multipart.Conversion(type, arrayEncodingStrategy: arrayEncodingStrategy)
        // The multipart body conversion carries its own boundary, so the Content-Type
        // header is not required to decode; parse the body directly.
        return try RFC_7230.Body.Parser(conversion).parse(&input)
    }

    /// The emission buffer type — `Parser.Bidirectional` pins `Buffer == Input`.
    public typealias Buffer = RFC_3986.URI.Request.Data

    /// Explicit leaf body: both `Parser.Protocol` and `Serializer.Protocol`
    /// supply a `Body == Never` default getter; the explicit override
    /// disambiguates between the two inherited candidates (the Coder.Witness
    /// precedent).
    @inlinable
    public var body: Never {
        borrowing get { return fatalError("leaf router — serialize(_:into:) is implemented directly") }
    }

    public func serialize(_ output: Value, into input: inout RFC_3986.URI.Request.Data) throws(RFC_3986.URI.Routing.Error) {
        let conversion = RFC_2046.Multipart.Conversion(type, arrayEncodingStrategy: arrayEncodingStrategy)
        // Emit the multipart/form-data Content-Type header (carrying the boundary).
        input.headers["Content-Type"] = [Optional(Substring(conversion.contentType.headerValue))][...]
        // Print body
        try RFC_7230.Body.Parser(conversion).print(output, into: &input)
    }
}
