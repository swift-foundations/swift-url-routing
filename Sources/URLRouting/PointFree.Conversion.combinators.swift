//
//  PointFree.Conversion.combinators.swift
//  swift-url-routing
//
//  Pointfree-compatible conversion combinators over the institute L1
//  `Parser.Conversion` engine: closure conversions (`.convert`), UTF-8 bytes
//  (`.utf8`), and the raw-value chain (`.representing`).
//

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

// MARK: - .utf8

extension Parser.Conversion.`Protocol` where Self == Parser.Conversion.UTF8 {
    /// A total `Substring` ⇆ `[UInt8]` UTF-8 conversion.
    @inlinable
    public static var utf8: Self { .init() }
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
