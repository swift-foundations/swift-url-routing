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
        public static func buildPartialBlock<P: Parser_Primitive.Parser.`Protocol`>(first: P) -> P
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
        public static func buildPartialBlock<P0: Parser_Primitive.Parser.`Protocol`, P1: Parser_Primitive.Parser.`Protocol`, each O1, O2>(
            accumulated: P0,
            next: P1
        ) -> Parser_Primitive.Parser.Map<Take2<P0, P1>, (repeat each O1, O2)>
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
        public static func buildExpression<P: Parser_Primitive.Parser.`Protocol`>(_ parser: P) -> Component<P> where P.Input == Substring {
            Component(parser)
        }

        public struct Component<ComponentParser: Parser_Primitive.Parser.`Protocol`>: Parser_Primitive.Parser.`Protocol`
        where ComponentParser.Input == Substring {
            public typealias Failure = RFC_3986.URI.Routing.Error

            @usableFromInline
            let componentParser: ComponentParser

            @usableFromInline
            init(_ componentParser: ComponentParser) {
                self.componentParser = componentParser
            }

            @inlinable
            public func parse(
                _ input: inout RFC_3986.URI.Request.Data
            ) throws(RFC_3986.URI.Routing.Error) -> ComponentParser.Output {
                guard input.path.count >= 1 else {
                    throw RFC_3986.URI.Routing.Error(
                        component: .path,
                        failure: .invalid("Path is too short"),
                        context: "Expected at least 1 component, got \(input.path.count)"
                    )
                }
                var component = input.path.removeFirst()
                do {
                    return try self.componentParser.parse(&component)
                } catch {
                    throw RFC_3986.URI.Routing.Error(
                        component: .path,
                        failure: .parseFailed("\(error)")
                    )
                }
            }
        }
    }
}

extension RFC_3986.URI.Path.Builder.Component: Parser_Primitive.Parser.Bidirectional where ComponentParser: Parser_Primitive.Parser.Bidirectional {
    @inlinable
    public func print(
        _ output: ComponentParser.Output,
        into input: inout RFC_3986.URI.Request.Data
    ) throws(RFC_3986.URI.Routing.Error) {
        do {
            try input.path.prepend(self.componentParser.print(output))
        } catch {
            throw RFC_3986.URI.Routing.Error(
                component: .path,
                failure: .parseFailed("\(error)")
            )
        }
    }
}

// MARK: - Helper Types for buildPartialBlock

extension RFC_3986.URI.Path.Builder {
    public struct SkipFirst<P0: Parser_Primitive.Parser.`Protocol`, P1: Parser_Primitive.Parser.`Protocol`>: Parser_Primitive.Parser.`Protocol`
    where P0.Input == RFC_3986.URI.Request.Data, P1.Input == RFC_3986.URI.Request.Data, P0.Output == Void {
        public typealias Failure = RFC_3986.URI.Routing.Error

        @usableFromInline let p0: P0, p1: P1

        @usableFromInline init(_ p0: P0, _ p1: P1) {
            self.p0 = p0
            self.p1 = p1
        }

        @inlinable public func parse(
            _ input: inout RFC_3986.URI.Request.Data
        ) throws(RFC_3986.URI.Routing.Error) -> P1.Output {
            do {
                try self.p0.parse(&input)
                return try self.p1.parse(&input)
            } catch {
                throw RFC_3986.URI.Routing.Error(component: .path, failure: .parseFailed("\(error)"))
            }
        }
    }

    public struct SkipSecond<P0: Parser_Primitive.Parser.`Protocol`, P1: Parser_Primitive.Parser.`Protocol`>: Parser_Primitive.Parser.`Protocol`
    where P0.Input == RFC_3986.URI.Request.Data, P1.Input == RFC_3986.URI.Request.Data, P1.Output == Void {
        public typealias Failure = RFC_3986.URI.Routing.Error

        @usableFromInline let p0: P0, p1: P1

        @usableFromInline init(_ p0: P0, _ p1: P1) {
            self.p0 = p0
            self.p1 = p1
        }

        @inlinable public func parse(
            _ input: inout RFC_3986.URI.Request.Data
        ) throws(RFC_3986.URI.Routing.Error) -> P0.Output {
            do {
                let o0 = try self.p0.parse(&input)
                try self.p1.parse(&input)
                return o0
            } catch {
                throw RFC_3986.URI.Routing.Error(component: .path, failure: .parseFailed("\(error)"))
            }
        }
    }

    public struct Take2<P0: Parser_Primitive.Parser.`Protocol`, P1: Parser_Primitive.Parser.`Protocol`>: Parser_Primitive.Parser.`Protocol`
    where P0.Input == RFC_3986.URI.Request.Data, P1.Input == RFC_3986.URI.Request.Data {
        public typealias Failure = RFC_3986.URI.Routing.Error

        @usableFromInline let p0: P0, p1: P1

        @usableFromInline init(_ p0: P0, _ p1: P1) {
            self.p0 = p0
            self.p1 = p1
        }

        @inlinable public func parse(
            _ input: inout RFC_3986.URI.Request.Data
        ) throws(RFC_3986.URI.Routing.Error) -> (P0.Output, P1.Output) {
            do {
                let o0 = try self.p0.parse(&input)
                let o1 = try self.p1.parse(&input)
                return (o0, o1)
            } catch {
                throw RFC_3986.URI.Routing.Error(component: .path, failure: .parseFailed("\(error)"))
            }
        }
    }
}

extension RFC_3986.URI.Path.Builder.SkipFirst: Parser_Primitive.Parser.Bidirectional where P0: Parser_Primitive.Parser.Bidirectional, P1: Parser_Primitive.Parser.Bidirectional {
    @inlinable public func print(
        _ output: P1.Output,
        into input: inout RFC_3986.URI.Request.Data
    ) throws(RFC_3986.URI.Routing.Error) {
        do {
            try self.p1.print(output, into: &input)
            try self.p0.print((), into: &input)
        } catch {
            throw RFC_3986.URI.Routing.Error(component: .path, failure: .parseFailed("\(error)"))
        }
    }
}

extension RFC_3986.URI.Path.Builder.SkipSecond: Parser_Primitive.Parser.Bidirectional where P0: Parser_Primitive.Parser.Bidirectional, P1: Parser_Primitive.Parser.Bidirectional {
    @inlinable public func print(
        _ output: P0.Output,
        into input: inout RFC_3986.URI.Request.Data
    ) throws(RFC_3986.URI.Routing.Error) {
        do {
            try self.p1.print((), into: &input)
            try self.p0.print(output, into: &input)
        } catch {
            throw RFC_3986.URI.Routing.Error(component: .path, failure: .parseFailed("\(error)"))
        }
    }
}

extension RFC_3986.URI.Path.Builder.Take2: Parser_Primitive.Parser.Bidirectional where P0: Parser_Primitive.Parser.Bidirectional, P1: Parser_Primitive.Parser.Bidirectional {
    @inlinable public func print(
        _ output: (P0.Output, P1.Output),
        into input: inout RFC_3986.URI.Request.Data
    ) throws(RFC_3986.URI.Routing.Error) {
        do {
            try self.p1.print(output.1, into: &input)
            try self.p0.print(output.0, into: &input)
        } catch {
            throw RFC_3986.URI.Routing.Error(component: .path, failure: .parseFailed("\(error)"))
        }
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
