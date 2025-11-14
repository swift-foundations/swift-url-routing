# Migration Plan: Upgrading from pointfreeco/swift-url-routing to coenttb/swift-url-routing

## Status Update (2025-11-14)

**Phase 1 (Critical Features): ✅ COMPLETE**

All critical blocking features for migration have been verified as implemented:
- ✅ OneOf combinator (via swift-parsing re-export)
- ✅ `.map()` with conversions (via swift-parsing re-export)
- ✅ `.eraseToAnyParserPrinter()` (via swift-parsing re-export)
- ✅ `.baseURL()` method (implemented in Printing.swift)
- ✅ All tests passing (47 tests in 8 suites)

New test coverage added:
- OneOfTests.swift (4 tests)
- MapConversionTests.swift (4 tests)
- TypeErasureTests.swift (4 tests)

**Next Steps**: Ready for Phase 4 (Real-World Validation) - migrate production codebases.

## Executive Summary

This document outlines the migration path for upgrading from pointfreeco's swift-url-routing to the RFC-first implementation in coenttb/swift-url-routing. Based on analysis of two production codebases (swift-identities-types and repotraffic-com-server), we've identified critical features and improvements needed.

## Current Usage Analysis

### Analyzed Codebases
1. **swift-identities-types**: Identity/authentication framework with feature-based routing
2. **repotraffic-com-server**: Production SaaS application with complex multi-domain routing

### Common Patterns Found

#### 1. Router Definition Pattern
```swift
public struct Router: ParserPrinter, Sendable {
    public init() {}

    public var body: some URLRouting.Router<Route> {
        OneOf {
            URLRouting.Route(.case(Route.api)) {
                Path { "api" }
                API.Router()
            }
            URLRouting.Route(.case(Route.view)) {
                View.Router()
            }
        }
    }
}
```

#### 2. Nested Router Composition
```swift
URLRouting.Route(.case(Identity.Route.authenticate)) {
    Identity.Authentication.Route.Router()
}

URLRouting.Route(.case(Route.App.repositories)) {
    Path { "repositories" }
    Repository.Route.Router()
}
```

#### 3. Existential Router Types
```swift
public var router: any URLRouting.Router<Identity.Route>
public var router: any ParserPrinter<URLRequestData, Route> & Sendable
```

#### 4. Router Mapping
```swift
router.map(
    .convert(
        apply: \.app,
        unapply: RepoTrafficRouter.Route.app
    )
)
.eraseToAnyParserPrinter()
```

#### 5. Method and Body Parsing
```swift
URLRouting.Route(.case(API.create)) {
    Method.post
    Path { "create" }
    Body(.json(CreateRequest.self))
}
```

## Missing Features in coenttb/swift-url-routing

### Critical (Blocking Migration)

1. ✅ **Method Parser** - IMPLEMENTED
   - Status: Migrated to `RFC_7231.Method.Parser`
   - Type alias: `Method`

2. ✅ **Headers Parser** - IMPLEMENTED
   - Status: Migrated to `RFC_7230.Header.Parser`
   - Type alias: `Headers`

3. ✅ **Body Parser** - IMPLEMENTED
   - Status: Migrated to `RFC_7230.Body.Parser`
   - Type alias: `Body`
   - Includes `.json()` conversion support

4. ✅ **Path Elements** - IMPLEMENTED
   - Status: Migrated to `RFC_3986.URI.Path.Parser`
   - Type alias: `Path`

5. ✅ **Query Parser** - IMPLEMENTED
   - Status: Migrated to `RFC_3986.URI.Query.Parser`
   - Type alias: `Query`

6. ⚠️ **Type Aliases** - PARTIALLY ADDRESSED
   - Current: Aliases exist but user wants to avoid using them internally
   - Action: Keep aliases for end-user convenience, use full names internally

7. ✅ **`.map()` with Conversions** - IMPLEMENTED
   - Status: Available via `@_exported import Parsing`
   - Example: `router.map(.convert(apply: \.app, unapply: Route.app))`
   - Source: swift-parsing library (re-exported)
   - Tests: Added MapConversionTests.swift (4 tests, all passing)

8. ✅ **`.eraseToAnyParserPrinter()`** - IMPLEMENTED
   - Status: Available via `@_exported import Parsing`
   - Allows: `any ParserPrinter<URLRequestData, Route>`
   - Pattern: Type erasure for protocol conformance
   - Tests: Added TypeErasureTests.swift (4 tests, all passing)

9. ✅ **OneOf Combinator** - IMPLEMENTED
   - Status: Available via `@_exported import Parsing`
   - Pattern: `OneOf { Route1; Route2; Route3 }`
   - Source: swift-parsing library (re-exported)
   - Tests: Added OneOfTests.swift (4 tests, all passing)

10. ✅ **`.baseURL()` Method** - IMPLEMENTED
    - Status: Implemented in Sources/URLRouting/Printing.swift
    - Pattern: `router.baseURL("https://api.example.com")`
    - Implementation: BaseURLPrinter struct with full support
    - Tests: Existing test "Base URL routing" passes

### Important (Needed for Feature Parity)

11. ❌ **`Route` Combinator** - NEEDS REVIEW
    - Current: `URIRoute` exists
    - Pattern: `URLRouting.Route(.case(...))`
    - Action: Verify compatibility with pointfreeco patterns

12. ❌ **`@CasePathable` Support** - DEPENDENCY
    - Dependency: swift-case-paths
    - Used extensively in route enums
    - Status: Package.swift already includes it

13. ❌ **FormData Parser** - IMPLEMENTED
    - Status: Migrated to `HTML.FormData.Parser`
    - Type alias: `FormData`

14. ❌ **Cookies Parser** - IMPLEMENTED
    - Status: Migrated to `RFC_6265.Cookie.Parser`
    - Type alias: `Cookies`

### Nice to Have (Quality of Life)

15. ❌ **Router Extensions**
    - Pattern: `router.api`, `router.view`
    - Used for extracting sub-routers
    - Improves ergonomics

16. ❌ **Conversion Helpers**
    - Pattern: `.convert(apply:unapply:)`
    - Used with `.map()` for route transformations

## Implementation Plan

### Phase 1: Critical Missing Features (Week 1)

**Goal**: Implement blocking features needed for basic migration

#### Task 1.1: Add OneOf Combinator
- **Location**: Re-export from swift-parsing
- **Files to modify**:
  - `Sources/URLRouting/Exports.swift`
- **Testing**: Verify OneOf works with Route combinators

#### Task 1.2: Add `.map()` Support
- **Location**: Re-export from swift-parsing
- **Approach**: Ensure Parsing's `.map()` works with our parsers
- **Testing**: Test with `.convert()` pattern

#### Task 1.3: Add `.eraseToAnyParserPrinter()`
- **Location**: Extension on `ParserPrinter`
- **Implementation**:
  ```swift
  extension ParserPrinter {
      public func eraseToAnyParserPrinter() -> AnyParserPrinter<Input, Output> {
          AnyParserPrinter(self)
      }
  }
  ```
- **Testing**: Test with existential types

#### Task 1.4: Add `.baseURL()` Method
- **Location**: Extension on `Router` or `ParserPrinter`
- **Pattern**: Adds base URL to all generated URLs
- **Testing**: Test URL generation with base URLs

### Phase 2: Router Enhancements (Week 2)

**Goal**: Add features for advanced routing patterns

#### Task 2.1: Review Route Combinator
- **Action**: Ensure `URIRoute` matches pointfreeco's `Route` behavior
- **Pattern**: `URLRouting.Route(.case(...))`
- **Testing**: Compare behavior with pointfreeco version

#### Task 2.2: Add Router Mapping Helpers
- **Location**: Extensions on `Router` or `ParserPrinter`
- **Features**:
  - `.map(.convert(apply:unapply:))`
  - Router composition utilities
- **Testing**: Test nested router scenarios

#### Task 2.3: Add Conversion Types
- **Location**: New file `Sources/URLRouting/Conversions.swift`
- **Implementation**: Conversion protocol and helpers
- **Testing**: Test with real conversion scenarios

### Phase 3: Convenience & Ergonomics (Week 3)

**Goal**: Match pointfreeco's ergonomics and developer experience

#### Task 3.1: Add Router Extensions
- **Pattern**: `router.api`, `router.view` extractors
- **Implementation**: Extensions on Router protocol
- **Testing**: Test sub-router extraction

#### Task 3.2: Documentation & Examples
- **Location**: `README.md`, doc comments
- **Content**:
  - Migration guide
  - Side-by-side examples
  - Breaking changes list
- **Testing**: Verify examples compile and run

#### Task 3.3: Add Migration Tests
- **Location**: `Tests/URLRoutingTests/MigrationTests.swift`
- **Content**:
  - Test pointfreeco patterns
  - Verify RFC patterns still work
  - Test mixed usage
- **Testing**: All migration scenarios pass

### Phase 4: Real-World Validation (Week 4)

**Goal**: Validate migration in production codebases

#### Task 4.1: Migrate swift-identities-types
- **Approach**: Create migration branch
- **Steps**:
  1. Update Package.swift dependency
  2. Update imports
  3. Run tests
  4. Fix any issues
- **Success**: All tests pass

#### Task 4.2: Migrate repotraffic-com-server (subset)
- **Approach**: Migrate one domain as proof-of-concept
- **Target**: Choose smaller domain (e.g., Analytics or Checkout)
- **Steps**:
  1. Update dependency
  2. Migrate chosen domain
  3. Run tests
  4. Document issues
- **Success**: Domain migrates successfully

#### Task 4.3: Create Migration Guide
- **Location**: `MIGRATION_GUIDE.md`
- **Content**:
  - Step-by-step instructions
  - Common issues and solutions
  - API differences table
  - Before/after examples
- **Audience**: Developers migrating from pointfreeco

## Breaking Changes

### Expected Breaking Changes

1. **Internal Type Names**
   - Old: `Method`, `Headers`, `Body` (standalone types)
   - New: `RFC_7231.Method.Parser`, `RFC_7230.Header.Parser`, etc.
   - **Impact**: Low (type aliases provide backward compatibility)

2. **RFC Package Dependencies**
   - **New**: Requires swift-rfc-6265, swift-rfc-7230, swift-rfc-7231
   - **Impact**: Medium (need to add dependencies)

3. **Import Changes**
   - Old: `import URLRouting`
   - New: `import URLRouting` + RFC package imports if using qualified names
   - **Impact**: Low (handled by transitive dependencies)

### Non-Breaking Additions

1. **RFC-First Architecture**
   - Benefit: Clear standards association
   - Impact: None (type aliases maintain compatibility)

2. **Swift 6.2 Features**
   - Benefit: Better concurrency support
   - Impact: None (Swift 6.2 is backward compatible)

3. **Swift Testing**
   - Benefit: Modern testing framework
   - Impact: None for consumers (internal change)

## Success Criteria

### Phase 1 Success
- ✅ OneOf combinator works
- ✅ `.map()` with conversions works
- ✅ `.eraseToAnyParserPrinter()` works
- ✅ `.baseURL()` method works
- ✅ All existing tests pass

### Phase 2 Success
- ✅ Route combinator matches pointfreeco behavior
- ✅ Router mapping works
- ✅ Conversion helpers implemented
- ✅ New tests for router features pass

### Phase 3 Success
- ✅ Router extensions work
- ✅ Documentation complete
- ✅ Migration tests pass
- ✅ Examples compile and run

### Phase 4 Success
- ✅ swift-identities-types migrates successfully
- ✅ One domain in repotraffic-com-server migrates
- ✅ Migration guide written and validated
- ✅ No regressions in functionality

## Timeline

- **Week 1**: Phase 1 (Critical Features)
- **Week 2**: Phase 2 (Router Enhancements)
- **Week 3**: Phase 3 (Convenience & Ergonomics)
- **Week 4**: Phase 4 (Real-World Validation)

**Total**: 4 weeks for complete migration readiness

## Next Steps

1. **Immediate**: Start Phase 1, Task 1.1 (OneOf Combinator)
2. **Today**: Complete Task 1.1 and 1.2
3. **This Week**: Complete entire Phase 1
4. **Next Week**: Begin Phase 2

## Notes

- User preference: Avoid type aliases internally, use full RFC qualified names
- Keep type aliases for end-user convenience
- Maintain 100% test coverage
- Use Swift Testing framework throughout
- All RFC packages need to be published before final migration
