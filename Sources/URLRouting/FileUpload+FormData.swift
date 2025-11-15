// ===----------------------------------------------------------------------===//
//
// Copyright (c) 2025 Coen ten Thije Boonkkamp
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of project contributors
//
// SPDX-License-Identifier: Apache-2.0
//
// ===----------------------------------------------------------------------===//

import Foundation
import WHATWG_HTML_Forms
import WHATWG_HTML_FormData

// MARK: - FileUpload → Form.Data Conversions

extension WHATWG_HTML_Forms.Form.Data.File {
    /// Creates a Form.Data.File from validated FileUpload data.
    ///
    /// This initializer validates the provided file data against the FileUpload
    /// specification (type, size limits) and creates a Form.Data.File instance.
    ///
    /// - Parameters:
    ///   - upload: The FileUpload specification defining validation rules
    ///   - data: The file data to validate
    ///
    /// - Throws: FileUpload.Error if validation fails
    ///
    /// ## Example
    ///
    /// ```swift
    /// let upload = try FileUpload(
    ///     fieldName: "document",
    ///     filename: "report.pdf",
    ///     fileType: .pdf,
    ///     maxSize: 5 * 1024 * 1024
    /// )
    ///
    /// let file = try Form.Data.File(upload: upload, data: pdfData)
    /// // File is validated and ready to use
    /// ```
    public init(upload: FileUpload, data: Data) throws {
        try upload.validate(data)

        self.init(
            name: upload.filename,
            type: upload.fileType.contentType.headerValue,
            body: data
        )
    }
}

extension WHATWG_HTML_Forms.Form.Data.Entry {
    /// Creates a Form.Data.Entry from validated FileUpload data.
    ///
    /// This initializer validates the provided file data against the FileUpload
    /// specification and creates a complete entry ready for inclusion in a
    /// Form.Data.Entry.List.
    ///
    /// - Parameters:
    ///   - upload: The FileUpload specification defining field name and validation rules
    ///   - data: The file data to validate
    ///
    /// - Throws: FileUpload.Error if validation fails
    ///
    /// ## Example
    ///
    /// ```swift
    /// let upload = try FileUpload(
    ///     fieldName: "avatar",
    ///     filename: "photo.jpg",
    ///     fileType: .image(.jpeg)
    /// )
    ///
    /// var formData = Form.Data.Entry.List()
    /// formData.append(try Form.Data.Entry(upload: upload, data: imageData))
    /// ```
    public init(upload: FileUpload, data: Data) throws {
        self.init(
            name: upload.fieldName,
            value: .file(try Form.Data.File(upload: upload, data: data))
        )
    }
}

// MARK: - FileType Conversion

extension FileUpload.FileType {
    /// The MIME type string for this file type.
    ///
    /// Returns the Content-Type header value suitable for use in
    /// Form.Data.File or HTTP headers.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let pdfType = FileUpload.FileType.pdf
    /// print(pdfType.mimeType)  // "application/pdf"
    /// ```
    public var mimeType: String {
        contentType.headerValue
    }
}
