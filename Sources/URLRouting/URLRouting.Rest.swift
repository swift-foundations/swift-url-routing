//
//  URLRouting.Rest.swift
//  swift-url-routing
//
//  Consumer-local bidirectional "consume the rest" leaf.
//
//  The institute L1 `Parser.Rest` is parse-only (no `Parser.Printer`
//  conformance) and constrains `Input: Collection.Slice.Protocol`, so
//  `Parser.Rest<Data>` (the HTTP body carrier) does not type-check — parity
//  GAP-4. It is also missing the printer that `URI.Query.Field` / `RFC_7230.Body`
//  need to round-trip. Rather than widen the L1 slice contract or add L1
//  conformances (out of this lane's scope), this leaf sidesteps both at the
//  consumer level: it is `Parser.Bidirectional` over any
//  `RangeReplaceableCollection` input (`Substring` for query/field values,
//  `Data` for bodies), consuming all remaining input on `parse` and restoring it
//  on `print`.
//
//  It is infallible (`Failure == Never`), which is why the pointfree call sites'
//  vestigial `.replaceError(with:)` wrapper (the pointfree `Rest` never fails, so
//  the default was unreachable) is dropped when re-basing onto this leaf.
//

import Parser_Primitive

extension URLRouting {
    /// A bidirectional parser-printer that consumes all remaining input on
    /// `parse` and restores it on `print`.
    public struct Rest<Input: RangeReplaceableCollection>: Parser.Bidirectional {
        /// The output is the whole remaining input.
        public typealias Output = Input
        /// Consuming the rest never fails.
        public typealias Failure = Never

        @inlinable
        public init() {}

        @inlinable
        public func parse(_ input: inout Input) -> Input {
            let remaining = input
            input = Input()
            return remaining
        }

        @inlinable
        public func print(_ output: Input, into input: inout Input) {
            input.insert(contentsOf: output, at: input.startIndex)
        }
    }
}

extension URLRouting.Rest: Sendable {}
