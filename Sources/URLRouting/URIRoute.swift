/// A parser that attempts to run a number of parsers to accumulate output associated with a
/// particular URI endpoint.
///
/// `URIRoute` is a domain-specific version of `Parse`, suited to RFC-compliant URI routing.
public struct URIRoute<Parsers: Parser>: Parser where Parsers.Input == URIRequestData {
  @usableFromInline
  let parsers: Parsers

  @inlinable
  public init<Upstream, NewOutput>(
    _ transform: @escaping (Upstream.Output) -> NewOutput,
    @ParserBuilder<URIRequestData> with build: () -> Upstream
  )
  where
    Upstream.Input == URIRequestData,
    Parsers == Parsing.Parsers.Map<Upstream, NewOutput>
  {
    self.parsers = build().map(transform)
  }

  @_disfavoredOverload
  @inlinable
  public init<Upstream, NewOutput>(
    _ output: NewOutput,
    @ParserBuilder<URIRequestData> with build: () -> Upstream
  )
  where
    Upstream.Input == URIRequestData,
    Parsers == Parsing.Parsers.MapConstant<Upstream, NewOutput>
  {
    self.parsers = build().map { output }
  }

  @inlinable
  public init<NewOutput>(
    _ output: NewOutput
  )
  where
    Parsers == Parsing.Parsers.MapConstant<Always<URIRequestData, Void>, NewOutput>
  {
    self.init(output) {
      Always<URIRequestData, Void>(())
    }
  }

  @inlinable
  public init<C: Conversion, P: Parser>(
    _ conversion: C,
    @ParserBuilder<URIRequestData> with parsers: () -> P
  )
  where
    P.Input == URIRequestData,
    Parsers == Parsing.Parsers.MapConversion<P, C>
  {
    self.parsers = parsers().map(conversion)
  }

  @inlinable
  public init<C: Conversion>(
    _ conversion: C
  ) where Parsers == Parsing.Parsers.MapConversion<Always<URIRequestData, Void>, C> {
    self.init(conversion) {
      Always<URIRequestData, Void>(())
    }
  }

  @inlinable
  public func parse(_ input: inout URIRequestData) throws -> Parsers.Output {
    let output = try self.parsers.parse(&input)
    if input.method != nil {
      try Method.get.parse(&input)
    }
    try URIPathEnd().parse(input)
    return output
  }
}

extension URIRoute: ParserPrinter where Parsers: ParserPrinter {
  @inlinable
  public func print(_ output: Parsers.Output, into input: inout URIRequestData) rethrows {
    try self.parsers.print(output, into: &input)
  }
}

@usableFromInline
struct URIPathEnd: ParserPrinter {
  @inlinable
  public init() {}

  @inlinable
  public func parse(_ input: inout URIRequestData) throws {
    guard var first = input.path.first else { return }
    try End().parse(&first)
  }

  @inlinable
  public func print(_ output: (), into input: inout Input) throws {
    guard var first = input.path.first else { return }
    try End().print((), into: &first)
  }
}

extension URIPathEnd {
  @usableFromInline typealias Input = URIRequestData
}

// Type aliases for convenience
public typealias Route = URIRoute
public typealias Path = URIPath
public typealias Query = URIQuery
public typealias Scheme = URIScheme
public typealias Host = URIHost
