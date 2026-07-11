import RFC_3986

// MARK: - RFC 3986 URI Route

extension RFC_3986.URI {
    /// A parser that attempts to run a number of parsers to accumulate output associated with a
    /// particular URI endpoint.
    ///
    /// `RFC_3986.URI.Route` is a domain-specific version of `Parse`, suited to RFC-compliant URI routing.
    public struct Route<Parsers: Parser.`Protocol`>: Parser.`Protocol` where Parsers.Input == RFC_3986.URI.Request.Data {
        public typealias Failure = RFC_3986.URI.Routing.Error

        @usableFromInline
        let parsers: Parsers

        @inlinable
        public init<Upstream, NewOutput>(
            _ transform: @escaping (Upstream.Output) -> NewOutput,
            @Parser.Builder<RFC_3986.URI.Request.Data> with build: () -> Upstream
        )
        where
            Upstream.Input == RFC_3986.URI.Request.Data,
            Parsers == Parser.Map<Upstream, NewOutput> {
            self.parsers = build().map(transform)
        }

        @inlinable
        public init<Upstream, NewOutput>(
            _ transform: @escaping (Upstream.Output) -> NewOutput,
            @Parser.Builder<RFC_3986.URI.Request.Data> with build: () throws -> Upstream
        ) rethrows
        where
            Upstream.Input == RFC_3986.URI.Request.Data,
            Parsers == Parser.Map<Upstream, NewOutput> {
            self.parsers = try build().map(transform)
        }

        @_disfavoredOverload
        @inlinable
        public init<Upstream, NewOutput: Equatable>(
            _ output: NewOutput,
            @Parser.Builder<RFC_3986.URI.Request.Data> with build: () -> Upstream
        )
        where
            Upstream.Input == RFC_3986.URI.Request.Data,
            Upstream.Output == Void,
            Parsers == Parser.Converted<Upstream, Parser.Conversion.Fixed<NewOutput>> {
            self.parsers = build().map(.fixed(output))
        }

        @_disfavoredOverload
        @inlinable
        public init<Upstream, NewOutput: Equatable>(
            _ output: NewOutput,
            @Parser.Builder<RFC_3986.URI.Request.Data> with build: () throws -> Upstream
        ) rethrows
        where
            Upstream.Input == RFC_3986.URI.Request.Data,
            Upstream.Output == Void,
            Parsers == Parser.Converted<Upstream, Parser.Conversion.Fixed<NewOutput>> {
            self.parsers = try build().map(.fixed(output))
        }

        @inlinable
        public init<NewOutput: Equatable>(
            _ output: NewOutput
        )
        where
            Parsers == Parser.Converted<Parser.Always<RFC_3986.URI.Request.Data, Void>, Parser.Conversion.Fixed<NewOutput>> {
            self.init(output) {
                Parser.Always<RFC_3986.URI.Request.Data, Void>(())
            }
        }

        @inlinable
        public init<C: Parser.Conversion.`Protocol`, P: Parser.`Protocol`>(
            _ conversion: C,
            @Parser.Builder<RFC_3986.URI.Request.Data> with parsers: () -> P
        )
        where
            P.Input == RFC_3986.URI.Request.Data,
            C.Input == P.Output,
            Parsers == Parser.Converted<P, C> {
            self.parsers = parsers().map(conversion)
        }

        @_disfavoredOverload
        @inlinable
        public init<C: Parser.Conversion.`Protocol`, P: Parser.`Protocol`>(
            _ conversion: C,
            @Parser.Builder<RFC_3986.URI.Request.Data> with parsers: () throws -> P
        ) rethrows
        where
            P.Input == RFC_3986.URI.Request.Data,
            C.Input == P.Output,
            Parsers == Parser.Converted<P, C> {
            self.parsers = try parsers().map(conversion)
        }

        @inlinable
        public init<C: Parser.Conversion.`Protocol`>(
            _ conversion: C
        ) where
            C.Input == Void,
            Parsers == Parser.Converted<Parser.Always<RFC_3986.URI.Request.Data, Void>, C> {
            self.init(conversion) {
                Parser.Always<RFC_3986.URI.Request.Data, Void>(())
            }
        }

        @inlinable
        public func parse(
            _ input: inout RFC_3986.URI.Request.Data
        ) throws(RFC_3986.URI.Routing.Error) -> Parsers.Output {
            let output: Parsers.Output
            do {
                output = try self.parsers.parse(&input)
            } catch {
                throw RFC_3986.URI.Routing.Error(component: .request, failure: .parseFailed("\(error)"))
            }
            if input.method != nil {
                try Method.get.parse(&input)
            }
            var pathEndInput = input
            try RFC_3986.URI.PathEnd().parse(&pathEndInput)
            return output
        }
    }
}

extension RFC_3986.URI.Route: Parser.Printer, Parser.Bidirectional where Parsers: Parser.Bidirectional {
    @inlinable
    public func print(
        _ output: Parsers.Output,
        into input: inout RFC_3986.URI.Request.Data
    ) throws(RFC_3986.URI.Routing.Error) {
        do {
            try self.parsers.print(output, into: &input)
        } catch {
            throw RFC_3986.URI.Routing.Error(component: .request, failure: .parseFailed("\(error)"))
        }
    }
}

extension RFC_3986.URI {
    @usableFromInline
    struct PathEnd: Parser.Bidirectional {
        @usableFromInline
        typealias Input = RFC_3986.URI.Request.Data
        @usableFromInline
        typealias Output = Void
        @usableFromInline
        typealias Failure = RFC_3986.URI.Routing.Error

        @inlinable
        init() {}

        @inlinable
        func parse(_ input: inout RFC_3986.URI.Request.Data) throws(RFC_3986.URI.Routing.Error) {
            guard var first = input.path.first else { return }
            do {
                try Parser.End().parse(&first)
            } catch {
                throw RFC_3986.URI.Routing.Error(
                    component: .path,
                    failure: .invalid("Path component not fully consumed"),
                    context: "\(error)"
                )
            }
        }

        @inlinable
        func print(_ output: Void, into input: inout RFC_3986.URI.Request.Data) throws(RFC_3986.URI.Routing.Error) {
            guard var first = input.path.first else { return }
            Parser.End().print((), into: &first)
        }
    }
}

// MARK: - Convenience Type Aliases

/// Convenience type alias for `RFC_3986.URI.Route`
///
/// For cleaner code, you can use `URIRoute` instead of `RFC_3986.URI.Route`:
/// ```swift
/// URIRoute(.case(\.home)) {
///   Path { "home" }
/// }
/// ```
public typealias URIRoute = RFC_3986.URI.Route

/// Convenience type alias for `RFC_3986.URI.Route`
///
/// For cleaner code, you can use `Route` instead of `RFC_3986.URI.Route`:
/// ```swift
/// Route(.case(\.home)) {
///   Path { "home" }
/// }
/// ```
public typealias Route = RFC_3986.URI.Route

/// Convenience type alias for `URIPath`
public typealias Path = URIPath

/// Convenience type alias for `URIQuery`
public typealias Query = URIQuery

/// Convenience type alias for `URIScheme`
public typealias Scheme = URIScheme

/// Convenience type alias for `URIHost`
public typealias Host = URIHost

// MARK: - Sendable Conformance

/// Sendable conformance for URI.Route.
///
/// URI routes are conceptually thread-safe as they are immutable value types with no
/// shared mutable state. However, they are marked as @unchecked Sendable because the
/// generic Parsers may contain closures that cannot be verified by the compiler.
///
/// This conformance is safe because:
/// - URI.Route is a struct with immutable fields
/// - All parsing operations are stateless transformations
/// - No shared mutable state exists
/// - Routes are composed functionally without side effects
///
/// - Note: Required for Swift 6 strict concurrency mode in server-side applications
/// where routing types must cross actor boundaries.
extension RFC_3986.URI.Route: @unchecked Sendable where Parsers: Sendable {}
