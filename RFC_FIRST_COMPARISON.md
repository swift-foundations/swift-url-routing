# RFC-First vs Current Implementation: Side-by-Side

## Example: Books API Router

### Current Implementation (pointfreeco/swift-url-routing)

```swift
import Foundation
import URLRouting

enum BooksRoute {
  case list
  case detail(id: Int)
  case search(query: String, page: Int)
}

let booksRouter = OneOf {
  // GET /books
  Route(.case(BooksRoute.list)) {
    Method.get
    Path { "books" }
  }

  // GET /books/:id
  Route(.case(BooksRoute.detail(id:))) {
    Method.get
    Path {
      "books"
      Digits()
    }
  }

  // GET /books/search?q=:query&page=:page
  Route(.case(BooksRoute.search(query:page:))) {
    Method.get
    Path { "books"; "search" }
    Query {
      Field("q")
      Field("page", default: 1) { Digits() }
    }
  }
}

// Usage: Parse Foundation URL
let url = URL(string: "https://api.example.com/books/42")!
let request = URLRequest(url: url)
let requestData = URLRequestData(request: request)!
let route = try booksRouter.parse(requestData)
// Result: BooksRoute.detail(id: 42)

// Usage: Print to Foundation URL
let requestData = try booksRouter.print(.search(query: "swift", page: 1))
let urlRequest = URLRequest(data: requestData)!
```

---

### RFC-First Implementation

```swift
import RFC_3986
import RFC_6570
import URLRouting  // Our new RFC-first version

enum BooksRoute {
  case list
  case detail(id: Int)
  case search(query: String, page: Int)
}

// Option 1: Traditional Parser Builder (same as before, but RFC-native)
let booksRouter = OneOf {
  // GET /books
  Route(.case(BooksRoute.list)) {
    Method.get
    Path { "books" }
  }

  // GET /books/:id
  Route(.case(BooksRoute.detail(id:))) {
    Method.get
    Path {
      "books"
      Digits()
    }
  }

  // GET /books/search?q=:query&page=:page
  Route(.case(BooksRoute.search(query:page:))) {
    Method.get
    Path { "books"; "search" }
    Query {
      Field("q")
      Field("page", default: 1) { Digits() }
    }
  }
}

// Option 2: Template-First (NEW! using RFC 6570)
let booksRouterTemplate = OneOf {
  // GET /books
  Template("/books", .case(BooksRoute.list))

  // GET /books/{id}
  Template("/books/{id}", .case(BooksRoute.detail(id:)))

  // GET /books/search?q={query}&page={page}
  Template("/books/search{?q,page}", .case(BooksRoute.search(query:page:)))
}

// Usage: Parse RFC 3986 URI (no Foundation!)
let uri = try RFC_3986.URI("/books/42")
let route = try booksRouter.match(uri: uri)
// Result: BooksRoute.detail(id: 42)

// Usage: Print to RFC 3986 URI
let uri = try booksRouter.uri(for: .search(query: "swift", page: 1))
// Result: RFC_3986.URI("/books/search?q=swift&page=1")

// Foundation bridge (optional, for compatibility)
let url = try URL(uri: uri)
```

---

## Key Differences

### 1. Input/Output Types

| Current | RFC-First |
|---------|-----------|
| `URLRequestData` | `URIRequestData` |
| Foundation `URL` | `RFC_3986.URI` |
| Foundation `URLRequest` | `URIRequestData` |
| String parsing via Foundation | Direct RFC 3986 parsing |

### 2. Template Support

**Current: No template support**
```swift
// Must manually construct path parsers
Path {
  "books"
  Digits()  // Parse integer
}
```

**RFC-First: Template-native**
```swift
// Use RFC 6570 template syntax
Template("/books/{id}")

// Complex templates work out of the box
Template("/search{?q,page,limit}")
Template("/users/{user}/repos{/repo*}")
```

### 3. Percent-Encoding

**Current: Foundation URLComponents**
- Foundation's encoding has quirks
- Not always RFC 3986 compliant
- Inconsistent across platforms

**RFC-First: RFC 3986 rules**
- Always RFC compliant
- Predictable behavior
- Works everywhere Swift works

### 4. Type Safety

**Current:**
```swift
// URL is stringly-typed
let url = URL(string: "not a valid url?")  // nil
let url = URL(string: "https://example.com")  // URL?
```

**RFC-First:**
```swift
// URI is validated at construction
let uri = try RFC_3986.URI("/valid/path")  // URI (throws on invalid)
let uri = RFC_3986.URI(unchecked: "...")   // Trusted sources
```

---

## Advanced Example: API with Authentication

### Current Implementation

```swift
enum APIRoute {
  case books(auth: String)
  case book(id: Int, auth: String)
}

let apiRouter = OneOf {
  Route(.case(APIRoute.books(auth:))) {
    Method.get
    Path { "books" }
    Headers {
      Field("Authorization")  // Bearer token
    }
  }

  Route(.case(APIRoute.book(id:auth:))) {
    Method.get
    Path {
      "books"
      Digits()
    }
    Headers {
      Field("Authorization")
    }
  }
}
```

### RFC-First with Template

```swift
enum APIRoute {
  case books(auth: BearerToken)
  case book(id: Int, auth: BearerToken)
}

// Define bearer token type (RFC 6750)
struct BearerToken: RawRepresentable {
  let rawValue: String
}

let apiRouter = OneOf {
  // Use template for path, traditional parser for headers
  Template("/books") {
    Headers {
      Field("Authorization", .bearerToken)  // RFC 6750 parser
    }
  }
  .map(.case(APIRoute.books(auth:)))

  Template("/books/{id}") {
    Headers {
      Field("Authorization", .bearerToken)
    }
  }
  .map(.case(APIRoute.book(id:auth:)))
}

// Future: Could support header templates too!
// Template("/books", headers: ["Authorization": "Bearer {token}"])
```

---

## Template Matching Deep Dive

### The Challenge

RFC 6570 defines expansion (route → URI) but not matching (URI → route).

**Example:**
```swift
let template = try RFC_6570.Template("/users/{id}/posts/{postId}")

// Expansion: Easy ✓
let uri = try template.expand(["id": "123", "postId": "456"])
// Result: "/users/123/posts/456"

// Matching: Hard! (Not defined in RFC)
let variables = try template.match("/users/123/posts/456")
// Should return: ["id": "123", "postId": "456"]
```

### Proposed Solution: Template Compilation

Compile template into a parser at initialization:

```swift
extension RFC_6570.Template {
  /// Generate a parser from the template
  func parser() -> Parser<URIRequestData, [String: String]> {
    // Analyze template syntax
    // Generate parser that extracts variables

    // Example: "/users/{id}/posts/{postId}" becomes:
    Path {
      "users"
      Capture()  // Captures to "id"
      "posts"
      Capture()  // Captures to "postId"
    }
  }
}
```

**Implementation approach:**
1. Parse template into components
2. For each variable expression, generate a `Capture()` parser
3. For each literal, generate a `Literal()` parser
4. Compose into full parser

This gives us:
- **Correctness:** Parser matches template exactly
- **Performance:** Compiled once, used many times
- **Type safety:** Variables are validated

---

## Migration Strategy

### Step 1: Add RFC Bridge to Existing Code

```swift
// Existing code continues to work
let requestData = URLRequestData(request: urlRequest)
let route = try router.parse(requestData)

// New: Can also parse from RFC URI
let uri = try RFC_3986.URI(urlRequest.url!.absoluteString)
let requestData = URIRequestData(uri: uri)
let route = try router.parse(requestData)
```

### Step 2: Gradually Adopt Templates

```swift
// Old style still works
Route(.case(BooksRoute.detail(id:))) {
  Path {
    "books"
    Digits()
  }
}

// New style alongside
Template("/books/{id}", .case(BooksRoute.detail(id:)))
```

### Step 3: Full RFC-First

```swift
// Pure RFC types, no Foundation
let uri = try RFC_3986.URI("/books/42")
let route = try router.match(uri: uri)
let printedURI = try router.uri(for: .detail(id: 42))
```

---

## Performance Comparison

### Current (Foundation-based)

```swift
// Parse URL through Foundation
let url = URL(string: urlString)  // String → URL
let components = URLComponents(url: url, resolvingAgainstBaseURL: false)  // URL → Components
let requestData = URLRequestData(...)  // Components → URLRequestData
let route = try router.parse(requestData)  // URLRequestData → Route
```

**Overhead:**
- Foundation URL parsing
- URLComponents construction
- Multiple allocations
- Foundation encoding quirks

### RFC-First

```swift
// Direct RFC parsing
let uri = try RFC_3986.URI(uriString)  // Validates once
let requestData = URIRequestData(uri: uri)  // Zero-copy when possible
let route = try router.parse(requestData)  // Direct parsing
```

**Benefits:**
- Single validation pass
- Minimal allocations (ArraySlice)
- No Foundation overhead
- Predictable performance

---

## Verdict

**Use RFC-First approach when:**
- Building new routing library from scratch ✓
- Need RFC compliance (APIs, specs)
- Want template-based routing
- Targeting non-Foundation platforms
- Value type safety over convenience

**Keep Current approach when:**
- Existing codebase with Foundation
- Need Foundation URL compatibility
- Tight Foundation integration

**Best of both worlds:**
- Build core as RFC-first
- Provide Foundation bridge
- Let users choose
