public import Tagged_Primitives

// Phantom-typed identifier parsers for route components.
//
// `Tagged<Tag, Underlying>` wraps an `Underlying` value with a phantom `Tag`
// that keeps otherwise-identical identifiers distinct at the type level
// (`Tagged<User, Int>` and `Tagged<Order, Int>` are different types). This
// factory re-expresses the `Int.parser()` leaf through a total forward /
// failable-reverse `.convert` conversion, so a whole path component
// round-trips into a tagged identifier and back.
//
// The `Tag` is left implicitly `Copyable & Escapable`: route tags are plain
// phantom enums, and the conversion embeds/extracts an owned `Underlying`.
// The `UUID` counterpart lives in `URL Routing Foundation Integration`
// (`Foundation.UUID`).

extension Tagged where Underlying == Int {
    /// A parser-printer that reads a whole route component as a phantom-typed
    /// integer identifier.
    ///
    /// Parsing reads the component as an `Int` (via ``Swift/Int/parser()``) and
    /// wraps it in `Self`; printing writes back the underlying `Int`'s string
    /// form. As with the `Int.parser()` leaf, the component is atomic — a
    /// partial match (e.g. `"42-foo"`) is a failure, not a prefix consumption.
    ///
    /// ```swift
    /// enum User {}
    /// typealias UserID = Tagged<User, Int>
    ///
    /// Path { "users"; UserID.parser() }
    /// ```
    @inlinable
    public static func parser()
        -> Parser_Primitive.Parser.Converted<
            URLRouting.Value<Int>, Parser_Primitive.Parser.Conversion.Case<Self, Int>
        >
    {
        (Int.parser() as URLRouting.Value<Int>).map(
            .convert(
                apply: { Self($0) },
                unapply: { $0.underlying }
            )
        )
    }
}
