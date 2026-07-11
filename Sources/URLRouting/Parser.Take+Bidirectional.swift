//
//  Parser.Take+Bidirectional.swift
//  swift-url-routing
//
//  The engine's `Parser.Take.Two` / `Parser.Skip.First` / `Parser.Skip.Second`
//  conform to `Parser.Protocol` and (conditionally) `Parser.Printer`, but the
//  combined `Parser.Bidirectional` refinement is not declared. Routing composes
//  these nodes into printable multi-value routes (via ``URLRouting/Take/Builder``),
//  so the refinement conformances are declared here, consumer-side.
//

// `Parser.Always` (used by an empty `Route(.case(x))` and by `.baseURL`) already
// conforms to `Parser.Protocol` and, for `Output == Void`, `Parser.Printer` — but the
// engine does not declare the combined `Parser.Bidirectional` refinement. A Void-output
// `Always` round-trips (parse yields `()`, print is a no-op), so the refinement holds.
extension Parser.Always: @retroactive Parser.Bidirectional where Output == Void {}

extension Parser.Take.Two: @retroactive Parser.Bidirectional
where P0: Parser.Bidirectional, P1: Parser.Bidirectional {}

extension Parser.Skip.First: @retroactive Parser.Bidirectional
where P0: Parser.Bidirectional, P1: Parser.Bidirectional {}

extension Parser.Skip.Second: @retroactive Parser.Bidirectional
where P0: Parser.Bidirectional, P1: Parser.Bidirectional {}
