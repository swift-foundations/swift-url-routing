//
//  PointFree.Optionally.swift
//  swift-url-routing
//
//  Top-level `Optionally { … }` runtime-optional authoring surface for the routing
//  carriers (query `Field`s, memberwise `Query` groups, request `Body`).
//
//  The institute L1 `Parser.Optionally` (`Parser Optional Primitives`) backtracks via
//  an `Input.Protocol` linear cursor (`input.checkpoint` / `input.restore`) — the same
//  parity friction F1 that `OneOf` documents. The routing carriers
//  (`RFC_3986.URI.Request.Data`, `RFC_3986.URI.Request.Fields`) are structured values,
//  not cursors, so this `Optionally` is consumer-owned and backtracks by value copy
//  (the carrier is `Copyable`): save the input, try the wrapped router, and on failure
//  restore the saved input and yield `nil`. This mirrors `OneOf`'s value-backtracking
//  machinery, dropping the second alternative for a `nil` result.
//
//  Unlike the L1 combinator — which pins `Failure` to `Never` and must therefore
//  *swallow* printer errors — this `Optionally` inherits the wrapped router's `Failure`
//  (the single routing error domain `RFC_3986.URI.Routing.Error`). Parsing is still
//  infallible in practice (a wrapped failure becomes `nil`), but a genuine printer
//  failure on a present value propagates rather than being discarded, and the carrier
//  is restored on that throw so no partial consumption leaks in either direction.
//

/// Runs a router as a runtime-optional: on parse it attempts the wrapped router and,
/// on failure, restores the carrier and yields `nil`; on print it emits nothing for
/// `nil` and prints the wrapped router for a present value.
///
/// ```swift
/// URLRouting.Query {
///     Optionally {
///         Field("page") { Int.parser() }
///     }
/// }
/// ```
///
/// The wrapped router's output becomes optional: `Optionally { Field("page") { Int.parser() } }`
/// parses to `Int?` — `.some` when the field is present and parses, `nil` when it is
/// absent (with the carrier left untouched).
public struct Optionally<Wrapped: Parser.`Protocol`>: Parser.`Protocol`
where Wrapped.Input: Copyable & Escapable {
    public typealias Input = Wrapped.Input
    public typealias Output = Wrapped.Output?
    public typealias Failure = Wrapped.Failure
    public typealias Body = Never

    @usableFromInline
    let wrapped: Wrapped

    /// Creates a runtime-optional from a single wrapped router.
    ///
    /// The trailing closure is a plain `() -> Wrapped`, not a result builder: pinning a
    /// `@Take.Builder<Wrapped.Input>` attribute here makes `Wrapped` uninferrable when
    /// `Optionally { … }` is nested inside another builder (the builder's generic
    /// argument depends on the very parameter being inferred). Every routing call site
    /// wraps exactly one router, so the closure return type infers `Wrapped` directly.
    @inlinable
    public init(_ build: () -> Wrapped) {
        self.wrapped = build()
    }

    /// Parses the wrapped router, backtracking by value copy and returning `nil` on
    /// failure. Never throws in practice; the typed-throws signature keeps `Optionally`
    /// in the wrapped router's error domain so it composes alongside required routers.
    @inlinable
    public func parse(_ input: inout Wrapped.Input) throws(Wrapped.Failure) -> Wrapped.Output? {
        let saved = input
        do throws(Wrapped.Failure) {
            return try self.wrapped.parse(&input)
        } catch {
            input = saved
            return nil
        }
    }
}

extension Optionally: Serializer.`Protocol`, Coder.`Protocol`, Parser.Bidirectional where Wrapped: Parser.Bidirectional {
    /// Prints the wrapped router for a present value and nothing for `nil`. On a printer
    /// failure the carrier is restored before the error propagates, so a failed print
    /// leaks no partial state.
    /// The emission buffer type — `Parser.Bidirectional` pins `Buffer == Input`.
    public typealias Buffer = Wrapped.Input

    /// Explicit leaf body: both `Parser.Protocol` and `Serializer.Protocol`
    /// supply a `Body == Never` default getter; the explicit override
    /// disambiguates between the two inherited candidates (the Coder.Witness
    /// precedent).
    @inlinable
    public var body: Never {
        borrowing get { return fatalError("leaf router — serialize(_:into:) is implemented directly") }
    }

    @inlinable
    public func serialize(_ output: Wrapped.Output?, into input: inout Wrapped.Input) throws(Wrapped.Failure) {
        guard let output else { return }
        let saved = input
        do throws(Wrapped.Failure) {
            try self.wrapped.print(output, into: &input)
        } catch {
            input = saved
            throw error
        }
    }
}

extension Optionally: Sendable where Wrapped: Sendable {}
