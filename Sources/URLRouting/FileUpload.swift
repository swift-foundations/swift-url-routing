import Foundation
import RFC_2045
import RFC_2046

/// A conversion that handles file uploads in multipart/form-data format.
///
/// `FileUpload` provides secure file upload functionality with built-in
/// validation, size limits, and content type checking. It automatically generates
/// proper multipart boundaries and headers according to RFC 7578.
///
/// ## Overview
///
/// This conversion is designed specifically for handling file uploads with:
/// - **Content validation**: Verifies file content matches expected file type
/// - **Size limits**: Configurable maximum file size (default 10MB)
/// - **Security**: Magic number validation to prevent malicious file uploads
/// - **Type safety**: Strongly typed file type system with built-in common types
///
/// ## Basic Usage
///
/// ```swift
/// // Create file upload for images
/// let imageUpload = FileUpload(
///     fieldName: "avatar",
///     filename: "profile.jpg",
///     fileType: .image(.jpeg)
/// )
///
/// // Use in route definition
/// Route {
///     Method.post
///     Path { "upload" }
///     Body(imageUpload)
/// }
/// ```
///
/// ## Custom File Size Limits
///
/// ```swift
/// let restrictedUpload = FileUpload(
///     fieldName: "thumbnail",
///     filename: "thumb.png",
///     fileType: .image(.png),
///     maxSize: 1024 * 1024  // 1MB limit
/// )
/// ```
///
/// ## Security Features
///
/// - **Magic number validation**: Verifies file headers match declared type
/// - **Size enforcement**: Prevents oversized file uploads
/// - **Content type validation**: Ensures uploaded content matches expectations
/// - **Safe boundary generation**: Uses cryptographically safe boundary strings
///
/// - Important: Always validate file content server-side even with client-side restrictions.
/// - Note: The conversion validates file content during both `apply` and `unapply` operations.
public struct FileUpload: Sendable {

        /// The validated boundary used to separate multipart fields.
        public let boundary: RFC_2046.Boundary

        /// The name of the form field for this file upload.
        public let fieldName: String

        /// The filename to include in the multipart headers.
        public let filename: String

        /// The file type specification including validation rules.
        public let fileType: FileType

        /// The default maximum file size (10MB).
        public static let maxFileSize: Int = 10 * 1024 * 1024  // 10MB default

        /// The maximum allowed file size for this upload.
        public let maxSize: Int

        /// Creates a new multipart file upload conversion.
        ///
        /// - Parameters:
        ///   - fieldName: The form field name for this file upload
        ///   - filename: The filename to include in multipart headers
        ///   - fileType: The expected file type with validation rules
        ///   - maxSize: Maximum file size in bytes (defaults to 10MB)
        ///
        /// ## Example
        ///
        /// ```swift
        /// let pdfUpload = FileUpload(
        ///     fieldName: "document",
        ///     filename: "report.pdf",
        ///     fileType: .pdf,
        ///     maxSize: 5 * 1024 * 1024  // 5MB limit
        /// )
        /// ```
        public init(
            fieldName: String,
            filename: String,
            fileType: FileType,
            maxSize: Int = FileUpload.maxFileSize
        ) throws {
            guard !fieldName.isEmpty else {
                throw Error.emptyFieldName
            }

            guard !filename.isEmpty else {
                throw Error.emptyFilename
            }

            guard !filename.contains("/") && !filename.contains("\\") else {
                throw Error.invalidFilename(filename)
            }

            guard maxSize > 0 else {
                throw Error.invalidMaxSize(maxSize)
            }

            guard maxSize <= 1024 * 1024 * 1024 else {
                throw Error.maxSizeExceedsLimit(maxSize)
            }

            self.fieldName = fieldName
            self.filename = filename
            self.fileType = fileType
            self.maxSize = maxSize
            // Use RFC 2046's boundary generation for RFC compliance
            self.boundary = RFC_2046.Boundary()
        }

        public func validate(_ data: Foundation.Data) throws {
            guard !data.isEmpty else {
                throw Error.emptyData
            }

            guard data.count <= maxSize else {
                throw Error.fileTooLarge(size: data.count, maxSize: maxSize)
            }

            try fileType.validate(data)
        }
    }

extension FileUpload {
    /// The Content-Type header value for this multipart file upload.
    ///
    /// Returns a properly typed RFC 2045 Content-Type including the unique
    /// boundary parameter required for multipart form data parsing.
    ///
    /// - Returns: RFC_2045.ContentType for `multipart/form-data` with boundary
    ///
    /// ## Usage
    ///
    /// ```swift
    /// let upload = FileUpload(/* ... */)
    /// request.setValue(upload.contentType.headerValue, forHTTPHeaderField: "Content-Type")
    /// ```
    public var contentType: RFC_2045.ContentType {
        RFC_2045.ContentType(
            type: "multipart",
            subtype: "form-data",
            parameters: ["boundary": boundary.value]
        )
    }
}


extension FileUpload {
    /// Errors that can occur during multipart file upload processing.
    ///
    /// `Error` provides detailed error information for various failure
    /// scenarios that can occur during file upload validation and processing.
    /// All errors implement `LocalizedError` to provide user-friendly descriptions.
    ///
    /// ## Error Cases
    ///
    /// - ``fileTooLarge(size:maxSize:)`` - File exceeds size limits
    /// - ``invalidContentType(_:)`` - Unsupported or malformed content type
    /// - ``contentMismatch(expected:detected:)`` - File content doesn't match declared type
    /// - ``emptyData`` - No file data provided
    /// - ``malformedBoundary`` - Invalid multipart boundary format
    /// - ``encodingError`` - Failed to encode multipart data
    /// - ``emptyFieldName`` - Field name is empty
    /// - ``emptyFilename`` - Filename is empty
    /// - ``invalidFilename`` - Filename contains path separators
    /// - ``invalidMaxSize`` - Max size is zero or negative
    /// - ``maxSizeExceedsLimit`` - Max size exceeds 1GB limit
    ///
    /// ## Error Handling
    ///
    /// ```swift
    /// do {
    ///     let validatedData = try fileUpload.apply(uploadData)
    /// } catch let error as FileUpload.Error {
    ///     switch error {
    ///     case .fileTooLarge(let size, let maxSize):
    ///         print("File \(size) bytes exceeds limit of \(maxSize) bytes")
    ///     case .contentMismatch(let expected, let detected):
    ///         print("Expected \(expected), got \(detected ?? "unknown")")
    ///     case .emptyData:
    ///         print("No file data provided")
    ///     // Handle other cases...
    ///     }
    /// }
    /// ```
    public enum Error: Equatable, Sendable, LocalizedError {
        /// File size exceeds the configured maximum.
        ///
        /// - Parameters:
        ///   - size: The actual file size in bytes
        ///   - maxSize: The maximum allowed size in bytes
        case fileTooLarge(size: Int, maxSize: Int)

        /// The provided content type is invalid or unsupported.
        ///
        /// - Parameter contentType: The invalid content type string
        case invalidContentType(String)

        /// File content doesn't match the expected type.
        ///
        /// This error occurs when magic number validation fails, indicating
        /// the file content doesn't match the declared MIME type.
        ///
        /// - Parameters:
        ///   - expected: The expected content type
        ///   - detected: The detected content type (if determinable)
        case contentMismatch(expected: String, detected: String?)

        /// No file data was provided (empty upload).
        case emptyData

        /// The multipart boundary format is invalid.
        case malformedBoundary

        /// Failed to encode data in multipart format.
        case encodingError

        /// Field name is empty.
        case emptyFieldName

        /// Filename is empty.
        case emptyFilename

        /// Filename contains path separators (/ or \).
        case invalidFilename(String)

        /// Max size is zero or negative.
        case invalidMaxSize(Int)

        /// Max size exceeds maximum allowed (1GB).
        case maxSizeExceedsLimit(Int)
    }
}

extension FileUpload.Error {
    /// Provides localized error descriptions for user-facing error messages.
    ///
    /// Each error case returns a descriptive message that can be displayed
    /// to users or logged for debugging purposes.
    public var errorDescription: String? {
        switch self {
        case .fileTooLarge(let size, let maxSize):
            return "File size \(size) exceeds maximum allowed size of \(maxSize) bytes"
        case .invalidContentType(let type):
            return "Invalid content type: \(type)"
        case .contentMismatch(let expected, let detected):
            return
                "Content type mismatch. Expected: \(expected), Detected: \(detected ?? "unknown")"
        case .emptyData:
            return "Empty file data"
        case .malformedBoundary:
            return "Malformed multipart boundary"
        case .encodingError:
            return "Failed to encode multipart form data"
        case .emptyFieldName:
            return "Field name cannot be empty"
        case .emptyFilename:
            return "Filename cannot be empty"
        case .invalidFilename(let filename):
            return "Filename '\(filename)' contains invalid path separators"
        case .invalidMaxSize(let size):
            return "Max size \(size) must be positive"
        case .maxSizeExceedsLimit(let size):
            return "Max size \(size) bytes exceeds maximum limit of 1GB"
        }
    }
}
