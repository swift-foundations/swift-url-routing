//
//  Multipart.Conversion.Error.swift
//  swift-url-routing
//
//  Created by Coen ten Thije Boonkkamp on 15/11/2025.
//

import Foundation
import RFC_2046

extension RFC_2046.Multipart.Conversion {
    /// Errors that can occur during multipart conversion.
    public enum Error: Swift.Error, LocalizedError {
        case encodingFailed
        case decodingFailed(reason: String)
        case emptyRequest(reason: String)

        public var errorDescription: String? {
            switch self {
            case .encodingFailed:
                return "Failed to encode value as multipart/form-data"
            case .decodingFailed(let reason):
                return "Failed to decode multipart/form-data: \(reason)"
            case .emptyRequest(let reason):
                return reason
            }
        }
    }
}
