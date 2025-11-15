//
//  Multipart.File.swift
//  swift-url-routing
//
//  Created by Coen ten Thije Boonkkamp on 15/11/2025.
//

import Foundation
import RFC_2045
import RFC_2046

extension RFC_2046.Multipart {
    /// File data for multipart encoding
    ///
    /// Represents a file to be encoded in multipart/form-data format.
    /// The field name is determined by the CodingKey, not stored in this struct.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let file = RFC_2046.Multipart.File(
    ///     filename: "document.pdf",
    ///     contentType: .applicationPDF,
    ///     data: pdfData
    /// )
    /// ```
    ///
    /// ## Usage with File Extractor
    ///
    /// ```swift
    /// encoder.fileExtractor = { value in
    ///     if let attachment = value as? Attachment {
    ///         return RFC_2046.Multipart.File(
    ///             filename: attachment.filename,
    ///             contentType: attachment.contentType,
    ///             data: attachment.data
    ///         )
    ///     }
    ///     return nil
    /// }
    /// ```
    public struct File: Hashable, Sendable {
        /// The filename to include in Content-Disposition header
        public let filename: String

        /// The MIME content type of the file
        public let contentType: RFC_2045.ContentType?

        /// The file content (binary data)
        public let data: Data

        /// Creates file data for multipart encoding
        ///
        /// - Parameters:
        ///   - filename: Filename for Content-Disposition header
        ///   - contentType: MIME type (optional, defaults to application/octet-stream if nil)
        ///   - data: File content
        public init(
            filename: String,
            contentType: RFC_2045.ContentType? = nil,
            data: Data
        ) {
            self.filename = filename
            self.contentType = contentType
            self.data = data
        }
    }
}
