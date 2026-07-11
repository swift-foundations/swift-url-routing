//
//  Parser.Conversion.Data.swift
//  swift-url-routing
//
//  UTF-8 byte array ⇆ Foundation.Data conversion — the middle hop of the pointfree
//  `.utf8.data.json(…)` conversion chain.
//

import Foundation

extension Parser.Conversion {
    /// A total conversion between a `[UInt8]` byte array and `Foundation.Data`.
    public struct Data {
        @inlinable
        public init() {}
    }
}

extension Parser.Conversion.Data: Parser.Conversion.`Protocol` {
    public typealias Input = [Swift.UInt8]
    public typealias Output = Foundation.Data
    public typealias Failure = Never

    @inlinable
    public func apply(_ input: [Swift.UInt8]) -> Foundation.Data {
        Foundation.Data(input)
    }

    @inlinable
    public func unapply(_ output: Foundation.Data) -> [Swift.UInt8] {
        [Swift.UInt8](output)
    }
}
