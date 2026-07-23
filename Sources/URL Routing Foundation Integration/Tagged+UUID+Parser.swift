public import Foundation
public import Tagged_Primitives
public import URLRouting

extension Tagged where Underlying == UUID {
    /// A parser-printer that reads a whole route component as a phantom-typed
    /// `UUID` identifier.
    ///
    /// Parsing reads the component as a `Foundation.UUID` (via
    /// ``Foundation/UUID/parser()``) and wraps it in `Self`; printing writes
    /// back the underlying `UUID`'s string form. Malformed input (not a valid
    /// UUID string) is a parse failure.
    ///
    /// ```swift
    /// enum Session {}
    /// typealias SessionID = Tagged<Session, UUID>
    ///
    /// Path { "sessions"; SessionID.parser() }
    /// ```
    @inlinable
    public static func parser()
        -> Parser_Primitive.Parser.Converted<
            URLRouting.Value<UUID>, Parser_Primitive.Parser.Conversion.Case<Self, UUID>
        >
    {
        (UUID.parser() as URLRouting.Value<UUID>).map(
            .convert(
                apply: { Self($0) },
                unapply: { $0.underlying }
            )
        )
    }
}
