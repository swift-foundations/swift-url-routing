import Testing
import Foundation
import URLRouting

#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif

@Suite("Parser match() Extensions Tests")
struct ParserMatchTests {

    // Multi-value cases carry NO argument labels so the synthesized `Case.Path` tuple
    // matches the builder's unlabeled `(A, B)` output.
    @Cases
    enum TestRoute: Equatable {
        case home
        case user(id: Int)
        case search(query: String)
        case api(String, String)
    }

    struct TestRouter: ParserPrinter {
        var body: some URLRouting.Router<TestRoute> {
            OneOf {
                RFC_3986.URI.Route(.case(TestRoute.cases.home)) {
                    Path { "home" }
                }

                RFC_3986.URI.Route(.case(TestRoute.cases.user)) {
                    Path { "users" }
                    Path { Int.parser() }
                }

                RFC_3986.URI.Route(.case(TestRoute.cases.search)) {
                    Path { "search" }
                    Query {
                        Field("q", .string)
                    }
                }

                RFC_3986.URI.Route(.case(TestRoute.cases.api)) {
                    Path { "api" }
                    Path { Parse(.string) }
                    Path { Parse(.string) }
                }
            }
        }
    }

    // MARK: - match(request:) Tests

    @Test("Match URLRequest with path only")
    func testMatchRequestWithPath() throws {
        let router = TestRouter()
        let request = URLRequest(url: URL(string: "https://example.com/home")!)

        let route = try router.match(request: request)
        #expect(route == .home)
    }

    @Test("Match URLRequest with path parameter")
    func testMatchRequestWithPathParameter() throws {
        let router = TestRouter()
        let request = URLRequest(url: URL(string: "https://example.com/users/42")!)

        let route = try router.match(request: request)
        #expect(route == .user(id: 42))
    }

    @Test("Match URLRequest with query parameters")
    func testMatchRequestWithQuery() throws {
        let router = TestRouter()
        let request = URLRequest(url: URL(string: "https://example.com/search?q=swift")!)

        let route = try router.match(request: request)
        #expect(route == .search(query: "swift"))
    }

    @Test("Match URLRequest with multiple path components")
    func testMatchRequestMultiplePathComponents() throws {
        let router = TestRouter()
        let request = URLRequest(url: URL(string: "https://example.com/api/v1/users")!)

        let route = try router.match(request: request)
        #expect(route == .api("v1", "users"))
    }

    @Test("Match URLRequest throws on invalid path")
    func testMatchRequestThrowsOnInvalidPath() throws {
        let router = TestRouter()
        let request = URLRequest(url: URL(string: "https://example.com/invalid")!)

        #expect(throws: Error.self) {
            try router.match(request: request)
        }
    }

    // MARK: - match(url:) Tests

    @Test("Match URL with path only")
    func testMatchURLWithPath() throws {
        let router = TestRouter()
        let url = URL(string: "https://example.com/home")!

        let route = try router.match(url: url)
        #expect(route == .home)
    }

    @Test("Match URL with path parameter")
    func testMatchURLWithPathParameter() throws {
        let router = TestRouter()
        let url = URL(string: "https://example.com/users/123")!

        let route = try router.match(url: url)
        #expect(route == .user(id: 123))
    }

    @Test("Match URL with query parameters")
    func testMatchURLWithQuery() throws {
        let router = TestRouter()
        let url = URL(string: "https://example.com/search?q=urlrouting")!

        let route = try router.match(url: url)
        #expect(route == .search(query: "urlrouting"))
    }

    @Test("Match URL with special characters in query")
    func testMatchURLWithSpecialCharacters() throws {
        let router = TestRouter()
        let url = URL(string: "https://example.com/search?q=hello%20world")!

        let route = try router.match(url: url)
        #expect(route == .search(query: "hello world"))
    }

    @Test("Match URL throws on invalid path")
    func testMatchURLThrowsOnInvalidPath() throws {
        let router = TestRouter()
        let url = URL(string: "https://example.com/notfound")!

        #expect(throws: Error.self) {
            try router.match(url: url)
        }
    }

    @Test("Match URL with different schemes")
    func testMatchURLWithDifferentSchemes() throws {
        let router = TestRouter()

        // HTTPS
        let httpsURL = URL(string: "https://example.com/home")!
        let httpsRoute = try router.match(url: httpsURL)
        #expect(httpsRoute == .home)

        // HTTP
        let httpURL = URL(string: "http://example.com/home")!
        let httpRoute = try router.match(url: httpURL)
        #expect(httpRoute == .home)
    }

    // MARK: - match(path:) Tests

    @Test("Match path string with simple path")
    func testMatchPathStringSimple() throws {
        let router = TestRouter()

        let route = try router.match(path: "/home")
        #expect(route == .home)
    }

    @Test("Match path string with parameter")
    func testMatchPathStringWithParameter() throws {
        let router = TestRouter()

        let route = try router.match(path: "/users/999")
        #expect(route == .user(id: 999))
    }

    @Test("Match path string with query")
    func testMatchPathStringWithQuery() throws {
        let router = TestRouter()

        let route = try router.match(path: "/search?q=test")
        #expect(route == .search(query: "test"))
    }

    @Test("Match path string with multiple components")
    func testMatchPathStringMultipleComponents() throws {
        let router = TestRouter()

        let route = try router.match(path: "/api/v2/posts")
        #expect(route == .api("v2", "posts"))
    }

    @Test("Match path string without leading slash")
    func testMatchPathStringWithoutLeadingSlash() throws {
        let router = TestRouter()

        let route = try router.match(path: "home")
        #expect(route == .home)
    }

    @Test("Match path string with encoded characters")
    func testMatchPathStringWithEncodedCharacters() throws {
        let router = TestRouter()

        let route = try router.match(path: "/search?q=hello%20world")
        #expect(route == .search(query: "hello world"))
    }

    @Test("Match path string throws on invalid path")
    func testMatchPathStringThrowsOnInvalidPath() throws {
        let router = TestRouter()

        #expect(throws: Error.self) {
            try router.match(path: "/unknown")
        }
    }

    // MARK: - Integration Tests

    @Test("Match across different input types produces same result")
    func testMatchConsistencyAcrossInputTypes() throws {
        let router = TestRouter()

        // All three methods should produce the same route
        let urlRequest = URLRequest(url: URL(string: "https://example.com/users/42")!)
        let url = URL(string: "https://example.com/users/42")!
        let path = "/users/42"

        let routeFromRequest = try router.match(request: urlRequest)
        let routeFromURL = try router.match(url: url)
        let routeFromPath = try router.match(path: path)

        #expect(routeFromRequest == .user(id: 42))
        #expect(routeFromURL == .user(id: 42))
        #expect(routeFromPath == .user(id: 42))
        #expect(routeFromRequest == routeFromURL)
        #expect(routeFromURL == routeFromPath)
    }

    @Test("Match preserves query parameter order")
    func testMatchPreservesQueryParameterOrder() throws {
        struct QueryResult: Equatable {
            let query: String
            let category: String
        }

        struct MultiQueryRouter: ParserPrinter {
            var body: some URLRouting.Router<QueryResult> {
                RFC_3986.URI.Route(
                    .memberwise(QueryResult.init, { ($0.query, $0.category) })
                ) {
                    Path { "search" }
                    Query {
                        Field("q", .string)
                        Field("category", .string)
                    }
                }
            }
        }

        let router = MultiQueryRouter()
        let url = URL(string: "https://example.com/search?q=swift&category=tutorials")!

        let result = try router.match(url: url)
        #expect(result.query == "swift")
        #expect(result.category == "tutorials")
    }
}
