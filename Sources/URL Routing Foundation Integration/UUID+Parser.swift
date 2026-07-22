public import Foundation
public import URLRouting

extension UUID {
    /// A parser-printer that reads a whole component as a `UUID`.
    @inlinable
    public static func parser() -> URLRouting.Value<UUID> {
        URLRouting.Value(
            label: "UUID",
            parse: { UUID(uuidString: Swift.String($0)) },
            print: { $0.uuidString }
        )
    }
}
