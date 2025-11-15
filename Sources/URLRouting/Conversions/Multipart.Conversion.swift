//
//  MultipartConversion.swift
//  swift-url-routing
//
//  Created by Coen ten Thije Boonkkamp on 13/01/2025.
//

import Foundation
import Parsing
import MultipartFormCoding
import RFC_2045
import RFC_2046
import RFC_7578

// MARK: - Multipart.Conversion

/// A conversion that handles multipart/form-data encoding for Codable types.
///
/// `Multipart.Conversion` provides automatic conversion from Swift Codable types to
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
/// let conversion = Multipart.Conversion(UpdateRequest.self)
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

/// Strategy for encoding arrays in multipart fields.
public enum MultipartArrayEncodingStrategy: Sendable {
    /// Repeats the field name for each array element.
    /// Example: `name="tags"\r\n\r\nswift\r\n...name="tags"\r\n\r\nios`
    case accumulateValues
    
    /// Appends empty brackets to field name.
    /// Example: `name="tags[]"\r\n\r\nswift\r\n...name="tags[]"\r\n\r\nios`
    case brackets
}

extension RFC_2046.Multipart {
    public struct Conversion<Value: Codable>: @unchecked Sendable {
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
        /// let encoder = Multipart.Encoder()
        /// encoder.boolEncoder = .yesNo
        /// encoder.fileExtractor = { value in
        ///     if let attachment = value as? Attachment {
        ///         return RFC_2046.Multipart.File(...)
        ///     }
        ///     return nil
        /// }
        ///
        /// let conversion = Multipart.Conversion(Request.self, encoder: encoder)
        /// ```
        public init(
            _ type: Value.Type,
            encoder: RFC_2046.Multipart.Encoder = RFC_2046.Multipart.Encoder(),
            boundary: RFC_2046.Boundary? = nil
        ) {
            self.boundary = boundary ?? RFC_2046.Boundary()
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
            arrayEncodingStrategy: MultipartArrayEncodingStrategy,
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
            RFC_2045.ContentType(
                type: "multipart",
                subtype: "form-data",
                parameters: ["boundary": boundary.value]
            )
        }
    }
}

extension RFC_2046.Multipart.Conversion: Conversion {
    /// Converts multipart form data to a Swift value.
    ///
    /// - Parameter input: The form data to decode
    /// - Returns: The decoded Swift value
    /// - Throws: Decoding errors
    ///
    /// - Note: Parses multipart data using RFC 2046 parser and converts to Swift value via JSON.
    public func apply(_ input: Data) throws -> Value {
        print("DEBUG apply() called with \(input.count) bytes")
        
        // Convert Data to String
        guard let string = String(data: input, encoding: .utf8) else {
            print("DEBUG: Invalid UTF-8")
            throw MultipartConversionError.decodingFailed(
                reason: "Invalid UTF-8 in multipart data"
            )
        }
        
        print("DEBUG: String length = \(string.count)")
        
        // Parse multipart data using RFC 2046
        let multipart = try RFC_2046.Multipart.parse(
            string,
            boundary: boundary,
            subtype: RFC_2046.Multipart.Subtype.formData
        )
        
        print("DEBUG: Parsed \(multipart.parts.count) parts")
        
        // Extract form fields to dictionary
        let fields = multipart.extractFormFields()
        
        print("DEBUG: Extracted \(fields.count) fields: \(fields)")
        
        // Convert dictionary to JSON and then decode to Value type
        let jsonData = try JSONSerialization.data(withJSONObject: fields)
        let decoder = JSONDecoder()
        let result = try decoder.decode(Value.self, from: jsonData)
        print("DEBUG: Decoded successfully")
        return result
    }
    
    /// Converts a Swift value to multipart form data.
    ///
    /// This method encodes the Swift value to RFC 7578-compliant multipart/form-data
    /// format using the RFC 2046 Multipart implementation.
    ///
    /// - Parameter output: The Swift value to encode
    /// - Returns: The multipart form data as `Data`
    /// - Throws: Encoding errors
    public func unapply(_ output: Value) throws -> Foundation.Data {
        print("DEBUG unapply() called with output: \(output)")
        // Step 1: Extract field→value pairs using our custom encoder
        let fieldEncoder = RFC_2046.Multipart.FieldEncoder(multipartEncoder: encoder)
        try output.encode(to: fieldEncoder)
        print("DEBUG encoder.fields count: \(fieldEncoder.fields.count)")
        
        // Step 2: Validate we have at least one field or file
        guard !fieldEncoder.fields.isEmpty || !fieldEncoder.files.isEmpty else {
            throw MultipartConversionError.emptyRequest(
                reason: "Cannot encode \(Value.self) as multipart/form-data: all fields are nil or empty. At least one field must have a value."
            )
        }
        
        // Step 3: Convert text fields to RFC_2046.BodyPart
        let fieldParts: [RFC_2046.BodyPart] = fieldEncoder.fields.map { field in
            // Create BodyPart with typed Headers using RFC_2183 Content-Disposition
            // This handles escaping of special characters in field names per RFC 2183
            return RFC_2046.BodyPart(
                headers: .formDataTextField(name: field.name),
                text: field.value
            )
        }
        
        // Step 4: Convert file fields to RFC_2046.BodyPart
        let fileParts: [RFC_2046.BodyPart] = fieldEncoder.files.map { file in
            let base64Content = file.content.base64EncodedString()
            return RFC_2046.BodyPart(
                headers: RFC_2046.BodyPart.Headers(
                    contentDisposition: .formData(name: file.fieldName, filename: file.filename),
                    contentType: file.contentType ?? .applicationOctetStream,
                    contentTransferEncoding: .base64
                ),
                text: base64Content
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
        
        // Step 7: Render to RFC-compliant format with CRLF line endings
        let rendered = multipart.render()
        
        // Step 8: Convert to Data
        guard let data = rendered.data(using: .utf8) else {
            throw MultipartConversionError.encodingFailed
        }
        
        return data
    }
}

/// Errors that can occur during multipart conversion.
public enum MultipartConversionError: Error, LocalizedError {
    case encodingFailed
    case decodingFailed(reason: String)
    case emptyRequest(reason: String)
    
    public var errorDescription: String? {
        switch self {
        case .encodingFailed:
            return "Failed to encode value as multipart/form-data"
        case .decodingFailed(let reason):
            return "Failed to decode multipart/form-data: \(reason)"
        case .emptyRequest(let reason):
            return reason
        }
    }
}

// MARK: - Custom Encoder for Field Extraction

extension RFC_2046.Multipart {
    /// Internal encoder that extracts field names and values from Codable types.
    fileprivate class FieldEncoder: Swift.Encoder {
        var fields: [Field] = []
        var files: [RFC_7578.Form.Data.File] = []
        let multipartEncoder: RFC_2046.Multipart.Encoder
        var codingPath: [CodingKey] = []
        var userInfo: [CodingUserInfoKey: Any] = [:]
        
        init(multipartEncoder: RFC_2046.Multipart.Encoder) {
            self.multipartEncoder = multipartEncoder
        }
        
        func container<Key>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> where Key: CodingKey {
            let container = KeyedContainer<Key>(
                encoder: self,
                codingPath: codingPath
            )
            return KeyedEncodingContainer(container)
        }
        
        func unkeyedContainer() -> UnkeyedEncodingContainer {
            fatalError("Unkeyed containers at root level not supported for multipart encoding")
        }
        
        func singleValueContainer() -> SingleValueEncodingContainer {
            SingleValueContainer(encoder: self, codingPath: codingPath)
        }
    }
    
    fileprivate struct Field {
        let name: String
        let value: String
    }
    
    fileprivate struct KeyedContainer<Key: CodingKey>: KeyedEncodingContainerProtocol {
        let encoder: RFC_2046.Multipart.FieldEncoder
        var codingPath: [CodingKey]
        
        mutating func encodeNil(forKey key: Key) throws {
            // Skip nil values
        }
        
        mutating func encode(_ value: Bool, forKey key: Key) throws {
            let stringValue = encoder.multipartEncoder.encodeBoolean(value)
            encoder.fields.append(Field(name: key.stringValue, value: stringValue))
        }
        
        mutating func encode(_ value: String, forKey key: Key) throws {
            encoder.fields.append(Field(name: key.stringValue, value: value))
        }
        
        mutating func encode(_ value: Int, forKey key: Key) throws {
            encoder.fields.append(Field(name: key.stringValue, value: String(value)))
        }
        
        mutating func encode(_ value: Double, forKey key: Key) throws {
            encoder.fields.append(Field(name: key.stringValue, value: String(value)))
        }
        
        mutating func encode(_ value: Float, forKey key: Key) throws {
            encoder.fields.append(Field(name: key.stringValue, value: String(value)))
        }
        
        mutating func encode(_ value: Int8, forKey key: Key) throws {
            encoder.fields.append(Field(name: key.stringValue, value: String(value)))
        }
        
        mutating func encode(_ value: Int16, forKey key: Key) throws {
            encoder.fields.append(Field(name: key.stringValue, value: String(value)))
        }
        
        mutating func encode(_ value: Int32, forKey key: Key) throws {
            encoder.fields.append(Field(name: key.stringValue, value: String(value)))
        }
        
        mutating func encode(_ value: Int64, forKey key: Key) throws {
            encoder.fields.append(Field(name: key.stringValue, value: String(value)))
        }
        
        mutating func encode(_ value: UInt, forKey key: Key) throws {
            encoder.fields.append(Field(name: key.stringValue, value: String(value)))
        }
        
        mutating func encode(_ value: UInt8, forKey key: Key) throws {
            encoder.fields.append(Field(name: key.stringValue, value: String(value)))
        }
        
        mutating func encode(_ value: UInt16, forKey key: Key) throws {
            encoder.fields.append(Field(name: key.stringValue, value: String(value)))
        }
        
        mutating func encode(_ value: UInt32, forKey key: Key) throws {
            encoder.fields.append(Field(name: key.stringValue, value: String(value)))
        }
        
        mutating func encode(_ value: UInt64, forKey key: Key) throws {
            encoder.fields.append(Field(name: key.stringValue, value: String(value)))
        }
        
        mutating func encode<T>(_ value: T, forKey key: Key) throws where T: Encodable {
            // 1. Try file extraction first
            if let fileExtractor = encoder.multipartEncoder.fileExtractor,
               let file = fileExtractor(value) {
                try encoder.files.append(RFC_7578.Form.Data.File(
                    fieldName: key.stringValue,
                    filename: file.filename,
                    contentType: file.contentType,
                    content: file.data
                ))
                return
            }
            
            // 2. Handle Date
            if let date = value as? Date {
                let stringValue = encoder.multipartEncoder.encodeDate(date)
                encoder.fields.append(Field(name: key.stringValue, value: stringValue))
                return
            }
            
            // 3. Handle arrays
            if let array = value as? [Any] {
                try encodeArray(array, forKey: key)
                return
            }
            
            // 4. Try custom value encoding
            if let customEncoder = encoder.multipartEncoder.customValueEncoder,
               let stringValue = customEncoder(value, key.stringValue) {
                encoder.fields.append(Field(name: key.stringValue, value: stringValue))
                return
            }
            
            // 5. For other complex types, encode them as nested JSON
            // (This is a simplification - in practice you might want more sophisticated handling)
            let jsonEncoder = JSONEncoder()
            let jsonData = try jsonEncoder.encode(value)
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                encoder.fields.append(Field(name: key.stringValue, value: jsonString))
            }
        }
        
        private mutating func encodeArray(_ array: [Any], forKey key: Key) throws {
            // Check if this is an array of files
            if let fileExtractor = encoder.multipartEncoder.fileExtractor {
                var allFiles = true
                var files: [RFC_2046.Multipart.File] = []
                
                for element in array {
                    if let file = fileExtractor(element) {
                        files.append(file)
                    } else {
                        allFiles = false
                        break
                    }
                }
                
                if allFiles && !files.isEmpty {
                    for file in files {
                        try encoder.files.append(RFC_7578.Form.Data.File(
                            fieldName: key.stringValue,
                            filename: file.filename,
                            contentType: file.contentType,
                            content: file.data
                        ))
                    }
                    return
                }
            }
            
            // Otherwise, encode as regular array
            let fieldName: String
            switch encoder.multipartEncoder.arrayEncodingStrategy {
            case .accumulateValues:
                fieldName = key.stringValue
            case .brackets:
                fieldName = "\(key.stringValue)[]"
            }
            
            for element in array {
                let stringValue: String
                if let stringElement = element as? String {
                    stringValue = stringElement
                } else if let intElement = element as? Int {
                    stringValue = String(intElement)
                } else if let boolElement = element as? Bool {
                    stringValue = encoder.multipartEncoder.encodeBoolean(boolElement)
                } else if let dateElement = element as? Date {
                    stringValue = encoder.multipartEncoder.encodeDate(dateElement)
                } else {
                    // For complex types, use JSON encoding
                    let jsonEncoder = JSONEncoder()
                    if let encodable = element as? Encodable,
                       let jsonData = try? jsonEncoder.encode(encodable),
                       let jsonString = String(data: jsonData, encoding: .utf8) {
                        stringValue = jsonString
                    } else {
                        stringValue = String(describing: element)
                    }
                }
                
                encoder.fields.append(Field(name: fieldName, value: stringValue))
            }
        }
        
        mutating func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type, forKey key: Key) -> KeyedEncodingContainer<NestedKey> where NestedKey: CodingKey {
            fatalError("Nested containers not yet implemented for multipart encoding")
        }
        
        mutating func nestedUnkeyedContainer(forKey key: Key) -> UnkeyedEncodingContainer {
            fatalError("Nested unkeyed containers not yet implemented for multipart encoding")
        }
        
        mutating func superEncoder() -> Swift.Encoder {
            encoder
        }
        
        mutating func superEncoder(forKey key: Key) -> Swift.Encoder {
            encoder
        }
    }
    
    fileprivate struct SingleValueContainer: SingleValueEncodingContainer {
        let encoder: RFC_2046.Multipart.FieldEncoder
        var codingPath: [CodingKey]
        
        mutating func encodeNil() throws {
            // Skip
        }
        
        mutating func encode(_ value: Bool) throws {
            let stringValue = encoder.multipartEncoder.encodeBoolean(value)
            encoder.fields.append(Field(name: "", value: stringValue))
        }
        
        mutating func encode(_ value: String) throws {
            encoder.fields.append(Field(name: "", value: value))
        }
        
        mutating func encode(_ value: Double) throws {
            encoder.fields.append(Field(name: "", value: String(value)))
        }
        
        mutating func encode(_ value: Float) throws {
            encoder.fields.append(Field(name: "", value: String(value)))
        }
        
        mutating func encode(_ value: Int) throws {
            encoder.fields.append(Field(name: "", value: String(value)))
        }
        
        mutating func encode(_ value: Int8) throws {
            encoder.fields.append(Field(name: "", value: String(value)))
        }
        
        mutating func encode(_ value: Int16) throws {
            encoder.fields.append(Field(name: "", value: String(value)))
        }
        
        mutating func encode(_ value: Int32) throws {
            encoder.fields.append(Field(name: "", value: String(value)))
        }
        
        mutating func encode(_ value: Int64) throws {
            encoder.fields.append(Field(name: "", value: String(value)))
        }
        
        mutating func encode(_ value: UInt) throws {
            encoder.fields.append(Field(name: "", value: String(value)))
        }
        
        mutating func encode(_ value: UInt8) throws {
            encoder.fields.append(Field(name: "", value: String(value)))
        }
        
        mutating func encode(_ value: UInt16) throws {
            encoder.fields.append(Field(name: "", value: String(value)))
        }
        
        mutating func encode(_ value: UInt32) throws {
            encoder.fields.append(Field(name: "", value: String(value)))
        }
        
        mutating func encode(_ value: UInt64) throws {
            encoder.fields.append(Field(name: "", value: String(value)))
        }
        
        mutating func encode<T>(_ value: T) throws where T: Encodable {
            // Handle Date
            if let date = value as? Date {
                let stringValue = encoder.multipartEncoder.encodeDate(date)
                encoder.fields.append(Field(name: "", value: stringValue))
                return
            }
            
            // Try custom value encoding
            if let customEncoder = encoder.multipartEncoder.customValueEncoder,
               let stringValue = customEncoder(value, "") {
                encoder.fields.append(Field(name: "", value: stringValue))
                return
            }
            
            // Fall back to JSON encoding
            let jsonEncoder = JSONEncoder()
            let jsonData = try jsonEncoder.encode(value)
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                encoder.fields.append(Field(name: "", value: jsonString))
            }
        }
    }
}

// MARK: - FileUpload URLRouting Integration

extension FileUpload {
    /// Internal conversion wrapper for Body() parser
    fileprivate struct BodyConversion: Parsing.Conversion {
        let fileUpload: FileUpload
        
        func apply(_ input: Foundation.Data) throws -> Foundation.Data {
            try fileUpload.validate(input)
            return input
        }
        
        func unapply(_ data: Foundation.Data) throws -> Foundation.Data {
            // Step 1: Validate the file data
            try fileUpload.validate(data)
            
            // Step 2: Create RFC 7578 Form.Data.File
            let file = try RFC_7578.Form.Data.File(
                fieldName: fileUpload.fieldName,
                filename: fileUpload.filename,
                contentType: fileUpload.fileType.contentType,
                content: data
            )
            
            // Step 3: Build RFC 2046 multipart message using RFC 7578 formData
            let multipart = try RFC_2046.Multipart.formData(
                fields: [:],
                files: [file],
                boundary: fileUpload.boundary.value
            )
            
            // Step 4: Render to RFC-compliant format with CRLF line endings
            let rendered = multipart.render()
            
            // Step 5: Convert to Data
            guard let result = rendered.data(using: String.Encoding.utf8) else {
                throw Error.encodingError
            }
            
            return result
        }
    }
}

extension FileUpload: ParserPrinter {
    public typealias Input = RFC_3986.URI.Request.Data
    public typealias Output = Foundation.Data
    
    /// Parses the request, extracting and validating file upload data.
    ///
    /// This method:
    /// 1. Parses the Content-Type header to verify it matches the file upload's content type
    /// 2. Extracts the body data
    /// 3. Validates the file data (size limits, content type verification)
    ///
    /// - Parameter input: The URI request data
    /// - Returns: The validated file data
    /// - Throws: Validation or parsing errors
    public func parse(_ input: inout RFC_3986.URI.Request.Data) throws -> Foundation.Data {
        // Parse Content-Type header
        try Parse {
            Headers {
                RFC_7230.Header.Field("Content-Type") { self.contentType.headerValue }
            }
        }.parse(&input)
        
        // Parse and validate body
        let data = try Body(BodyConversion(fileUpload: self)).parse(&input)
        return data
    }
    
    /// Prints the file data back into request format.
    ///
    /// This method:
    /// 1. Sets the Content-Type header for the file upload
    /// 2. Encodes the file data as multipart/form-data in the body
    ///
    /// - Parameters:
    ///   - output: The file data to encode
    ///   - input: The URI request data to write into
    /// - Throws: Encoding errors
    public func print(_ output: Foundation.Data, into input: inout RFC_3986.URI.Request.Data) throws {
        // Print Content-Type header
        try Parse {
            Headers {
                RFC_7230.Header.Field("Content-Type") { self.contentType.headerValue }
            }
        }.print((), into: &input)
        
        // Print body
        try Body(BodyConversion(fileUpload: self)).print(output, into: &input)
    }
}

// MARK: - Conversion Convenience Methods

extension URLRouting.Conversion {
    /// Creates a multipart form data conversion for the specified Codable type.
    ///
    /// This static method provides a convenient way to create ``Multipart.Conversion``
    /// instances for use in URLRouting route definitions.
    ///
    /// - Parameters:
    ///   - type: The Codable type to convert to/from multipart form data
    ///   - arrayEncodingStrategy: How to encode array fields (default: accumulate values)
    /// - Returns: A ``Multipart.Conversion`` instance
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
    public static func multipart<Value>(
        _ type: Value.Type,
        arrayEncodingStrategy: MultipartArrayEncodingStrategy = .accumulateValues
    ) -> Self where Self == RFC_2046.Multipart.Conversion<Value> {
        .init(type, arrayEncodingStrategy: arrayEncodingStrategy)
    }
}

// MARK: - Multipart Parser

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
/// let conversion = Multipart.Conversion(UpdateRequest.self)
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
    let arrayEncodingStrategy: MultipartArrayEncodingStrategy
    
    /// Creates a multipart parser for the specified Codable type.
    ///
    /// - Parameters:
    ///   - type: The Codable type to parse/print
    ///   - arrayEncodingStrategy: How to encode array fields (default: accumulate values)
    public init(
        _ type: Value.Type,
        arrayEncodingStrategy: MultipartArrayEncodingStrategy = .accumulateValues
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
