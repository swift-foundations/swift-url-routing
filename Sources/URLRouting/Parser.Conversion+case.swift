//
//  Parser.Conversion+case.swift
//  swift-url-routing
//
//  Enum-case addressing for the Route conversion seam (ratified plan R3).
//
//  Bridges swift-dual's `Case.Path` (embed/extract pair) into the institute L1
//  `Parser.Conversion.Case` (apply = embed / unapply = extract-or-throw). This
//  lets a downstream router write `Route(.case(\.someCase)) { … }` — the keypath
//  literal resolves through the `@Cases`-generated witness — while the existing
//  closure form `.case(embed:extract:)` (swift-parser-primitives) keeps working.
//

import Dual

extension Parser.Conversion.`Protocol` {
    /// A conversion between an enum case's payload and the enum, addressed by a
    /// ``Case/Path``.
    ///
    /// `apply` embeds the payload into the case (total); `unapply` extracts it,
    /// failing with ``Parser/Conversion/Error/absentCase`` when the enum holds a
    /// different case.
    ///
    /// - Parameter casePath: The case path addressing the enum case.
    /// - Returns: A conversion from the case payload to the enum.
    @inlinable
    public static func `case`<Root, Value>(
        _ casePath: Case.Path<Root, Value>
    ) -> Self where Self == Parser.Conversion.Case<Root, Value> {
        .case(embed: casePath.embed, extract: casePath.extract)
    }

    /// A conversion between an enum case's payload and the enum, addressed by a
    /// `@Cases` keypath literal (`.case(\.someCase)`).
    ///
    /// The keypath resolves against the enum's macro-generated `Cases` witness to
    /// a ``Case/Path``, then bridges to ``Parser/Conversion/Case``.
    ///
    /// - Parameter keyPath: A keypath into the enum's `Cases` witness.
    /// - Returns: A conversion from the case payload to the enum.
    @inlinable
    public static func `case`<Root: CaseAnalyzable, Value>(
        _ keyPath: KeyPath<Root.Cases, Case.Path<Root, Value>>
    ) -> Self where Self == Parser.Conversion.Case<Root, Value> {
        let casePath = Root.cases[keyPath: keyPath]
        return .case(embed: casePath.embed, extract: casePath.extract)
    }
}
