import Foundation
public import HTML_Form_Coder_Codable
import RFC_3986
public import typealias HTML_Standard.HTML

extension HTML.Form.Coder {
    /// Transitional conversion surface retained until the routing/form bridge is
    /// dissolved in Batch 7. Encoding and decoding are delegated to the
    /// canonical HTML form coder.
    public struct Conversion<Value: Swift.Codable>: @unchecked Sendable {
        public let decoder: HTML.Form.Coder.Decoder
        public let encoder: HTML.Form.Coder.Encoder

        public init(
            _ type: Value.Type,
            decoder: HTML.Form.Coder.Decoder = .init(),
            encoder: HTML.Form.Coder.Encoder = .init()
        ) {
            self.decoder = decoder
            self.encoder = encoder
        }
    }
}

extension HTML.Form.Coder.Conversion: Parser.Conversion.`Protocol` {
    public typealias Input = Foundation.Data
    public typealias Output = Value
    public typealias Failure = RFC_3986.URI.Routing.Error

    public func apply(
        _ input: Foundation.Data
    ) throws(RFC_3986.URI.Routing.Error) -> Value {
        do {
            return try decoder.decode(Value.self, from: input)
        } catch {
            throw RFC_3986.URI.Routing.Error(
                component: .body,
                failure: .parseFailed(String(describing: error))
            )
        }
    }

    public func unapply(
        _ output: Value
    ) throws(RFC_3986.URI.Routing.Error) -> Foundation.Data {
        do {
            return try encoder.encode(output)
        } catch {
            throw RFC_3986.URI.Routing.Error(
                component: .body,
                failure: .parseFailed(String(describing: error))
            )
        }
    }
}
