import Parsing
import RFC_3986

// MARK: - RFC 3986 URI Path Builder

/// A custom parameter attribute that constructs path component parsers from closures. The
/// constructed parser runs a number of parsers against each patch component, one after the other,
/// and accumulates their outputs.
///
/// The ``Path`` router acts as an entry point into `@RFC_3986.URI.Path.Builder` syntax, where you can list all of
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
extension RFC_3986.URI.Path {
    @resultBuilder
    public enum Builder {
        @inlinable
        public static func buildPartialBlock<P: Parsing.Parser>(first: P) -> P
        where P.Input == RFC_3986.URI.Request.Data {
            first
        }

        @_disfavoredOverload
        @inlinable
        public static func buildPartialBlock<P0, P1>(accumulated: P0, next: P1) -> SkipFirst<P0, P1>
        where P0.Input == RFC_3986.URI.Request.Data, P1.Input == RFC_3986.URI.Request.Data, P0.Output == Void {
            SkipFirst(accumulated, next)
        }

        @inlinable
        public static func buildPartialBlock<P0, P1>(accumulated: P0, next: P1) -> SkipSecond<P0, P1>
        where P0.Input == RFC_3986.URI.Request.Data, P1.Input == RFC_3986.URI.Request.Data, P1.Output == Void {
            SkipSecond(accumulated, next)
        }

        @_disfavoredOverload
        @inlinable
        public static func buildPartialBlock<P0: Parsing.Parser, P1: Parsing.Parser, each O1, O2>(
            accumulated: P0,
            next: P1
        ) -> Parsers.Map<Take2<P0, P1>, (repeat each O1, O2)>
        where
            P0.Input == RFC_3986.URI.Request.Data,
            P1.Input == RFC_3986.URI.Request.Data,
            P0.Output == (repeat each O1),
            P1.Output == O2
        {
            Take2(accumulated, next)
                .map { tuple, next in
                    (repeat each tuple, next)
                }
        }

        @inlinable
        public static func buildExpression<P: Parsing.Parser>(_ parser: P) -> Component<P> where P.Input == Substring {
            Component(parser)
        }

        @inlinable
        @_disfavoredOverload
        public static func buildExpression<P: Parsing.Parser>(
            _ parser: P
        ) -> Component<From<Conversions.SubstringToUTF8View, Substring.UTF8View, P>>
        where P.Input == Substring.UTF8View {
            Component(
                From(.utf8) {
                    parser
                }
            )
        }

        public struct Component<ComponentParser: Parsing.Parser>: Parsing.Parser
        where ComponentParser.Input == Substring {
            @usableFromInline
            let componentParser: ComponentParser

            @usableFromInline
            init(_ componentParser: ComponentParser) {
                self.componentParser = componentParser
            }

            @inlinable
            public func parse(_ input: inout RFC_3986.URI.Request.Data) throws -> ComponentParser.Output {
                guard input.path.count >= 1 else {
                    throw RFC_3986.URI.Routing.Error(
                        component: .path,
                        failure: .invalid("Path is too short"),
                        context: "Expected at least 1 component, got \(input.path.count)"
                    )
                }
                return try self.componentParser.parse(input.path.removeFirst())
            }
        }
    }
}

extension RFC_3986.URI.Path.Builder.Component: ParserPrinter where ComponentParser: ParserPrinter {
    @inlinable
    public func print(_ output: ComponentParser.Output, into input: inout RFC_3986.URI.Request.Data) rethrows {
        try input.path.prepend(self.componentParser.print(output))
    }
}

// MARK: - Helper Types for buildPartialBlock

extension RFC_3986.URI.Path.Builder {
    public struct SkipFirst<P0: Parsing.Parser, P1: Parsing.Parser>: Parsing.Parser
    where P0.Input == RFC_3986.URI.Request.Data, P1.Input == RFC_3986.URI.Request.Data, P0.Output == Void {
        @usableFromInline let p0: P0, p1: P1

        @usableFromInline init(_ p0: P0, _ p1: P1) {
            self.p0 = p0
            self.p1 = p1
        }

        @inlinable public func parse(_ input: inout RFC_3986.URI.Request.Data) rethrows -> P1.Output {
            try self.p0.parse(&input)
            return try self.p1.parse(&input)
        }
    }

    public struct SkipSecond<P0: Parsing.Parser, P1: Parsing.Parser>: Parsing.Parser
    where P0.Input == RFC_3986.URI.Request.Data, P1.Input == RFC_3986.URI.Request.Data, P1.Output == Void {
        @usableFromInline let p0: P0, p1: P1

        @usableFromInline init(_ p0: P0, _ p1: P1) {
            self.p0 = p0
            self.p1 = p1
        }

        @inlinable public func parse(_ input: inout RFC_3986.URI.Request.Data) rethrows -> P0.Output {
            let o0 = try self.p0.parse(&input)
            try self.p1.parse(&input)
            return o0
        }
    }

    public struct Take2<P0: Parsing.Parser, P1: Parsing.Parser>: Parsing.Parser
    where P0.Input == RFC_3986.URI.Request.Data, P1.Input == RFC_3986.URI.Request.Data {
        @usableFromInline let p0: P0, p1: P1

        @usableFromInline init(_ p0: P0, _ p1: P1) {
            self.p0 = p0
            self.p1 = p1
        }

        @inlinable public func parse(_ input: inout RFC_3986.URI.Request.Data) rethrows -> (P0.Output, P1.Output) {
            let o0 = try self.p0.parse(&input)
            let o1 = try self.p1.parse(&input)
            return (o0, o1)
        }
    }
}

extension RFC_3986.URI.Path.Builder.SkipFirst: ParserPrinter where P0: ParserPrinter, P1: ParserPrinter {
    @inlinable public func print(_ output: P1.Output, into input: inout RFC_3986.URI.Request.Data) rethrows {
        try self.p1.print(output, into: &input)
        try self.p0.print((), into: &input)
    }
}

extension RFC_3986.URI.Path.Builder.SkipSecond: ParserPrinter where P0: ParserPrinter, P1: ParserPrinter {
    @inlinable public func print(_ output: P0.Output, into input: inout RFC_3986.URI.Request.Data) rethrows {
        try self.p1.print((), into: &input)
        try self.p0.print(output, into: &input)
    }
}

extension RFC_3986.URI.Path.Builder.Take2: ParserPrinter where P0: ParserPrinter, P1: ParserPrinter {
    @inlinable public func print(_ output: (P0.Output, P1.Output), into input: inout RFC_3986.URI.Request.Data) rethrows {
        try self.p1.print(output.1, into: &input)
        try self.p0.print(output.0, into: &input)
    }
}

// MARK: - Sendable Conformance

/// Sendable conformance for Path.Builder.Component.
///
/// Path builder components are conceptually thread-safe as they are immutable value types
/// with no shared mutable state. However, they are marked as @unchecked Sendable because
/// the generic ComponentParser may contain closures that cannot be verified by the compiler.
///
/// This conformance is safe because:
/// - Component is a struct with immutable fields
/// - All parsing operations are stateless transformations
/// - No shared mutable state exists
/// - Components are building blocks used in path construction
///
/// - Note: Required for Swift 6 strict concurrency mode in server-side applications
/// where routing types must cross actor boundaries.
extension RFC_3986.URI.Path.Builder.Component: @unchecked Sendable where ComponentParser: Sendable {}
