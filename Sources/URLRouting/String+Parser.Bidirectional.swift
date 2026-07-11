//
//  String+Parser.Bidirectional.swift
//  swift-url-routing
//
//  `String` already conforms to `Parser.Protocol` and `Parser.Printer` (literal
//  matcher) in the L1 conformance module; this declares the combined
//  `Parser.Bidirectional` refinement so string literals round-trip inside `Path { }`.
//

extension Swift.String: @retroactive Parser.Bidirectional {}
