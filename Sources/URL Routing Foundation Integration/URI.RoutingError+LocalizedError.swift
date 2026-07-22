public import Foundation
public import URLRouting

extension RFC_3986.URI.Routing.Error: LocalizedError {
    public var errorDescription: String? { description }
}
