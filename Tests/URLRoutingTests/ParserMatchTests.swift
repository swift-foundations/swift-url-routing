import Testing
import Foundation
import URLRouting

#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif

@Suite
struct `Parser Match Tests` {

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

    @Test
    func `Match URLRequest with path only`() throws {
        let router = TestRouter()
        let request = URLRequest(url: URL(string: "https://example.com/home")!)

        let route = try router.match(request: request)
        #expect(route == .home)
    }

    @Test
    func `Match URLRequest with path parameter`() throws {
        let router = TestRouter()
        let request = URLRequest(url: URL(string: "https://example.com/users/42")!)

        let route = try router.match(request: request)
        #expect(route == .user(id: 42))
    }

    @Test
    func `Match URLRequest with query parameters`() throws {
        let router = TestRouter()
        let request = URLRequest(url: URL(string: "https://example.com/search?q=swift")!)

        let route = try router.match(request: request)
        #expect(route == .search(query: "swift"))
    }

    @Test
    func `Match URLRequest with multiple path components`() throws {
        let router = TestRouter()
        let request = URLRequest(url: URL(string: "https://example.com/api/v1/users")!)

        let route = try router.match(request: request)
        #expect(route == .api("v1", "users"))
    }

    @Test
    func `Match URLRequest throws on invalid path`() throws {
        let router = TestRouter()
        let request = URLRequest(url: URL(string: "https://example.com/invalid")!)

        #expect(throws: Error.self) {
            try router.match(request: request)
        }
    }

    // MARK: - match(url:) Tests

    @Test
    func `Match URL with path only`() throws {
        let router = TestRouter()
        let url = URL(string: "https://example.com/home")!

        let route = try router.match(url: url)
        #expect(route == .home)
    }

    @Test
    func `Match URL with path parameter`() throws {
        let router = TestRouter()
        let url = URL(string: "https://example.com/users/123")!

        let route = try router.match(url: url)
        #expect(route == .user(id: 123))
    }

    @Test
    func `Match URL with query parameters`() throws {
        let router = TestRouter()
        let url = URL(string: "https://example.com/search?q=urlrouting")!

        let route = try router.match(url: url)
        #expect(route == .search(query: "urlrouting"))
    }

    @Test
    func `Match URL with special characters in query`() throws {
        let router = TestRouter()
        let url = URL(string: "https://example.com/search?q=hello%20world")!

        let route = try router.match(url: url)
        #expect(route == .search(query: "hello world"))
    }

    @Test
    func `Match URL throws on invalid path`() throws {
        let router = TestRouter()
        let url = URL(string: "https://example.com/notfound")!

        #expect(throws: Error.self) {
            try router.match(url: url)
        }
    }

    @Test
    func `Match URL with different schemes`() throws {
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

    @Test
    func `Match path string with simple path`() throws {
        let router = TestRouter()

        let route = try router.match(path: "/home")
        #expect(route == .home)
    }

    @Test
    func `Match path string with parameter`() throws {
        let router = TestRouter()

        let route = try router.match(path: "/users/999")
        #expect(route == .user(id: 999))
    }

    @Test
    func `Match path string with query`() throws {
        let router = TestRouter()

        let route = try router.match(path: "/search?q=test")
        #expect(route == .search(query: "test"))
    }

    @Test
    func `Match path string with multiple components`() throws {
        let router = TestRouter()

        let route = try router.match(path: "/api/v2/posts")
        #expect(route == .api("v2", "posts"))
    }

    @Test
    func `Match path string without leading slash`() throws {
        let router = TestRouter()

        let route = try router.match(path: "home")
        #expect(route == .home)
    }

    @Test
    func `Match path string with encoded characters`() throws {
        let router = TestRouter()

        let route = try router.match(path: "/search?q=hello%20world")
        #expect(route == .search(query: "hello world"))
    }

    @Test
    func `Match path string throws on invalid path`() throws {
        let router = TestRouter()

        #expect(throws: Error.self) {
            try router.match(path: "/unknown")
        }
    }

    // MARK: - Integration Tests

    @Test
    func `Match across different input types produces same result`() throws {
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

    @Test
    func `Match preserves query parameter order`() throws {
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
