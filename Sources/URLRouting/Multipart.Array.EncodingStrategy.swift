//
//  Multipart.Array.EncodingStrategy.swift
//  swift-url-routing
//
//  Created by Coen ten Thije Boonkkamp on 15/11/2025.
//

import Foundation
import RFC_2046

extension RFC_2046.Multipart {
    public enum Array {
        /// Strategy for encoding arrays in multipart fields.
        ///
        /// ## Examples
        ///
        /// - `.accumulateValues`: Repeats field name for each value (Mailgun style)
        ///   ```
        ///   --boundary
        ///   Content-Disposition: form-data; name="tags"
        ///
        ///   swift
        ///   --boundary
        ///   Content-Disposition: form-data; name="tags"
        ///
        ///   ios
        ///   ```
        ///
        /// - `.brackets`: Uses empty brackets notation (PHP/Rails style)
        ///   ```
        ///   --boundary
        ///   Content-Disposition: form-data; name="tags[]"
        ///
        ///   swift
        ///   ```
        public enum EncodingStrategy: Sendable {
            /// Repeats the field name for each array element.
            /// Example: `name="tags"\r\n\r\nswift\r\n...name="tags"\r\n\r\nios`
            case accumulateValues

            /// Appends empty brackets to field name.
            /// Example: `name="tags[]"\r\n\r\nswift\r\n...name="tags[]"\r\n\r\nios`
            case brackets
        }
    }
}
