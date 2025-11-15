import Testing
import Foundation
import URLRouting

#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif

@Suite("ParserPrinter request() Extensions Tests")
struct ParserPrinterRequestTests {

    enum TestRoute: Equatable {
        case home
        case user(id: Int)
        case search(query: String)
        case api(version: String, endpoint: String)
        case userWithQuery(id: Int, filter: String)
    }

    struct TestRouter: ParserPrinter {
        var body: some URLRouting.Router<TestRoute> {
            OneOf {
                RFC_3986.URI.Route(.case(TestRoute.home)) {
                    Path { "home" }
                }

                RFC_3986.URI.Route(.case(TestRoute.user)) {
                    Path { "users" }
                    Path { Int.parser() }
                }

                RFC_3986.URI.Route(.case(TestRoute.search)) {
                    Path { "search" }
                    Query {
                        Field("q", .string)
                    }
                }

                RFC_3986.URI.Route(.case(TestRoute.api)) {
                    Path { "api" }
                    Path { Parse(.string) }
                    Path { Parse(.string) }
                }

                RFC_3986.URI.Route(.case(TestRoute.userWithQuery)) {
                    Path { "users" }
                    Path { Int.parser() }
                    Query {
                        Field("filter", .string)
                    }
                }
            }
        }
    }

    // MARK: - request(for:) Tests

    @Test("Generate URLRequest for simple route")
    func testRequestForSimpleRoute() throws {
        let router = TestRouter()
        let request = try router.request(for: .home)

        #expect(request.url?.path == "/home")
    }

    @Test("Generate URLRequest with path parameter")
    func testRequestForRouteWithParameter() throws {
        let router = TestRouter()
        let request = try router.request(for: .user(id: 42))

        #expect(request.url?.path == "/users/42")
    }

    @Test("Generate URLRequest with query parameter")
    func testRequestForRouteWithQuery() throws {
        let router = TestRouter()
        let request = try router.request(for: .search(query: "swift"))

        #expect(request.url?.path == "/search")
        #expect(request.url?.query?.contains("q=swift") == true)
    }

    @Test("Generate URLRequest with multiple path components")
    func testRequestForRouteWithMultipleComponents() throws {
        let router = TestRouter()
        let request = try router.request(for: .api(version: "v1", endpoint: "users"))

        #expect(request.url?.path == "/api/v1/users")
    }

    @Test("Generate URLRequest with path and query parameters")
    func testRequestForRouteWithPathAndQuery() throws {
        let router = TestRouter()
        let request = try router.request(for: .userWithQuery(id: 123, filter: "active"))

        #expect(request.url?.path == "/users/123")
        #expect(request.url?.query?.contains("filter=active") == true)
    }

    @Test("Generate URLRequest with special characters in query")
    func testRequestForRouteWithSpecialCharacters() throws {
        let router = TestRouter()
        let request = try router.request(for: .search(query: "hello world"))

        #expect(request.url?.path == "/search")
        // URL encoding should handle spaces
        let query = request.url?.query ?? ""
        #expect(query.contains("hello") && query.contains("world"))
    }

    // MARK: - url(for:) Tests

    @Test("Generate URL for simple route")
    func testURLForSimpleRoute() {
        let router = TestRouter()
        let url = router.url(for: .home)

        #expect(url.path == "/home")
    }

    @Test("Generate URL with path parameter")
    func testURLForRouteWithParameter() {
        let router = TestRouter()
        let url = router.url(for: .user(id: 999))

        #expect(url.path == "/users/999")
    }

    @Test("Generate URL with query parameter")
    func testURLForRouteWithQuery() {
        let router = TestRouter()
        let url = router.url(for: .search(query: "testing"))

        #expect(url.path == "/search")
        #expect(url.query?.contains("q=testing") == true)
    }

    @Test("Generate URL with multiple path components")
    func testURLForRouteWithMultipleComponents() {
        let router = TestRouter()
        let url = router.url(for: .api(version: "v2", endpoint: "posts"))

        #expect(url.path == "/api/v2/posts")
    }

    @Test("Generate URL with path and query parameters")
    func testURLForRouteWithPathAndQuery() {
        let router = TestRouter()
        let url = router.url(for: .userWithQuery(id: 456, filter: "inactive"))

        #expect(url.path == "/users/456")
        #expect(url.query?.contains("filter=inactive") == true)
    }

    @Test("Generate URL handles special characters")
    func testURLForRouteWithSpecialCharacters() {
        let router = TestRouter()
        let url = router.url(for: .search(query: "swift & ios"))

        #expect(url.path == "/search")
        // URLComponents should handle encoding
        #expect(url.query != nil)
    }

    // MARK: - urlPath(for:) Tests

    @Test("Generate URL path for simple route")
    func testURLPathForSimpleRoute() {
        let router = TestRouter()
        let path = router.urlPath(for: .home)

        #expect(path == "/home")
    }

    @Test("Generate URL path with parameter")
    func testURLPathForRouteWithParameter() {
        let router = TestRouter()
        let path = router.urlPath(for: .user(id: 42))

        #expect(path == "/users/42")
    }

    @Test("Generate URL path with query parameter")
    func testURLPathForRouteWithQuery() {
        let router = TestRouter()
        let path = router.urlPath(for: .search(query: "swift"))

        #expect(path.starts(with: "/search"))
        #expect(path.contains("q=swift"))
    }

    @Test("Generate URL path with multiple components")
    func testURLPathForRouteWithMultipleComponents() {
        let router = TestRouter()
        let path = router.urlPath(for: .api(version: "v3", endpoint: "comments"))

        #expect(path == "/api/v3/comments")
    }

    @Test("Generate URL path with path and query")
    func testURLPathForRouteWithPathAndQuery() {
        let router = TestRouter()
        let path = router.urlPath(for: .userWithQuery(id: 789, filter: "pending"))

        #expect(path.starts(with: "/users/789"))
        #expect(path.contains("filter=pending"))
    }

    @Test("Generate URL path includes query string separator")
    func testURLPathIncludesQuerySeparator() {
        let router = TestRouter()
        let path = router.urlPath(for: .search(query: "test"))

        // Should have both path and query separated by ?
        #expect(path.contains("?"))
        let components = path.components(separatedBy: "?")
        #expect(components.count == 2)
        #expect(components[0] == "/search")
        #expect(components[1].contains("q=test"))
    }

    // MARK: - Round-trip Tests

    @Test("Round-trip: request -> match -> request")
    func testRoundTripRequestMatchRequest() throws {
        let router = TestRouter()
        let originalRoute = TestRoute.user(id: 42)

        let request = try router.request(for: originalRoute)
        let matchedRoute = try router.match(request: request)
        let finalRequest = try router.request(for: matchedRoute)

        #expect(originalRoute == matchedRoute)
        #expect(request.url?.path == finalRequest.url?.path)
    }

    @Test("Round-trip: url -> match -> url")
    func testRoundTripURLMatchURL() throws {
        let router = TestRouter()
        let originalRoute = TestRoute.search(query: "testing")

        let url = router.url(for: originalRoute)
        let matchedRoute = try router.match(url: url)
        let finalURL = router.url(for: matchedRoute)

        #expect(originalRoute == matchedRoute)
        #expect(url.path == finalURL.path)
    }

    @Test("Round-trip: path -> match -> path")
    func testRoundTripPathMatchPath() throws {
        let router = TestRouter()
        let originalRoute = TestRoute.api(version: "v1", endpoint: "users")

        let path = router.urlPath(for: originalRoute)
        let matchedRoute = try router.match(path: path)
        let finalPath = router.urlPath(for: matchedRoute)

        #expect(originalRoute == matchedRoute)
        #expect(path == finalPath)
    }

    // MARK: - Consistency Tests

    @Test("request(), url(), and urlPath() produce consistent paths")
    func testConsistentPathGeneration() throws {
        let router = TestRouter()
        let route = TestRoute.user(id: 123)

        let request = try router.request(for: route)
        let url = router.url(for: route)
        let urlPath = router.urlPath(for: route)

        #expect(request.url?.path == url.path)
        #expect(url.path == urlPath)
    }

    @Test("All generation methods work with query parameters")
    func testConsistentQueryParameterGeneration() throws {
        let router = TestRouter()
        let route = TestRoute.search(query: "swift")

        let request = try router.request(for: route)
        let url = router.url(for: route)
        let urlPath = router.urlPath(for: route)

        // All should have the query parameter
        #expect(request.url?.query?.contains("q=swift") == true)
        #expect(url.query?.contains("q=swift") == true)
        #expect(urlPath.contains("q=swift"))

        // All should have the same path
        #expect(request.url?.path == "/search")
        #expect(url.path == "/search")
        #expect(urlPath.starts(with: "/search?"))
    }

    // MARK: - Edge Cases

    @Test("Generate paths for routes with numeric IDs")
    func testNumericIDsInPaths() throws {
        let router = TestRouter()

        // Test various numeric values
        for id in [0, 1, 42, 999, 1000000] {
            let route = TestRoute.user(id: id)
            let request = try router.request(for: route)
            #expect(request.url?.path == "/users/\(id)")
        }
    }

    @Test("Generate paths with empty strings handled appropriately")
    func testEmptyStringHandling() {
        let router = TestRouter()
        let route = TestRoute.search(query: "")

        let url = router.url(for: route)
        // Should still generate valid URL even with empty query
        #expect(url.path == "/search")
    }
}
