import Foundation
public import HTTP_Body

extension Parser.Conversion.JSON {
    /// Transitional HTTP body coder over URLRouting's Foundation JSON bridge.
    ///
    /// B6 retirement condition (B2-18): replace this implementation with the
    /// swift-json-backed bridge and remove `JSONEncoder`/`JSONDecoder` from the
    /// routing core. The consumer-facing `.json(...)` spelling must remain.
    public struct Coder {
        @usableFromInline
        let conversion: Parser.Conversion.JSON<Value>

        @inlinable
        public init(_ type: Value.Type) {
            _ = type
            self.conversion = .init()
        }
    }
}

extension Parser.Conversion.JSON.Coder: RFC_9110.Body.Coder.`Protocol` {
    public typealias Input = [Byte]
    public typealias Buffer = [Byte]
    public typealias Output = Value
    public typealias Failure = Parser.Conversion.Error
    public typealias Body = Never

    @inlinable
    public var body: Never {
        borrowing get {
            fatalError("leaf codec — parse(_:) and serialize(_:into:) are implemented directly")
        }
    }

    public static var contentType: HTTP.MediaType { .json }

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
    /// Uses the existing JSON conversion while coupling it to `application/json`.
    @inlinable
    public static func json<Value: Swift.Codable>(
        _ type: Value.Type
    ) -> Self where Self == Parser.Conversion.JSON<Value>.Coder {
        .init(type)
    }
}
