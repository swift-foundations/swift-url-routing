/// A custom parameter attribute that constructs path component parsers from closures. The
/// constructed parser runs a number of parsers against each patch component, one after the other,
/// and accumulates their outputs.
///
/// The ``Path`` router acts as an entry point into `@PathBuilder` syntax, where you can list all of
/// the path component parsers you want to run. For example, to route to a particular user by their
/// integer identifier:
///
/// ```swift
/// try Path {
///   "users"
///   Digits()
/// }
/// .match(path: "/users/42") // 42
/// ```
@resultBuilder
public enum PathBuilder {
    @inlinable
    public static func buildPartialBlock<P: Parser>(first: P) -> P
    where P.Input == URIRequestData {
        first
    }

    @_disfavoredOverload
    @inlinable
    public static func buildPartialBlock<P0, P1>(accumulated: P0, next: P1) -> SkipFirst<P0, P1>
    where P0.Input == URIRequestData, P1.Input == URIRequestData, P0.Output == Void {
        SkipFirst(accumulated, next)
    }

    @inlinable
    public static func buildPartialBlock<P0, P1>(accumulated: P0, next: P1) -> SkipSecond<P0, P1>
    where P0.Input == URIRequestData, P1.Input == URIRequestData, P1.Output == Void {
        SkipSecond(accumulated, next)
    }

    @_disfavoredOverload
    @inlinable
    public static func buildPartialBlock<P0: Parser, P1: Parser, each O1, O2>(
        accumulated: P0,
        next: P1
    ) -> Parsers.Map<Take2<P0, P1>, (repeat each O1, O2)>
    where
        P0.Input == URIRequestData,
        P1.Input == URIRequestData,
        P0.Output == (repeat each O1),
        P1.Output == O2
    {
        Take2(accumulated, next)
            .map { tuple, next in
                (repeat each tuple, next)
            }
    }

    @inlinable
    public static func buildExpression<P: Parser>(_ parser: P) -> Component<P> where P.Input == Substring {
        Component(parser)
    }

    @inlinable
    @_disfavoredOverload
    public static func buildExpression<P: Parser>(
        _ parser: P
    ) -> Component<From<Conversions.SubstringToUTF8View, Substring.UTF8View, P>>
    where P.Input == Substring.UTF8View {
        Component(
            From(.utf8) {
                parser
            }
        )
    }

    public struct Component<ComponentParser: Parser>: Parser
    where ComponentParser.Input == Substring {
        @usableFromInline
        let componentParser: ComponentParser

        @usableFromInline
        init(_ componentParser: ComponentParser) {
            self.componentParser = componentParser
        }

        @inlinable
        public func parse(_ input: inout URIRequestData) throws -> ComponentParser.Output {
            guard input.path.count >= 1 else { throw RoutingError() }
            return try self.componentParser.parse(input.path.removeFirst())
        }
    }
}

extension PathBuilder.Component: ParserPrinter where ComponentParser: ParserPrinter {
    @inlinable
    public func print(_ output: ComponentParser.Output, into input: inout URIRequestData) rethrows {
        try input.path.prepend(self.componentParser.print(output))
    }
}

// MARK: - Helper Types for buildPartialBlock

extension PathBuilder {
    public struct SkipFirst<P0: Parser, P1: Parser>: Parser
    where P0.Input == URIRequestData, P1.Input == URIRequestData, P0.Output == Void {
        @usableFromInline let p0: P0, p1: P1

        @usableFromInline init(_ p0: P0, _ p1: P1) {
            self.p0 = p0
            self.p1 = p1
        }

        @inlinable public func parse(_ input: inout URIRequestData) rethrows -> P1.Output {
            try self.p0.parse(&input)
            return try self.p1.parse(&input)
        }
    }

    public struct SkipSecond<P0: Parser, P1: Parser>: Parser
    where P0.Input == URIRequestData, P1.Input == URIRequestData, P1.Output == Void {
        @usableFromInline let p0: P0, p1: P1

        @usableFromInline init(_ p0: P0, _ p1: P1) {
            self.p0 = p0
            self.p1 = p1
        }

        @inlinable public func parse(_ input: inout URIRequestData) rethrows -> P0.Output {
            let o0 = try self.p0.parse(&input)
            try self.p1.parse(&input)
            return o0
        }
    }

    public struct Take2<P0: Parser, P1: Parser>: Parser
    where P0.Input == URIRequestData, P1.Input == URIRequestData {
        @usableFromInline let p0: P0, p1: P1

        @usableFromInline init(_ p0: P0, _ p1: P1) {
            self.p0 = p0
            self.p1 = p1
        }

        @inlinable public func parse(_ input: inout URIRequestData) rethrows -> (P0.Output, P1.Output) {
            let o0 = try self.p0.parse(&input)
            let o1 = try self.p1.parse(&input)
            return (o0, o1)
        }
    }
}

extension PathBuilder.SkipFirst: ParserPrinter where P0: ParserPrinter, P1: ParserPrinter {
    @inlinable public func print(_ output: P1.Output, into input: inout URIRequestData) rethrows {
        try self.p1.print(output, into: &input)
        try self.p0.print((), into: &input)
    }
}

extension PathBuilder.SkipSecond: ParserPrinter where P0: ParserPrinter, P1: ParserPrinter {
    @inlinable public func print(_ output: P0.Output, into input: inout URIRequestData) rethrows {
        try self.p1.print((), into: &input)
        try self.p0.print(output, into: &input)
    }
}

extension PathBuilder.Take2: ParserPrinter where P0: ParserPrinter, P1: ParserPrinter {
    @inlinable public func print(_ output: (P0.Output, P1.Output), into input: inout URIRequestData) rethrows {
        try self.p1.print(output.1, into: &input)
        try self.p0.print(output.0, into: &input)
    }
}
