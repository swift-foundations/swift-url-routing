//
//  Multipart.SingleValueContainer.swift
//  swift-url-routing
//
//  Created by Coen ten Thije Boonkkamp on 15/11/2025.
//

import Foundation
import RFC_2046

extension RFC_2046.Multipart {
    internal struct SingleValueContainer: SingleValueEncodingContainer {
        let encoder: RFC_2046.Multipart.Field.Encoder
        var codingPath: [CodingKey]

        mutating func encodeNil() throws {
            // Skip
        }

        mutating func encode(_ value: Bool) throws {
            let stringValue = encoder.multipartEncoder.encodeBoolean(value)
            encoder.fields.append(RFC_2046.Multipart.Field(name: "", value: stringValue))
        }

        mutating func encode(_ value: String) throws {
            encoder.fields.append(RFC_2046.Multipart.Field(name: "", value: value))
        }

        mutating func encode(_ value: Double) throws {
            encoder.fields.append(RFC_2046.Multipart.Field(name: "", value: String(value)))
        }

        mutating func encode(_ value: Float) throws {
            encoder.fields.append(RFC_2046.Multipart.Field(name: "", value: String(value)))
        }

        mutating func encode(_ value: Int) throws {
            encoder.fields.append(RFC_2046.Multipart.Field(name: "", value: String(value)))
        }

        mutating func encode(_ value: Int8) throws {
            encoder.fields.append(RFC_2046.Multipart.Field(name: "", value: String(value)))
        }

        mutating func encode(_ value: Int16) throws {
            encoder.fields.append(RFC_2046.Multipart.Field(name: "", value: String(value)))
        }

        mutating func encode(_ value: Int32) throws {
            encoder.fields.append(RFC_2046.Multipart.Field(name: "", value: String(value)))
        }

        mutating func encode(_ value: Int64) throws {
            encoder.fields.append(RFC_2046.Multipart.Field(name: "", value: String(value)))
        }

        mutating func encode(_ value: UInt) throws {
            encoder.fields.append(RFC_2046.Multipart.Field(name: "", value: String(value)))
        }

        mutating func encode(_ value: UInt8) throws {
            encoder.fields.append(RFC_2046.Multipart.Field(name: "", value: String(value)))
        }

        mutating func encode(_ value: UInt16) throws {
            encoder.fields.append(RFC_2046.Multipart.Field(name: "", value: String(value)))
        }

        mutating func encode(_ value: UInt32) throws {
            encoder.fields.append(RFC_2046.Multipart.Field(name: "", value: String(value)))
        }

        mutating func encode(_ value: UInt64) throws {
            encoder.fields.append(RFC_2046.Multipart.Field(name: "", value: String(value)))
        }

        mutating func encode<T>(_ value: T) throws where T: Encodable {
            // Handle Date
            if let date = value as? Date {
                let stringValue = encoder.multipartEncoder.encodeDate(date)
                encoder.fields.append(RFC_2046.Multipart.Field(name: "", value: stringValue))
                return
            }

            // Try custom value encoding
            if let customEncoder = encoder.multipartEncoder.customValueEncoder,
               let stringValue = customEncoder(value, "") {
                encoder.fields.append(RFC_2046.Multipart.Field(name: "", value: stringValue))
                return
            }

            // Fall back to JSON encoding
            let jsonEncoder = JSONEncoder()
            let jsonData = try jsonEncoder.encode(value)
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                encoder.fields.append(RFC_2046.Multipart.Field(name: "", value: jsonString))
            }
        }
    }
}
