import Parsing
import RFC_3986

// MARK: - RFC 3986 URI Route

extension RFC_3986.URI {
    /// A parser that attempts to run a number of parsers to accumulate output associated with a
    /// particular URI endpoint.
    ///
    /// `RFC_3986.URI.Route` is a domain-specific version of `Parse`, suited to RFC-compliant URI routing.
    public struct Route<Parsers: Parser>: Parser where Parsers.Input == RFC_3986.URI.Request.Data {
        @usableFromInline
        let parsers: Parsers

        @inlinable
        public init<Upstream, NewOutput>(
            _ transform: @escaping (Upstream.Output) -> NewOutput,
            @ParserBuilder<RFC_3986.URI.Request.Data> with build: () -> Upstream
        )
        where
            Upstream.Input == RFC_3986.URI.Request.Data,
            Parsers == Parsing.Parsers.Map<Upstream, NewOutput> {
            self.parsers = build().map(transform)
        }

        @inlinable
        public init<Upstream, NewOutput>(
            _ transform: @escaping (Upstream.Output) -> NewOutput,
            @ParserBuilder<RFC_3986.URI.Request.Data> with build: () throws -> Upstream
        ) rethrows
        where
            Upstream.Input == RFC_3986.URI.Request.Data,
            Parsers == Parsing.Parsers.Map<Upstream, NewOutput> {
            self.parsers = try build().map(transform)
        }

        @_disfavoredOverload
        @inlinable
        public init<Upstream, NewOutput>(
            _ output: NewOutput,
            @ParserBuilder<RFC_3986.URI.Request.Data> with build: () -> Upstream
        )
        where
            Upstream.Input == RFC_3986.URI.Request.Data,
            Parsers == Parsing.Parsers.MapConstant<Upstream, NewOutput> {
            self.parsers = build().map { output }
        }

        @_disfavoredOverload
        @inlinable
        public init<Upstream, NewOutput>(
            _ output: NewOutput,
            @ParserBuilder<RFC_3986.URI.Request.Data> with build: () throws -> Upstream
        ) rethrows
        where
            Upstream.Input == RFC_3986.URI.Request.Data,
            Parsers == Parsing.Parsers.MapConstant<Upstream, NewOutput> {
            self.parsers = try build().map { output }
        }

        @inlinable
        public init<NewOutput>(
            _ output: NewOutput
        )
        where
            Parsers == Parsing.Parsers.MapConstant<Always<RFC_3986.URI.Request.Data, Void>, NewOutput> {
            self.init(output) {
                Always<RFC_3986.URI.Request.Data, Void>(())
            }
        }

        @inlinable
        public init<C: Conversion, P: Parser>(
            _ conversion: C,
            @ParserBuilder<RFC_3986.URI.Request.Data> with parsers: () -> P
        )
        where
            P.Input == RFC_3986.URI.Request.Data,
            Parsers == Parsing.Parsers.MapConversion<P, C> {
            self.parsers = parsers().map(conversion)
        }

        @inlinable
        public init<C: Conversion, P: Parser>(
            _ conversion: C,
            @ParserBuilder<RFC_3986.URI.Request.Data> with parsers: () throws -> P
        ) rethrows
        where
            P.Input == RFC_3986.URI.Request.Data,
            Parsers == Parsing.Parsers.MapConversion<P, C> {
            self.parsers = try parsers().map(conversion)
        }

        @inlinable
        public init<C: Conversion>(
            _ conversion: C
        ) where Parsers == Parsing.Parsers.MapConversion<Always<RFC_3986.URI.Request.Data, Void>, C> {
            self.init(conversion) {
                Always<RFC_3986.URI.Request.Data, Void>(())
            }
        }

        @inlinable
        public func parse(_ input: inout RFC_3986.URI.Request.Data) throws -> Parsers.Output {
            let output = try self.parsers.parse(&input)
            if input.method != nil {
                try Method.get.parse(&input)
            }
            try RFC_3986.URI.PathEnd().parse(input)
            return output
        }
    }
}

extension RFC_3986.URI.Route: ParserPrinter where Parsers: ParserPrinter {
    @inlinable
    public func print(_ output: Parsers.Output, into input: inout RFC_3986.URI.Request.Data) rethrows {
        try self.parsers.print(output, into: &input)
    }
}

extension RFC_3986.URI {
    @usableFromInline
    struct PathEnd: ParserPrinter {
        @inlinable
        init() {}

        @inlinable
        func parse(_ input: inout RFC_3986.URI.Request.Data) throws {
            guard var first = input.path.first else { return }
            try End().parse(&first)
        }

        @inlinable
        func print(_ output: (), into input: inout Input) throws {
            guard var first = input.path.first else { return }
            try End().print((), into: &first)
        }
    }
}

extension RFC_3986.URI.PathEnd {
    @usableFromInline typealias Input = RFC_3986.URI.Request.Data
}

// MARK: - Convenience Type Aliases

/// Convenience type alias for `RFC_3986.URI.Route`
///
/// For cleaner code, you can use `URIRoute` instead of `RFC_3986.URI.Route`:
/// ```swift
/// URIRoute(.case(AppRoute.home)) {
///   Path { "home" }
/// }
/// ```
public typealias URIRoute = RFC_3986.URI.Route

/// Convenience type alias for `RFC_3986.URI.Route`
///
/// For cleaner code, you can use `Route` instead of `RFC_3986.URI.Route`:
/// ```swift
/// Route(.case(AppRoute.home)) {
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
