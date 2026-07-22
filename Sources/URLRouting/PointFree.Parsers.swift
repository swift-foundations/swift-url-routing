//
//  PointFree.Parsers.swift
//  swift-url-routing
//
//  Pointfree-compatible `.parser()` factories producing ``URLRouting/Value`` leaves
//  that read a whole component `Substring` into a typed value.
//

extension Int {
    /// A parser-printer that reads a whole component as an `Int`.
    @inlinable
    public static func parser() -> URLRouting.Value<Int> {
        URLRouting.Value(
            label: "Int",
            parse: { Int(Swift.String($0)) },
            print: { Swift.String($0) }
        )
    }
}

extension Bool {
    /// A parser-printer that reads a whole component as a `Bool`.
    @inlinable
    public static func parser() -> URLRouting.Value<Bool> {
        URLRouting.Value(
            label: "Bool",
            parse: { Bool(Swift.String($0)) },
            print: { Swift.String($0) }
        )
    }
}

extension RawRepresentable where RawValue == Swift.String {
    /// A parser-printer that reads a whole component as this `RawRepresentable`
    /// (string-backed) type.
    @inlinable
    public static func parser() -> URLRouting.Value<Self> {
        URLRouting.Value(
            label: Swift.String(describing: Self.self),
            parse: { Self(rawValue: Swift.String($0)) },
            print: { $0.rawValue }
        )
    }
}
