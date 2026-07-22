public import Foundation
public import URLRouting

extension Parser.Conversion.`Protocol` where Output == [Swift.UInt8] {
    /// Chains a `[UInt8]` ⇆ `Foundation.Data` conversion onto this one.
    @inlinable
    public var data: Parser.Conversion.Map<Self, Parser.Conversion.Data> {
        self.map(Parser.Conversion.Data())
    }
}

extension Parser.Conversion.`Protocol` where Output == Foundation.Data {
    /// Chains a `Foundation.Data` ⇆ `Value` JSON conversion onto this one.
    @inlinable
    public func json<Value: Swift.Codable>(
        _ type: Value.Type
    ) -> Parser.Conversion.Map<Self, Parser.Conversion.JSON<Value>> {
        self.map(Parser.Conversion.JSON<Value>())
    }
}

extension Parser.Conversion.`Protocol` {
    /// A standalone `Foundation.Data` ⇆ `Value` JSON conversion.
    @inlinable
    @available(
        *,
        deprecated,
        message: "Use URLRouting.Body(coding: .json(...)) so Content-Type is emitted."
    )
    public static func json<Value: Swift.Codable>(
        _ type: Value.Type
    ) -> Self where Self == Parser.Conversion.JSON<Value> {
        .init()
    }
}
