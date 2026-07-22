import Foundation
public import HTTP_Body
public import RFC_3986
public import URLFormCoding

extension Form {
    /// Transitional HTTP body coder over the existing URL-form conversion.
    ///
    /// B5 replaces the implementation with `HTML.Form.Coder`; the public
    /// `.form(...)` construction spelling is deliberately stable across that
    /// replacement.
    public struct Coder<Value: Swift.Codable>: @unchecked Sendable {
        @usableFromInline
        let conversion: Form.Conversion<Value>

        @inlinable
        public init(
            _ type: Value.Type,
            decoder: Form.Decoder = .init(),
            encoder: Form.Encoder = .init()
        ) {
            self.conversion = Form.Conversion(type, decoder: decoder, encoder: encoder)
        }
    }
}

extension Form.Coder: RFC_9110.Body.Coder.`Protocol` {
    public typealias Input = [Byte]
    public typealias Buffer = [Byte]
    public typealias Output = Value
    public typealias Failure = RFC_3986.URI.Routing.Error
    public typealias Body = Never

    @inlinable
    public var body: Never {
        borrowing get {
            fatalError("leaf codec — parse(_:) and serialize(_:into:) are implemented directly")
        }
    }

    public static var contentType: HTTP.MediaType { .formUrlEncoded }

    @inlinable
    public func parse(_ input: inout [Byte]) throws(Failure) -> Value {
        let data = Foundation.Data(input.map(\.underlying))
        let output = try conversion.apply(data)
        input = []
        return output
    }

    @inlinable
    public func serialize(_ output: Value, into buffer: inout [Byte]) throws(Failure) {
        let data = try conversion.unapply(output)
        buffer.append(contentsOf: data.map(Byte.init))
    }
}

extension RFC_9110.Body.Coder.`Protocol` {
    /// Uses the existing URL-form codec while coupling it to its media type.
    @inlinable
    public static func form<Value: Swift.Codable>(
        _ type: Value.Type,
        decoder: Form.Decoder = .init(),
        encoder: Form.Encoder = .init()
    ) -> Self where Self == Form.Coder<Value> {
        .init(type, decoder: decoder, encoder: encoder)
    }
}
