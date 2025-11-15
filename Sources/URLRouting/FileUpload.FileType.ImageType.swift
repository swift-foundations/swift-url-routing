import Foundation
import RFC_2045

extension FileUpload.FileType {
    /// Represents image file types with magic number validation.
    ///
    /// `ImageType` provides specialized validation for common image formats
    /// using magic number (file signature) detection to prevent malicious
    /// file uploads disguised as images.
    ///
    /// ## Supported Image Types
    ///
    /// - `.jpeg` - JPEG images (validates FF D8 FF magic numbers)
    /// - `.png` - PNG images (validates PNG signature)
    /// - `.gif` - GIF images (validates GIF87a/GIF89a signatures)
    /// - `.webp` - WebP images (validates RIFF/WEBP signature)
    ///
    /// ## Example
    ///
    /// ```swift
    /// let imageUpload = FileUpload(
    ///     fieldName: "photo",
    ///     filename: "profile.jpg",
    ///     fileType: .image(.jpeg)  // Validates JPEG magic numbers
    /// )
    /// ```
    ///
    /// ## Security
    ///
    /// Each image type validates the file's magic numbers (binary signature)
    /// to ensure the file content matches the declared format, preventing
    /// security vulnerabilities from disguised malicious files.
    public struct ImageType: Sendable {
        /// The RFC 2045 Content-Type for this image format.
        public let contentType: RFC_2045.ContentType

        /// The file extension (without dot) for this image format.
        public let fileExtension: String

        /// Validation function that checks magic numbers for this image type.
        let validate: @Sendable (Foundation.Data) throws -> Void

        /// Creates a new image type specification.
        ///
        /// - Parameters:
        ///   - contentType: The RFC 2045 Content-Type
        ///   - fileExtension: The file extension without dot (e.g., "jpg")
        ///   - validate: Validation function that checks image magic numbers
        public init(
            contentType: RFC_2045.ContentType,
            fileExtension: String,
            validate: @escaping @Sendable (Foundation.Data) throws -> Void = { _ in }
        ) {
            self.contentType = contentType
            self.fileExtension = fileExtension
            self.validate = validate
        }
    }
}

// MARK: - Predefined Image Types

extension FileUpload.FileType.ImageType {
    /// JPEG image type with magic number validation.
    ///
    /// Validates the JPEG file signature (FF D8 FF) to ensure the uploaded
    /// file is a genuine JPEG image. This prevents malicious files from
    /// being disguised as JPEG images.
    ///
    /// - Content Type: `image/jpeg`
    /// - File Extension: `jpg`
    /// - Magic Numbers: `FF D8 FF` (first 3 bytes)
    ///
    /// ## Security
    ///
    /// The validation checks the first 3 bytes of the file for the JPEG
    /// Start of Image (SOI) marker followed by the Application marker.
    public static let jpeg = Self(
            contentType: RFC_2045.ContentType(type: "image", subtype: "jpeg"),
            fileExtension: "jpg"
        ) { (data: Foundation.Data) in
            let jpegMagicNumbers: [UInt8] = [0xFF, 0xD8, 0xFF]
            guard data.prefix(3).elementsEqual(jpegMagicNumbers) else {
                throw FileUpload.Error.contentMismatch(
                    expected: "image/jpeg",
                    detected: nil
                )
            }
        }

    /// PNG image type with magic number validation.
    ///
    /// Validates the PNG file signature to ensure the uploaded file is a
    /// genuine PNG image. The PNG signature is more complex than JPEG,
    /// providing stronger validation against malicious files.
    ///
    /// - Content Type: `image/png`
    /// - File Extension: `png`
    /// - Magic Numbers: `89 50 4E 47 0D 0A 1A 0A` (PNG signature)
    ///
    /// ## Security
    ///
    /// PNG files begin with an 8-byte signature that includes:
    /// - High-bit ASCII bytes to detect transmission problems
    /// - PNG identifier ("PNG")
    /// - DOS-style line ending (CRLF)
    /// - DOS end-of-file character and Unix line ending
    public static let png = Self(
            contentType: RFC_2045.ContentType(type: "image", subtype: "png"),
            fileExtension: "png"
        ) { (data: Foundation.Data) in
            let pngMagicNumbers: [UInt8] = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]
            guard data.prefix(8).elementsEqual(pngMagicNumbers) else {
                throw FileUpload.Error.contentMismatch(
                    expected: "image/png",
                    detected: nil
                )
            }
        }

    /// GIF image type with version validation.
    ///
    /// Validates GIF file signatures for both GIF87a and GIF89a formats.
    /// Supports both the original 1987 and enhanced 1989 GIF specifications.
    ///
    /// - Content Type: `image/gif`
    /// - File Extension: `gif`
    /// - Magic Numbers: `GIF87a` or `GIF89a` (ASCII header)
    ///
    /// ## Supported Versions
    ///
    /// - **GIF87a**: Original 1987 specification
    /// - **GIF89a**: Enhanced 1989 specification with animation support
    public static let gif = Self(
            contentType: RFC_2045.ContentType(type: "image", subtype: "gif"),
            fileExtension: "gif"
        ) { (data: Foundation.Data) in
            let gif87a = Data("GIF87a".utf8)
            let gif89a = Data("GIF89a".utf8)
            guard data.prefix(6).elementsEqual(gif87a) || data.prefix(6).elementsEqual(gif89a)
            else {
                throw FileUpload.Error.contentMismatch(
                    expected: "image/gif",
                    detected: nil
                )
            }
        }

    /// WebP image type with RIFF container validation.
    ///
    /// Validates WebP images by checking both the RIFF container header
    /// and the WebP format identifier. WebP uses a RIFF container format
    /// similar to WAV audio files.
    ///
    /// - Content Type: `image/webp`
    /// - File Extension: `webp`
    /// - Magic Numbers: `RIFF` header + `WEBP` identifier
    ///
    /// ## Structure
    ///
    /// WebP files have this structure:
    /// - Bytes 0-3: "RIFF" (container identifier)
    /// - Bytes 4-7: File size (little-endian)
    /// - Bytes 8-11: "WEBP" (format identifier)
    public static let webp = Self(
            contentType: RFC_2045.ContentType(type: "image", subtype: "webp"),
            fileExtension: "webp"
        ) { (data: Foundation.Data) in
            let riffMagic = Data("RIFF".utf8)
            let webpMagic = Data("WEBP".utf8)
            guard
                data.prefix(4).elementsEqual(riffMagic)
                    && data.dropFirst(8).prefix(4).elementsEqual(webpMagic)
            else {
                throw FileUpload.Error.contentMismatch(
                    expected: "image/webp",
                    detected: nil
                )
            }
        }

    /// TIFF image type with endianness validation.
    ///
    /// Validates TIFF (Tagged Image File Format) files by checking for
    /// either Intel (little-endian) or Motorola (big-endian) byte order markers.
    ///
    /// - Content Type: `image/tiff`
    /// - File Extension: `tiff`
    /// - Magic Numbers: `II*\0` (Intel) or `MM\0*` (Motorola)
    ///
    /// ## Byte Order Support
    ///
    /// TIFF files can use either byte ordering:
    /// - **Intel**: `49 49 2A 00` (little-endian)
    /// - **Motorola**: `4D 4D 00 2A` (big-endian)
    public static let tiff = Self(
            contentType: RFC_2045.ContentType(type: "image", subtype: "tiff"),
            fileExtension: "tiff"
        ) { (data: Foundation.Data) in
            let intelMagic: [UInt8] = [0x49, 0x49, 0x2A, 0x00]  // II*\0
            let motorolaMagic: [UInt8] = [0x4D, 0x4D, 0x00, 0x2A]  // MM\0*
            guard
                data.prefix(4).elementsEqual(intelMagic)
                    || data.prefix(4).elementsEqual(motorolaMagic)
            else {
                throw FileUpload.Error.contentMismatch(
                    expected: "image/tiff",
                    detected: nil
                )
            }
        }

    /// BMP image type with bitmap signature validation.
    ///
    /// Validates Windows Bitmap files by checking for the "BM" signature.
    /// BMP is the native bitmap format for Windows systems.
    ///
    /// - Content Type: `image/bmp`
    /// - File Extension: `bmp`
    /// - Magic Numbers: `42 4D` ("BM" in ASCII)
    ///
    /// ## Format
    ///
    /// BMP files begin with a simple 2-byte signature:
    /// - "BM" indicates a Windows bitmap file
    /// - Other variants like "BA", "CI", "CP", "IC", "PT" exist but are rare
    public static let bmp = Self(
            contentType: RFC_2045.ContentType(type: "image", subtype: "bmp"),
            fileExtension: "bmp"
        ) { (data: Foundation.Data) in
            let bmpMagic: [UInt8] = [0x42, 0x4D]  // "BM"
            guard data.prefix(2).elementsEqual(bmpMagic) else {
                throw FileUpload.Error.contentMismatch(
                    expected: "image/bmp",
                    detected: nil
                )
            }
        }

    /// HEIC image type with container format validation.
    ///
    /// Validates High Efficiency Image Container files used by Apple devices.
    /// HEIC uses a container format based on ISOBMFF (ISO Base Media File Format).
    ///
    /// - Content Type: `image/heic`
    /// - File Extension: `heic`
    /// - Validation: Checks for `ftyp` box with `heic` brand identifier
    ///
    /// ## Container Structure
    ///
    /// HEIC files use a box-based container format:
    /// - Bytes 4-7: "ftyp" (file type box identifier)
    /// - Bytes 8-11: "heic" (brand identifier)
    ///
    /// - Note: This validation is basic due to HEIC's complex container format.
    ///   More sophisticated validation could check additional brand compatibility.
    public static let heic = Self(
            contentType: RFC_2045.ContentType(type: "image", subtype: "heic"),
            fileExtension: "heic"
        ) { (data: Foundation.Data) in
            // HEIC validation is complex due to its container format
            // This is a basic check for the ftyp box with heic brand
            guard data.count >= 12,
                let ftyp = String(data: data.subdata(in: 4..<8), encoding: .ascii),
                ftyp == "ftyp",
                let brand = String(data: data.subdata(in: 8..<12), encoding: .ascii),
                brand == "heic"
            else {
                throw FileUpload.Error.contentMismatch(
                    expected: "image/heic",
                    detected: nil
                )
            }
        }

    /// AVIF image type with container format validation.
    ///
    /// Validates AV1 Image File Format files, a modern image format based on
    /// the AV1 video codec. AVIF provides excellent compression and quality.
    ///
    /// - Content Type: `image/avif`
    /// - File Extension: `avif`
    /// - Validation: Checks for `ftyp` box with `avif` brand identifier
    ///
    /// ## Modern Format
    ///
    /// AVIF is designed to replace JPEG with:
    /// - Better compression efficiency
    /// - Wide color gamut support
    /// - HDR capability
    /// - Lossless and lossy compression modes
    ///
    /// Like HEIC, it uses an ISOBMFF container format.
    public static let avif = Self(
            contentType: RFC_2045.ContentType(type: "image", subtype: "avif"),
            fileExtension: "avif"
        ) { (data: Foundation.Data) in
            // Similar to HEIC, AVIF uses a container format
            guard data.count >= 12,
                let ftyp = String(data: data.subdata(in: 4..<8), encoding: .ascii),
                ftyp == "ftyp",
                let brand = String(data: data.subdata(in: 8..<12), encoding: .ascii),
                brand == "avif"
            else {
                throw FileUpload.Error.contentMismatch(
                    expected: "image/avif",
                    detected: nil
                )
            }
        }
}
