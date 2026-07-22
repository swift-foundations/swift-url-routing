//
//  FileUpload+ParserPrinter.swift
//  swift-url-routing
//
//  Created by Coen ten Thije Boonkkamp on 15/11/2025.
//

import Foundation
import RFC_2046
import RFC_2183
import RFC_3986
import RFC_7230
import RFC_7578

// MARK: - FileUpload URLRouting Integration

extension FileUpload {
    /// Internal conversion wrapper for RFC_7230.Body.Parser() parser
    internal struct BodyConversion: Parser.Conversion.`Protocol` {
        typealias Input = Foundation.Data
        typealias Output = Foundation.Data
        typealias Failure = RFC_3986.URI.Routing.Error

        let fileUpload: FileUpload

        func apply(_ input: Foundation.Data) throws(RFC_3986.URI.Routing.Error) -> Foundation.Data {
            do {
                try fileUpload.validate(input)
                return input
            } catch {
                throw RFC_3986.URI.Routing.Error(component: .body, failure: .parseFailed("\(error)"))
            }
        }

        func unapply(_ data: Foundation.Data) throws(RFC_3986.URI.Routing.Error) -> Foundation.Data {
          do {
            // Step 1: Validate the file data
            try fileUpload.validate(data)

            // Step 2: Create RFC 7578 Form.Data.File
            let file = try RFC_7578.Form.Data.File(
                fieldName: fileUpload.fieldName,
                filename: try RFC_2183.Filename(fileUpload.filename),
                contentType: fileUpload.fileType.contentType,
                content: [UInt8](data)
            )

            // Step 3: Build RFC 2046 multipart message using RFC 7578 formData
            let multipart = try RFC_2046.Multipart.formData(
                fields: [:],
                files: [file],
                boundary: fileUpload.boundary.rawValue
            )

            // Step 4: Serialize to RFC-compliant bytes (CRLF line endings) and return as Data.
            var buffer: [Byte] = []
            RFC_2046.Multipart.serialize(multipart, into: &buffer)
            return Data(buffer.map { $0.underlying } as [UInt8])
          } catch {
            throw RFC_3986.URI.Routing.Error(component: .body, failure: .parseFailed("\(error)"))
          }
        }
    }
}

extension FileUpload: Parser.Bidirectional {
    public typealias Input = RFC_3986.URI.Request.Data
    public typealias Output = Foundation.Data
    public typealias Failure = RFC_3986.URI.Routing.Error

    /// Parses the request, extracting and validating file upload data.
    ///
    /// This method:
    /// 1. Extracts the body data via `RFC_7230.Body.Parser`
    /// 2. Validates the file data through the body conversion (size limits,
    ///    content sniffing / file-content verification)
    ///
    /// The Content-Type header is NOT re-validated on parse — the body conversion
    /// self-validates the file content, so the header check is deliberately narrowed
    /// out of the parse path. ``print(_:into:)`` still emits the header.
    ///
    /// - Parameter input: The URI request data
    /// - Returns: The validated file data
    /// - Throws: Validation or parsing errors
    public func parse(_ input: inout RFC_3986.URI.Request.Data) throws(RFC_3986.URI.Routing.Error) -> Foundation.Data {
        // The body conversion validates the file itself; parse it directly.
        return try RFC_7230.Body.Parser(BodyConversion(fileUpload: self)).parse(&input)
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

    public func serialize(_ output: Foundation.Data, into input: inout RFC_3986.URI.Request.Data) throws(RFC_3986.URI.Routing.Error) {
        // Emit the multipart/form-data Content-Type header (carrying the boundary).
        input.headers["Content-Type"] = [Optional(Substring(self.contentType.headerValue))][...]
        // Print body
        try RFC_7230.Body.Parser(BodyConversion(fileUpload: self)).print(output, into: &input)
    }
}
