//
//  ParserPrinter.convenience.swift
//  swift-url-routing
//
//  By-value parse and no-buffer print conveniences over the routing carrier,
//  matching the pointfree top-level `router.parse(_:)` / `router.print(_:)` shapes.
//  The institute L1 by-value `parse(_:)` requires `Input: Collection.Slice.Protocol`,
//  which the structured `RFC_3986.URI.Request.Data` carrier is not — so these are
//  supplied here at the routing boundary.
//

import RFC_3986

// MARK: - By-value parse

extension Parser.`Protocol` where Input == RFC_3986.URI.Request.Data {
    /// Parses a route from a request-data value passed by value.
    ///
    /// Convenience over the `inout`-based ``Parser/Protocol/parse(_:)`` requirement:
    /// copies the carrier, runs the parser, and returns the output. Routing parsers
    /// self-assert end-of-path (`RFC_3986.URI.Route` runs `PathEnd`), so no trailing
    /// consumption check is applied here.
    @inlinable
    public borrowing func parse(
        _ input: RFC_3986.URI.Request.Data
    ) throws(Failure) -> Output {
        var input = input
        return try parse(&input)
    }
}

// MARK: - Printing compatibility spellings over `serialize`

extension Parser.Bidirectional {
    /// Prints (serializes) a route into an existing carrier.
    ///
    /// Compatibility spelling over the coder-unification requirement
    /// ``Serializer/Protocol/serialize(_:into:)`` — `Parser.Bidirectional`
    /// pins `Buffer == Input`, so the retired `Parser.Printer.print(_:into:)`
    /// shape forwards directly. Forward-order append emission is byte-equal to
    /// the retired prepend algebra (spike GREEN).
    @inlinable
    public borrowing func print(
        _ output: Output,
        into input: inout Input
    ) throws(Failure) {
        try serialize(output, into: &input)
    }
}

// MARK: - No-buffer print

extension Parser.Bidirectional where Input == RFC_3986.URI.Request.Data {
    /// Prints a route into a fresh request-data value.
    ///
    /// Convenience over the `inout`-based `serialize(_:into:)`: the
    /// routing carrier is not `RangeReplaceableCollection`, so the engine's
    /// buffer-returning `serialize(_:)` does not apply here.
    @inlinable
    public borrowing func print(
        _ output: Output
    ) throws(Failure) -> RFC_3986.URI.Request.Data {
        var data = RFC_3986.URI.Request.Data()
        try serialize(output, into: &data)
        return data
    }
}

extension Parser.Bidirectional where Input == RFC_3986.URI.Request.Data, Output == Void {
    /// Prints a `Void`-output parser (e.g. a `Method` or `Scheme` matcher) into a
    /// fresh request-data value.
    @inlinable
    public borrowing func print() throws(Failure) -> RFC_3986.URI.Request.Data {
        try print(())
    }
}

// MARK: - Buffer-returning print (linear carriers)

extension Parser.Bidirectional where Input: RangeReplaceableCollection {
    /// Prints (serializes) a value into a fresh linear buffer.
    ///
    /// Compatibility spelling over the engine's buffer-returning
    /// `serialize(_:)` for linear carriers (`Substring`, `Data`).
    @inlinable
    public borrowing func print(_ output: Output) throws(Failure) -> Input {
        try serialize(output)
    }
}
