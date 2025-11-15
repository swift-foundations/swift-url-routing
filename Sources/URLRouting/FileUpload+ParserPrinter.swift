//
//  FileUpload+ParserPrinter.swift
//  swift-url-routing
//
//  Created by Coen ten Thije Boonkkamp on 15/11/2025.
//

import Foundation
import Parsing
import RFC_2046
import RFC_3986
import RFC_7230
import RFC_7578

// MARK: - FileUpload URLRouting Integration

extension FileUpload {
    /// Internal conversion wrapper for Body() parser
    internal struct BodyConversion: Parsing.Conversion {
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
