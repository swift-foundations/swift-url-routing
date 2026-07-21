//
//  Parser.Conversion.JSON.swift
//  swift-url-routing
//
//  Foundation.Data ⇆ Codable value conversion via JSON — the terminal hop of the
//  pointfree `.utf8.data.json(…)` chain and the `Body(.json(…))` convenience.
//

import Foundation

extension Parser.Conversion {
    /// A conversion between `Foundation.Data` and a `Codable` value via JSON.
    ///
    /// `apply` decodes the value from JSON; `unapply` encodes it back. Both directions
    /// raise ``Parser/Conversion/Error/unrepresentable`` on a coding failure.
    public struct JSON<Value: Swift.Codable> {
        @inlinable
        public init() {}
    }
}

extension Parser.Conversion.JSON: Parser.Conversion.`Protocol` {
    public typealias Input = Foundation.Data
    public typealias Output = Value
    public typealias Failure = Parser.Conversion.Error

    @inlinable
    public func apply(_ input: Foundation.Data) throws(Parser.Conversion.Error) -> Value {
        do {
            return try JSONDecoder().decode(Value.self, from: input)
        } catch {
            throw .unrepresentable
        }
    }

    @inlinable
    public func unapply(_ output: Value) throws(Parser.Conversion.Error) -> Foundation.Data {
        do {
            return try JSONEncoder().encode(output)
        } catch {
            throw .unrepresentable
        }
    }
}
