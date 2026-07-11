//
//  Parser.Conversion.UTF8.swift
//  swift-url-routing
//
//  Substring ⇆ UTF-8 byte array conversion — the first hop of the pointfree
//  `.utf8.data.json(…)` conversion chain.
//

extension Parser.Conversion {
    /// A total conversion between a `Substring` and its UTF-8 byte encoding.
    public struct UTF8 {
        @inlinable
        public init() {}
    }
}

extension Parser.Conversion.UTF8: Parser.Conversion.`Protocol` {
    public typealias Input = Substring
    public typealias Output = [Swift.UInt8]
    public typealias Failure = Never

    @inlinable
    public func apply(_ input: Substring) -> [Swift.UInt8] {
        Array(input.utf8)
    }

    @inlinable
    public func unapply(_ output: [Swift.UInt8]) -> Substring {
        Substring(Swift.String(decoding: output, as: Unicode.UTF8.self))
    }
}
