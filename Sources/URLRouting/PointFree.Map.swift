//
//  PointFree.Map.swift
//  swift-url-routing
//
//  The router-level `.map(conversion)` — the pointfree spelling for transforming a
//  router's output through a conversion. Unlike the engine's `Parser.Protocol.map`,
//  which composes error domains into `Either<Upstream.Failure, Downstream.Failure>`,
//  the routing surface presents a SINGLE error domain: the conversion's failure is
//  re-wrapped into `RFC_3986.URI.Routing.Error`, exactly as the `Route(conversion)`
//  combinator does internally. This keeps a mapped router a `ParserPrinter` (whose
//  `Failure` is pinned to the routing error) so it can be erased and stored uniformly.
//

import RFC_3986

extension URLRouting {
    /// A router that maps an upstream router's output through a conversion, collapsing
    /// the conversion's error into the unified routing error domain.
    public struct Map<Upstream, Downstream>: ParserPrinter
    where
        Upstream: Parser.Bidirectional,
        Upstream.Input == RFC_3986.URI.Request.Data,
        Upstream.Failure == RFC_3986.URI.Routing.Error,
        Downstream: Parser.Conversion.`Protocol`,
        Downstream.Input == Upstream.Output
    {
        public typealias Input = RFC_3986.URI.Request.Data
        public typealias Output = Downstream.Output
        public typealias Body = Never

        @usableFromInline
        let upstream: Upstream

        @usableFromInline
        let downstream: Downstream

        @usableFromInline
        init(upstream: Upstream, downstream: Downstream) {
            self.upstream = upstream
            self.downstream = downstream
        }

        @inlinable
        public func parse(
            _ input: inout RFC_3986.URI.Request.Data
        ) throws(RFC_3986.URI.Routing.Error) -> Downstream.Output {
            let value = try self.upstream.parse(&input)
            do {
                return try self.downstream.apply(value)
            } catch {
                throw RFC_3986.URI.Routing.Error(
                    component: .request,
                    failure: .parseFailed("\(error)")
                )
            }
        }

        @inlinable
        public func print(
            _ output: Downstream.Output,
            into input: inout RFC_3986.URI.Request.Data
        ) throws(RFC_3986.URI.Routing.Error) {
            let value: Downstream.Input
            do {
                value = try self.downstream.unapply(output)
            } catch {
                throw RFC_3986.URI.Routing.Error(
                    component: .request,
                    failure: .parseFailed("\(error)")
                )
            }
            try self.upstream.print(value, into: &input)
        }
    }
}

extension URLRouting.Map: Sendable where Upstream: Sendable, Downstream: Sendable {}

// MARK: - Router `.map(conversion)`

extension Parser.Bidirectional
where
    Input == RFC_3986.URI.Request.Data,
    Failure == RFC_3986.URI.Routing.Error
{
    /// Maps this router's output through a conversion, collapsing the conversion's
    /// error into the unified routing error domain (`RFC_3986.URI.Routing.Error`).
    ///
    /// This is the routing-surface counterpart to the engine's
    /// ``Parser/Protocol/map(_:)-(Downstream)``: where the engine composes error
    /// domains into an `Either`, a router keeps its single error domain so the result
    /// remains a ``ParserPrinter`` (erasable, storable as `any ParserPrinter<…>`).
    @inlinable
    public func map<Downstream: Parser.Conversion.`Protocol`>(
        _ conversion: Downstream
    ) -> URLRouting.Map<Self, Downstream> where Downstream.Input == Output {
        URLRouting.Map(upstream: self, downstream: conversion)
    }
}
