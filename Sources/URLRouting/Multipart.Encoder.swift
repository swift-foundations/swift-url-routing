//
//  Multipart.Encoder.swift
//  swift-url-routing
//
//  Created by Coen ten Thije Boonkkamp on 15/11/2025.
//

import Foundation
import RFC_2045
import RFC_2046

// MARK: - Bool Encoding

extension Bool {
    /// Encoder for boolean values in multipart fields
    public struct Encoder: Sendable {
        public let encode: @Sendable (Bool) -> String

        public init(encode: @escaping @Sendable (Bool) -> String) {
            self.encode = encode
        }

        /// Encode as "true" or "false" (default)
        public static let trueFalse = Encoder { $0 ? "true" : "false" }

        /// Encode as "yes" or "no" (Mailgun, legacy APIs)
        public static let yesNo = Encoder { $0 ? "yes" : "no" }

        /// Encode as "1" or "0" (numeric)
        public static let numeric = Encoder { $0 ? "1" : "0" }
    }
}

// MARK: - Date Encoding

extension Date {
    /// Encoder for date values in multipart fields
    public struct Encoder: Sendable {
        public let encode: @Sendable (Date) -> String

        public init(encode: @escaping @Sendable (Date) -> String) {
            self.encode = encode
        }

        /// ISO8601 format (default)
        public static let iso8601 = Encoder { date in
            let formatter = ISO8601DateFormatter()
            return formatter.string(from: date)
        }

        /// Seconds since January 1, 1970
        public static let secondsSince1970 = Encoder { date in
            String(Int(date.timeIntervalSince1970))
        }

        /// Milliseconds since January 1, 1970
        public static let millisecondsSince1970 = Encoder { date in
            String(Int(date.timeIntervalSince1970 * 1000))
        }
    }
}

// MARK: - RFC_2046.Multipart.Encoder

extension RFC_2046.Multipart {
    /// Encoder for converting Codable types to multipart/form-data
    ///
    /// `RFC_2046.Multipart.Encoder` provides configurable encoding strategies for converting
    /// Swift Codable types to multipart/form-data format, with special handling for
    /// files, arrays, booleans, and custom types.
    ///
    /// ## Basic Usage
    ///
    /// ```swift
    /// let encoder = RFC_2046.Multipart.Encoder()
    /// encoder.boolEncoder = .yesNo
    /// encoder.arrayEncodingStrategy = .accumulateValues
    ///
    /// let conversion = RFC_2046.Multipart.Conversion(Request.self, encoder: encoder)
    /// ```
    ///
    /// ## File Handling
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
    ///
    /// ## Custom Value Encoding
    ///
    /// ```swift
    /// encoder.customValueEncoder = { value, key in
    ///     if let email = value as? EmailAddress {
    ///         return email.rawValue
    ///     }
    ///     return nil
    /// }
    /// ```
    public class Encoder: @unchecked Sendable {
        /// Encoder for boolean values
        public var boolEncoder: Bool.Encoder = .trueFalse

        /// Encoder for date values
        public var dateEncoder: Date.Encoder = .iso8601

        /// Strategy for encoding arrays
        public var arrayEncodingStrategy: RFC_2046.Multipart.Array.EncodingStrategy = .accumulateValues

        /// Closure to extract file data from values
        ///
        /// Return `RFC_2046.Multipart.File` if the value represents a file, `nil` otherwise.
        ///
        /// The field name comes from the CodingKey, not from the file data.
        ///
        /// ## Example
        ///
        /// ```swift
        /// encoder.fileExtractor = { value in
        ///     if let attachment = value as? MyAttachment {
        ///         return RFC_2046.Multipart.File(
        ///             filename: attachment.name,
        ///             contentType: .applicationPDF,
        ///             data: attachment.data
        ///         )
        ///     }
        ///     return nil
        /// }
        /// ```
        public var fileExtractor: ((Any) -> RFC_2046.Multipart.File?)? = nil

        /// Custom encoder for special types
        ///
        /// Return a string representation if the value should be custom-encoded,
        /// `nil` to fall back to default encoding.
        ///
        /// Called before standard encoding, allowing you to override default
        /// behavior for specific types (e.g., EmailAddress, custom enums).
        ///
        /// ## Example
        ///
        /// ```swift
        /// encoder.customValueEncoder = { value, key in
        ///     if let email = value as? EmailAddress {
        ///         return email.rawValue
        ///     }
        ///     if let option = value as? TrackingOption {
        ///         return option.stringValue
        ///     }
        ///     return nil
        /// }
        /// ```
        public var customValueEncoder: ((Any, String) -> String?)? = nil

        /// Creates a new multipart encoder with default strategies
        public init() {}

        // Internal helper to encode boolean values
        func encodeBoolean(_ value: Bool) -> String {
            boolEncoder.encode(value)
        }

        // Internal helper to encode date values
        func encodeDate(_ value: Date) -> String {
            dateEncoder.encode(value)
        }
    }
}
