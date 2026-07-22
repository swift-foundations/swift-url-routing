//
//  Multipart.Conversion.swift
//  swift-url-routing
//
//  Created by Coen ten Thije Boonkkamp on 15/11/2025.
//

import Foundation
import MultipartFormCoding
import RFC_2045
import RFC_2046
import RFC_3986
import RFC_7578

// MARK: - RFC_2046.Multipart.Conversion

extension RFC_2046.Multipart {
    /// A conversion that handles multipart/form-data encoding for Codable types.
    ///
    /// `RFC_2046.Multipart.Conversion` provides automatic conversion from Swift Codable types to
    /// multipart/form-data format, commonly used by APIs like Mailgun that require this
    /// encoding for non-file fields.
    ///
    /// ## Usage
    ///
    /// ```swift
    /// struct UpdateRequest: Codable {
    ///     let name: String
    ///     let subscribed: Bool
    ///     let vars: [String: String]?
    /// }
    ///
    /// let conversion = RFC_2046.Multipart.Conversion(UpdateRequest.self)
    ///
    /// // Use in route definition
    /// Route {
    ///     Method.put
    ///     Path { "members" / \.id }
    ///     Body(conversion)
    /// }
    /// ```
    ///
    /// ## Array Encoding Strategies
    ///
    /// - `.accumulateValues`: Repeats field name for each value (Mailgun style)
    ///   ```
    ///   --boundary
    ///   Content-Disposition: form-data; name="tags"
    ///
    ///   swift
    ///   --boundary
    ///   Content-Disposition: form-data; name="tags"
    ///
    ///   ios
    ///   ```
    ///
    /// - `.brackets`: Uses empty brackets notation (PHP/Rails style)
    ///   ```
    ///   --boundary
    ///   Content-Disposition: form-data; name="tags[]"
    ///
    ///   swift
    ///   ```
    public struct Conversion<Value: Swift.Codable>: @unchecked Sendable {
        /// The validated boundary used to separate multipart fields.
        public let boundary: RFC_2046.Boundary

        /// The encoder used for encoding values to multipart format
        public let encoder: RFC_2046.Multipart.Encoder

        /// Creates a new multipart form coding conversion.
        ///
        /// - Parameters:
        ///   - type: The Codable type to convert to/from
        ///   - encoder: Multipart encoder with encoding strategies (default: new encoder)
        ///   - boundary: Optional custom boundary string (generates one if not provided)
        ///
        /// ## Example
        ///
        /// ```swift
        /// let encoder = RFC_2046.Multipart.Encoder()
        /// encoder.boolEncoder = .yesNo
        /// encoder.fileExtractor = { value in
        ///     if let attachment = value as? Attachment {
        ///         return RFC_2046.Multipart.File(...)
        ///     }
        ///     return nil
        /// }
        ///
        /// let conversion = RFC_2046.Multipart.Conversion(Request.self, encoder: encoder)
        /// ```
        public init(
            _ type: Value.Type,
            encoder: RFC_2046.Multipart.Encoder = RFC_2046.Multipart.Encoder(),
            boundary: RFC_2046.Boundary? = nil
        ) {
            self.boundary = boundary ?? RFC_2046.Boundary(__unchecked: (), rawValue: "----FormBoundary\(UUID().uuidString)")
            self.encoder = encoder
        }

        /// Creates a new multipart form coding conversion with array strategy.
        ///
        /// - Parameters:
        ///   - type: The Codable type to convert to/from
        ///   - arrayEncodingStrategy: How to encode array fields
        ///   - boundary: Optional custom boundary string (generates one if not provided)
        ///
        /// - Note: This initializer is provided for backward compatibility.
        ///   Prefer using the encoder-based initializer for more control.
        public init(
            _ type: Value.Type,
            arrayEncodingStrategy: RFC_2046.Multipart.Array.EncodingStrategy,
            boundary: RFC_2046.Boundary? = nil
        ) {
            let encoder = RFC_2046.Multipart.Encoder()
            encoder.arrayEncodingStrategy = arrayEncodingStrategy
            self.init(type, encoder: encoder, boundary: boundary)
        }

        /// The Content-Type header value for multipart/form-data requests.
        ///
        /// Returns an RFC 2045 ContentType with the format: `multipart/form-data; boundary=<unique-boundary>`
        public var contentType: RFC_2045.ContentType {
            RFC_2045.ContentType(__unchecked: (), type: "multipart",
                subtype: "form-data",
                parameters: [.boundary: boundary.rawValue]
            )
        }
    }
}

// MARK: - Conversion Protocol Conformance

extension RFC_2046.Multipart.Conversion: Parser.Conversion.`Protocol` {
    public typealias Input = Foundation.Data
    public typealias Output = Value
    public typealias Failure = RFC_3986.URI.Routing.Error

    /// Converts multipart form data to a Swift value.
    ///
    /// - Parameter input: The form data to decode
    /// - Returns: The decoded Swift value
    /// - Throws: Decoding errors
    ///
    /// - Note: Parses multipart data using RFC 2046 parser and converts to Swift value via JSON.
    public func apply(_ input: Data) throws(RFC_3986.URI.Routing.Error) -> Value {
      do {
        // Parse multipart data using RFC 2046 (byte-cursor parser).
        let parser = RFC_2046.Multipart.Parser(boundary: boundary, subtype: .formData)
        let multipart = try RFC_2046.Multipart.parse(from: [Byte](input), parser: parser)

        // Extract form fields to dictionary
        let fields = multipart.extractFormFields()

        // Convert dictionary to JSON and then decode to Value type
        let jsonData = try JSONSerialization.data(withJSONObject: fields)
        let decoder = JSONDecoder()
        let result = try decoder.decode(Value.self, from: jsonData)
        return result
      } catch {
        throw RFC_3986.URI.Routing.Error(component: .body, failure: .parseFailed("\(error)"))
      }
    }

    /// Converts a Swift value to multipart form data.
    ///
    /// This method encodes the Swift value to RFC 7578-compliant multipart/form-data
    /// format using the RFC 2046 Multipart implementation.
    ///
    /// - Parameter output: The Swift value to encode
    /// - Returns: The multipart form data as `Data`
    /// - Throws: Encoding errors
    public func unapply(_ output: Value) throws(RFC_3986.URI.Routing.Error) -> Foundation.Data {
      do {
        // Step 1: Extract field→value pairs using our custom encoder
        let fieldEncoder = RFC_2046.Multipart.Field.Encoder(multipartEncoder: encoder)
        try output.encode(to: fieldEncoder)

        // Step 2: Validate we have at least one field or file
        guard !fieldEncoder.fields.isEmpty || !fieldEncoder.files.isEmpty else {
            throw Error.emptyRequest(
                reason: "Cannot encode \(Value.self) as multipart/form-data: all fields are nil or empty. At least one field must have a value."
            )
        }

        // Step 3: Convert text fields to RFC_2046.BodyPart. Content-Disposition comes
        // from RFC 2183 (handles escaping of special characters in field names); the
        // value is carried as body content. Built per-field to preserve duplicate
        // field names (array encoding strategies repeat a name).
        let fieldParts: [RFC_2046.BodyPart] = fieldEncoder.fields.map { field in
            RFC_2046.BodyPart(
                headers: RFC_2046.BodyPart.Headers(
                    contentDisposition: .formData(name: field.name)
                ),
                content: RFC_2046.BodyPart.Content(field.value)
            )
        }

        // Step 4: Convert file fields to RFC_2046.BodyPart
        let fileParts: [RFC_2046.BodyPart] = fieldEncoder.files.map { file in
            let base64Content = Data(file.content).base64EncodedString()
            return RFC_2046.BodyPart(
                headers: RFC_2046.BodyPart.Headers(
                    contentDisposition: .formData(
                        name: file.fieldName,
                        filename: file.filename
                    ),
                    contentType: file.contentType ?? .applicationOctetStream,
                    contentTransferEncoding: .base64
                ),
                content: RFC_2046.BodyPart.Content(base64Content)
            )
        }

        // Step 5: Combine all parts
        let allParts = fieldParts + fileParts

        // Step 6: Build RFC 2046-compliant multipart message
        let multipart = try RFC_2046.Multipart(
            subtype: .formData,
            parts: allParts,
            boundary: boundary
        )

        // Step 7: Serialize to RFC-compliant bytes (CRLF line endings) and return as Data.
        var buffer: [Byte] = []
        RFC_2046.Multipart.serialize(multipart, into: &buffer)
        return Data(buffer.map { $0.underlying } as [UInt8])
      } catch {
        throw RFC_3986.URI.Routing.Error(component: .body, failure: .parseFailed("\(error)"))
      }
    }
}

// MARK: - Conversion Convenience Methods

extension URLRouting.Conversion {
    /// Creates a multipart form data conversion for the specified Codable type.
    ///
    /// This static method provides a convenient way to create ``RFC_2046.Multipart.Conversion``
    /// instances for use in URLRouting route definitions.
    ///
    /// - Parameters:
    ///   - type: The Codable type to convert to/from multipart form data
    ///   - arrayEncodingStrategy: How to encode array fields (default: accumulate values)
    /// - Returns: A ``RFC_2046.Multipart.Conversion`` instance
    ///
    /// ## Example
    ///
    /// ```swift
    /// struct UpdateRequest: Codable {
    ///     let name: String
    ///     let subscribed: Bool
    /// }
    ///
    /// // Create conversion with default array strategy
    /// let conversion = Conversion.multipart(UpdateRequest.self)
    ///
    /// // Or with custom array strategy
    /// let conversion = Conversion.multipart(
    ///     UpdateRequest.self,
    ///     arrayEncodingStrategy: .brackets
    /// )
    /// ```
    ///
    /// ## Usage in Routes
    ///
    /// ```swift
    /// Route {
    ///     Method.put
    ///     Path { "members" / \.id }
    ///     Body(.multipart(UpdateRequest.self))
    /// }
    /// ```
    @available(
        *,
        deprecated,
        message: "Use URLRouting.Body(coding: RFC_2046.Multipart.Conversion(...)) so Content-Type is emitted."
    )
    public static func multipart<Value>(
        _ type: Value.Type,
        arrayEncodingStrategy: RFC_2046.Multipart.Array.EncodingStrategy = .accumulateValues
    ) -> Self where Self == RFC_2046.Multipart.Conversion<Value> {
        .init(type, arrayEncodingStrategy: arrayEncodingStrategy)
    }
}
