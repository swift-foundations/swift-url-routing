# RFC-First URL Routing Architecture

## Philosophy

Starting fresh with only:
- `swift-parsing` (parser combinators)
- `swift-rfc-3986` (URI parsing/validation)
- `swift-rfc-6570` (URI templates)

Build a URL routing library that is:
1. **RFC-compliant by default** - Use RFC 3986 types and validation
2. **Template-first** - RFC 6570 templates as the primary routing mechanism
3. **Type-safe** - Leverage Swift's type system with RFC types
4. **Efficient** - Keep incremental parsing with `ArraySlice<Substring>`
5. **Foundation-optional** - Foundation is a bridge, not a dependency

---

## Core Types

### 1. URIRequestData (replaces URLRequestData)

```swift
import RFC_3986
import OrderedCollections

/// A parseable URI request optimized for incremental parsing.
///
/// Models an HTTP request with URI components stored as subsequences
/// for efficient parser consumption.
public struct URIRequestData: Sendable, Equatable {
  // HTTP Method
  public var method: String?

  // URI components (parsed from RFC_3986.URI)
  public var scheme: String?
  public var authority: Authority?
  public var path: Path
  public var query: Query
  public var fragment: String?

  // HTTP-specific
  public var headers: Headers
  public var body: Data?

  /// Authority component (user, host, port)
  public struct Authority: Sendable, Equatable {
    public var userinfo: String?  // user:password
    public var host: String        // Required
    public var port: Int?
  }

  /// Path as array of segments for incremental parsing
  public struct Path: Sendable, Equatable {
    public var segments: ArraySlice<Substring>

    public init(_ segments: ArraySlice<Substring> = []) {
      self.segments = segments
    }
  }

  /// Query as ordered fields for incremental parsing
  public typealias Query = Fields

  /// Headers as ordered fields (case-insensitive)
  public typealias Headers = Fields

  /// Fields for efficient incremental parsing
  public struct Fields: Sendable, Equatable {
    public var fields: OrderedDictionary<String, ArraySlice<Substring?>>
    public var isCaseSensitive: Bool

    public init(
      _ fields: OrderedDictionary<String, ArraySlice<Substring?>> = [:],
      isCaseSensitive: Bool
    ) {
      self.fields = fields
      self.isCaseSensitive = isCaseSensitive
    }
  }
}
```

**Key Differences from URLRequestData:**
- Uses RFC 3986 terminology (`authority` not separate user/host/port)
- `Path` and `Query` are nested types (better namespacing)
- Designed for RFC compliance from the start

---

### 2. URI Parsing (RFC 3986 Integration)

```swift
extension URIRequestData {
  /// Parse from RFC_3986.URI
  public init(uri: RFC_3986.URI, method: String? = nil) throws {
    // Use RFC 3986 parsing rules
    // Parse scheme, authority, path, query, fragment
    // Store as subsequences for efficient parsing
  }

  /// Print to RFC_3986.URI
  public func uri() throws -> RFC_3986.URI {
    // Reconstruct URI from components
    // Use RFC 3986 percent-encoding rules
  }
}
```

---

### 3. Router with RFC Types

```swift
/// A parser-printer that transforms URIs to/from route values
public typealias Router<Output> = ParserPrinter<URIRequestData, Output>

extension Router {
  /// Match a URI to a route
  public func match(uri: RFC_3986.URI) throws -> Output {
    var data = try URIRequestData(uri: uri)
    return try self.parse(&data)
  }

  /// Print a route to a URI
  public func uri(for output: Output) throws -> RFC_3986.URI {
    var data = URIRequestData()
    try self.print(output, into: &data)
    return try data.uri()
  }
}
```

---

## Component Parsers (RFC 3986 Native)

### Path Parser

```swift
/// Parses URI path segments using RFC 3986 rules
public struct Path<ComponentParsers: Parser>: Parser
where ComponentParsers.Input == URIRequestData {
  let componentParsers: ComponentParsers

  public init(@RFC_3986.URI.Path.Builder build: () -> ComponentParsers) {
    self.componentParsers = build()
  }

  public func parse(_ input: inout URIRequestData) rethrows -> ComponentParsers.Output {
    try self.componentParsers.parse(&input)
  }
}

extension Path: ParserPrinter where ComponentParsers: ParserPrinter {
  public func print(_ output: ComponentParsers.Output, into input: inout URIRequestData) rethrows {
    try self.componentParsers.print(output, into: &input)
  }
}
```

### Scheme Parser (RFC 3986 Validated)

```swift
/// Parses URI scheme per RFC 3986 section 3.1
public struct Scheme: ParserPrinter {
  let name: String

  public static let http = Self("http")
  public static let https = Self("https")

  public init(_ name: String) {
    // TODO: Validate scheme per RFC 3986 (ALPHA *( ALPHA / DIGIT / "+" / "-" / "." ))
    self.name = name
  }

  public func parse(_ input: inout URIRequestData) throws {
    guard let scheme = input.scheme, scheme == self.name else {
      throw RoutingError()
    }
    input.scheme = nil
  }

  public func print(_ output: (), into input: inout URIRequestData) {
    input.scheme = self.name
  }
}
```

### Query Parser (RFC 3986 Rules)

```swift
/// Parses query parameters using RFC 3986 encoding
public struct Query<FieldParsers: Parser>: Parser
where FieldParsers.Input == URIRequestData.Fields {
  let fieldParsers: FieldParsers

  public init(@ParserBuilder<URIRequestData.Fields> build: () -> FieldParsers) {
    self.fieldParsers = build()
  }

  public func parse(_ input: inout URIRequestData) rethrows -> FieldParsers.Output {
    try self.fieldParsers.parse(&input.query)
  }
}

extension Query: ParserPrinter where FieldParsers: ParserPrinter {
  public func print(_ output: FieldParsers.Output, into input: inout URIRequestData) rethrows {
    try self.fieldParsers.print(output, into: &input.query)
  }
}
```

---

## RFC 6570 Template Integration

This is the **killer feature** - first-class template support.

### Template-Based Router

```swift
import RFC_6570

/// A router that uses RFC 6570 URI templates
public struct TemplateRouter<Output>: ParserPrinter {
  let template: RFC_6570.Template
  let conversion: Conversion<[String: String], Output>

  public init(
    _ template: String,
    _ conversion: Conversion<[String: String], Output>
  ) throws {
    self.template = try RFC_6570.Template(template)
    self.conversion = conversion
  }

  // Parse: extract variables from URI using template pattern matching
  public func parse(_ input: inout URIRequestData) throws -> Output {
    let uri = try input.uri()

    // TODO: Implement RFC 6570 template matching (reverse operation)
    // This is the hard part - RFC 6570 only defines expansion, not matching
    // We need heuristic-based matching or template pattern analysis
    let variables = try self.template.match(uri: uri)

    return try self.conversion.apply(variables)
  }

  // Print: expand template with variables from output
  public func print(_ output: Output, into input: inout URIRequestData) throws {
    let variables = try self.conversion.unapply(output)
    let uri = try self.template.expand(variables)

    // Merge expanded URI into request data
    let expanded = try URIRequestData(uri: uri)
    input.scheme = expanded.scheme ?? input.scheme
    input.authority = expanded.authority ?? input.authority
    input.path = expanded.path
    input.query = expanded.query
    input.fragment = expanded.fragment
  }
}
```

### Example Usage

```swift
// Define routes as enum
enum AppRoute {
  case books
  case book(id: Int)
  case search(query: String, page: Int)
}

// Define router with templates
let router = OneOf {
  // GET /books
  TemplateRouter("/books", .case(AppRoute.books))

  // GET /books/{id}
  TemplateRouter("/books/{id}", .case(AppRoute.book(id:)))

  // GET /search?q={query}&page={page}
  TemplateRouter("/search{?q,page}", .case(AppRoute.search(query:page:)))
}

// Match URI
let uri = try RFC_3986.URI("/books/42")
let route = try router.match(uri: uri)
// Result: AppRoute.book(id: 42)

// Print URI
let uri = try router.uri(for: .search(query: "swift", page: 1))
// Result: RFC_3986.URI("/search?q=swift&page=1")
```

---

## Advantages Over Current Approach

### 1. **RFC Compliance by Default**
- All parsing/printing uses RFC 3986 rules
- Percent-encoding is always correct
- No Foundation quirks

### 2. **Template-First Routing**
- RFC 6570 templates are expressive and standard
- Bidirectional (parse and print) built-in
- Familiar to API designers

### 3. **Type Safety**
- `RFC_3986.URI` type prevents invalid URIs
- Template variables are type-checked
- Swift's type system enforces correctness

### 4. **Foundation Independence**
- Core library has zero Foundation dependency
- Foundation bridge is optional for compatibility
- Works on all Swift platforms

### 5. **Better Performance**
- Incremental parsing with `ArraySlice<Substring>`
- No redundant validation (RFC types guarantee correctness)
- Template matching can be optimized

---

## Migration Path

### Phase 1: Core Types
1. Define `URIRequestData`
2. RFC 3986 integration (`init(uri:)`, `func uri()`)
3. Basic parsers (Scheme, Path, Query)

### Phase 2: Component Parsers
1. Port existing parsers to `URIRequestData`
2. Add RFC 3986 validation
3. Maintain same API surface

### Phase 3: Template Support
1. Implement RFC 6570 template matching (reverse operation)
2. Add `TemplateRouter` type
3. Examples and documentation

### Phase 4: Foundation Bridge
1. `URIRequestData` ↔ `URLRequest` conversion
2. Backward compatibility layer
3. Migration guide

---

## Open Questions

### 1. Template Matching Algorithm
RFC 6570 only defines expansion (route → URI), not matching (URI → route).

**Options:**
- Heuristic-based matching (parse template syntax, generate regex)
- Explicit route registration with pattern analysis
- Compile-time template analysis with macros

### 2. Authority Component Granularity
Should we expose `authority` as single field or split into `user`, `password`, `host`, `port`?

**Recommendation:** Split for parser convenience, but validate as unit.

### 3. Performance vs Correctness
Should we validate every URI per RFC 3986 or trust parser correctness?

**Recommendation:** Validate on boundaries (input/output), trust internally.

---

## Implementation Priority

1. **High Priority:**
   - `URIRequestData` core type
   - RFC 3986 URI integration
   - Basic parsers (Path, Query, Scheme)
   - Router with URI matching

2. **Medium Priority:**
   - RFC 6570 template expansion in routers
   - Template matching algorithm (v1: simple cases)
   - Foundation bridge

3. **Low Priority:**
   - Advanced template matching
   - Performance optimizations
   - Migration tooling

---

## Conclusion

An RFC-first approach gives us:
- **Correctness** - RFC compliance by construction
- **Expressiveness** - Templates are familiar and powerful
- **Type safety** - Swift types + RFC types = win
- **Foundation independence** - Works everywhere Swift works

The key architectural decision: **Keep incremental parsing model, make it RFC-native.**
