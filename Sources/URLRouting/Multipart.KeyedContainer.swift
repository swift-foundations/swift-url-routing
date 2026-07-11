//
//  Multipart.KeyedContainer.swift
//  swift-url-routing
//
//  Created by Coen ten Thije Boonkkamp on 15/11/2025.
//

import Foundation
import RFC_2046
import RFC_7578

extension RFC_2046.Multipart {
    internal struct KeyedContainer<Key: CodingKey>: KeyedEncodingContainerProtocol {
        let encoder: RFC_2046.Multipart.Field.Encoder
        var codingPath: [CodingKey]

        mutating func encodeNil(forKey key: Key) throws {
            // Skip nil values
        }

        mutating func encode(_ value: Bool, forKey key: Key) throws {
            let stringValue = encoder.multipartEncoder.encodeBoolean(value)
            encoder.fields.append(RFC_2046.Multipart.Field(name: key.stringValue, value: stringValue))
        }

        mutating func encode(_ value: String, forKey key: Key) throws {
            encoder.fields.append(RFC_2046.Multipart.Field(name: key.stringValue, value: value))
        }

        mutating func encode(_ value: Int, forKey key: Key) throws {
            encoder.fields.append(RFC_2046.Multipart.Field(name: key.stringValue, value: String(value)))
        }

        mutating func encode(_ value: Double, forKey key: Key) throws {
            encoder.fields.append(RFC_2046.Multipart.Field(name: key.stringValue, value: String(value)))
        }

        mutating func encode(_ value: Float, forKey key: Key) throws {
            encoder.fields.append(RFC_2046.Multipart.Field(name: key.stringValue, value: String(value)))
        }

        mutating func encode(_ value: Int8, forKey key: Key) throws {
            encoder.fields.append(RFC_2046.Multipart.Field(name: key.stringValue, value: String(value)))
        }

        mutating func encode(_ value: Int16, forKey key: Key) throws {
            encoder.fields.append(RFC_2046.Multipart.Field(name: key.stringValue, value: String(value)))
        }

        mutating func encode(_ value: Int32, forKey key: Key) throws {
            encoder.fields.append(RFC_2046.Multipart.Field(name: key.stringValue, value: String(value)))
        }

        mutating func encode(_ value: Int64, forKey key: Key) throws {
            encoder.fields.append(RFC_2046.Multipart.Field(name: key.stringValue, value: String(value)))
        }

        mutating func encode(_ value: UInt, forKey key: Key) throws {
            encoder.fields.append(RFC_2046.Multipart.Field(name: key.stringValue, value: String(value)))
        }

        mutating func encode(_ value: UInt8, forKey key: Key) throws {
            encoder.fields.append(RFC_2046.Multipart.Field(name: key.stringValue, value: String(value)))
        }

        mutating func encode(_ value: UInt16, forKey key: Key) throws {
            encoder.fields.append(RFC_2046.Multipart.Field(name: key.stringValue, value: String(value)))
        }

        mutating func encode(_ value: UInt32, forKey key: Key) throws {
            encoder.fields.append(RFC_2046.Multipart.Field(name: key.stringValue, value: String(value)))
        }

        mutating func encode(_ value: UInt64, forKey key: Key) throws {
            encoder.fields.append(RFC_2046.Multipart.Field(name: key.stringValue, value: String(value)))
        }

        mutating func encode<T>(_ value: T, forKey key: Key) throws where T: Encodable {
            // 1. Try file extraction first
            if let fileExtractor = encoder.multipartEncoder.fileExtractor,
               let file = fileExtractor(value) {
                try encoder.files.append(RFC_7578.Form.Data.File(
                    fieldName: key.stringValue,
                    filename: try RFC_2183.Filename(file.filename),
                    contentType: file.contentType,
                    content: [UInt8](file.data)
                ))
                return
            }

            // 2. Handle Date
            if let date = value as? Date {
                let stringValue = encoder.multipartEncoder.encodeDate(date)
                encoder.fields.append(RFC_2046.Multipart.Field(name: key.stringValue, value: stringValue))
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
                encoder.fields.append(RFC_2046.Multipart.Field(name: key.stringValue, value: stringValue))
                return
            }

            // 5. For other complex types, encode them as nested JSON
            // (This is a simplification - in practice you might want more sophisticated handling)
            let jsonEncoder = JSONEncoder()
            let jsonData = try jsonEncoder.encode(value)
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                encoder.fields.append(RFC_2046.Multipart.Field(name: key.stringValue, value: jsonString))
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
                            filename: try RFC_2183.Filename(file.filename),
                            contentType: file.contentType,
                            content: [UInt8](file.data)
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

                encoder.fields.append(RFC_2046.Multipart.Field(name: fieldName, value: stringValue))
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
}
