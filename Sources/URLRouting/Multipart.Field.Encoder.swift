//
//  Multipart.Field.Encoder.swift
//  swift-url-routing
//
//  Created by Coen ten Thije Boonkkamp on 15/11/2025.
//

import Foundation
import RFC_2046
import RFC_7578

// MARK: - RFC_2046.Multipart.Field

extension RFC_2046.Multipart {
    /// Field name-value pair for multipart encoding
    internal struct Field {
        let name: String
        let value: String
    }
}

// MARK: - RFC_2046.Multipart.Field.Encoder

extension RFC_2046.Multipart.Field {
    /// Internal encoder that extracts field names and values from Codable types.
    internal class Encoder: Swift.Encoder {
        var fields: [RFC_2046.Multipart.Field] = []
        var files: [RFC_7578.Form.Data.File] = []
        let multipartEncoder: RFC_2046.Multipart.Encoder
        var codingPath: [CodingKey] = []
        var userInfo: [CodingUserInfoKey: Any] = [:]

        init(multipartEncoder: RFC_2046.Multipart.Encoder) {
            self.multipartEncoder = multipartEncoder
        }

        func container<Key>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> where Key: CodingKey {
            let container = RFC_2046.Multipart.KeyedContainer<Key>(
                encoder: self,
                codingPath: codingPath
            )
            return KeyedEncodingContainer(container)
        }

        func unkeyedContainer() -> UnkeyedEncodingContainer {
            fatalError("Unkeyed containers at root level not supported for multipart encoding")
        }

        func singleValueContainer() -> SingleValueEncodingContainer {
            RFC_2046.Multipart.SingleValueContainer(encoder: self, codingPath: codingPath)
        }
    }
}
