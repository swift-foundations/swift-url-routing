//
//  PointFree.Conversion.combinators.swift
//  swift-url-routing
//
//  Pointfree-compatible conversion combinators over the institute L1
//  `Parser.Conversion` engine: closure conversions (`.convert`), the byte/JSON
//  chain (`.utf8` / `.data` / `.json`), and the raw-value chain (`.representing`).
//

import Foundation

// MARK: - .convert(apply:unapply:)

extension Parser.Conversion.`Protocol` {
    /// A conversion from a forward/failable-reverse closure pair.
    ///
    /// `apply` maps forward (total); `unapply` maps back and returns `nil` when the
    /// output has no representable input, in which case printing throws. This reuses
    /// the L1 ``Parser/Conversion/Case`` embed/extract machinery.
    @inlinable
    public static func convert<A, B>(
        apply: @escaping (A) -> B,
        unapply: @escaping (B) -> A?
    ) -> Self where Self == Parser.Conversion.Case<B, A> {
        .case(embed: apply, extract: unapply)
    }
}

// MARK: - .utf8 / .data / .json chain

extension Parser.Conversion.`Protocol` where Self == Parser.Conversion.UTF8 {
    /// A total `Substring` ⇆ `[UInt8]` UTF-8 conversion.
    @inlinable
    public static var utf8: Self { .init() }
}

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
    public func json<Value: Codable>(
        _ type: Value.Type
    ) -> Parser.Conversion.Map<Self, Parser.Conversion.JSON<Value>> {
        self.map(Parser.Conversion.JSON<Value>())
    }
}

extension Parser.Conversion.`Protocol` {
    /// A standalone `Foundation.Data` ⇆ `Value` JSON conversion.
    @inlinable
    public static func json<Value: Codable>(
        _ type: Value.Type
    ) -> Self where Self == Parser.Conversion.JSON<Value> {
        .init()
    }
}

// MARK: - .representing chain

extension Parser.Conversion.`Protocol` {
    /// Chains a raw-value ⇆ `RawRepresentable` conversion onto this one.
    @inlinable
    public func representing<Wrapper: RawRepresentable>(
        _ type: Wrapper.Type
    ) -> Parser.Conversion.Map<Self, Parser.Conversion.RawValue<Wrapper>>
    where Output == Wrapper.RawValue {
        self.map(Parser.Conversion.RawValue<Wrapper>())
    }
}
