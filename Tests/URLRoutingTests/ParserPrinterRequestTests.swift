import Testing
import Foundation
import URLRouting
import URL_Routing_Foundation_Integration

#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif

@Suite
struct `Parser Printer Request Tests` {

    // Multi-value cases carry NO argument labels: `@Cases` synthesizes an unlabeled
    // tuple `Case.Path` for them, matching the builder's `(A, B)` output.
    @Cases
    enum TestRoute: Equatable {
        case home
        case user(id: Int)
        case search(query: String)
        case api(String, String)
        case userWithQuery(Int, String)
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

                RFC_3986.URI.Route(.case(TestRoute.cases.userWithQuery)) {
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

    @Test
    func `Generate URLRequest for simple route`() throws {
        let router = TestRouter()
        let request = try router.request(for: .home)

        #expect(request.url?.path == "/home")
    }

    @Test
    func `Generate URLRequest with path parameter`() throws {
        let router = TestRouter()
        let request = try router.request(for: .user(id: 42))

        #expect(request.url?.path == "/users/42")
    }

    @Test
    func `Generate URLRequest with query parameter`() throws {
        let router = TestRouter()
        let request = try router.request(for: .search(query: "swift"))

        #expect(request.url?.path == "/search")
        #expect(request.url?.query?.contains("q=swift") == true)
    }

    @Test
    func `Generate URLRequest with multiple path components`() throws {
        let router = TestRouter()
        let request = try router.request(for: .api("v1", "users"))

        #expect(request.url?.path == "/api/v1/users")
    }

    @Test
    func `Generate URLRequest with path and query parameters`() throws {
        let router = TestRouter()
        let request = try router.request(for: .userWithQuery(123, "active"))

        #expect(request.url?.path == "/users/123")
        #expect(request.url?.query?.contains("filter=active") == true)
    }

    @Test
    func `Generate URLRequest with special characters in query`() throws {
        let router = TestRouter()
        let request = try router.request(for: .search(query: "hello world"))

        #expect(request.url?.path == "/search")
        // URL encoding should handle spaces
        let query = request.url?.query ?? ""
        #expect(query.contains("hello") && query.contains("world"))
    }

    // MARK: - url(for:) Tests

    @Test
    func `Generate URL for simple route`() {
        let router = TestRouter()
        let url = router.url(for: .home)

        #expect(url.path == "/home")
    }

    @Test
    func `Generate URL with path parameter`() {
        let router = TestRouter()
        let url = router.url(for: .user(id: 999))

        #expect(url.path == "/users/999")
    }

    @Test
    func `Generate URL with query parameter`() {
        let router = TestRouter()
        let url = router.url(for: .search(query: "testing"))

        #expect(url.path == "/search")
        #expect(url.query?.contains("q=testing") == true)
    }

    @Test
    func `Generate URL with multiple path components`() {
        let router = TestRouter()
        let url = router.url(for: .api("v2", "posts"))

        #expect(url.path == "/api/v2/posts")
    }

    @Test
    func `Generate URL with path and query parameters`() {
        let router = TestRouter()
        let url = router.url(for: .userWithQuery(456, "inactive"))

        #expect(url.path == "/users/456")
        #expect(url.query?.contains("filter=inactive") == true)
    }

    @Test
    func `Generate URL handles special characters`() {
        let router = TestRouter()
        let url = router.url(for: .search(query: "swift & ios"))

        #expect(url.path == "/search")
        // URLComponents should handle encoding
        #expect(url.query != nil)
    }

    // MARK: - urlPath(for:) Tests

    @Test
    func `Generate URL path for simple route`() {
        let router = TestRouter()
        let path = router.urlPath(for: .home)

        #expect(path == "/home")
    }

    @Test
    func `Generate URL path with parameter`() {
        let router = TestRouter()
        let path = router.urlPath(for: .user(id: 42))

        #expect(path == "/users/42")
    }

    @Test
    func `Generate URL path with query parameter`() {
        let router = TestRouter()
        let path = router.urlPath(for: .search(query: "swift"))

        #expect(path.starts(with: "/search"))
        #expect(path.contains("q=swift"))
    }

    @Test
    func `Generate URL path with multiple components`() {
        let router = TestRouter()
        let path = router.urlPath(for: .api("v3", "comments"))

        #expect(path == "/api/v3/comments")
    }

    @Test
    func `Generate URL path with path and query`() {
        let router = TestRouter()
        let path = router.urlPath(for: .userWithQuery(789, "pending"))

        #expect(path.starts(with: "/users/789"))
        #expect(path.contains("filter=pending"))
    }

    @Test
    func `Generate URL path includes query string separator`() {
        let router = TestRouter()
        let path = router.urlPath(for: .search(query: "test"))

        // Should have both path and query separated by ?
        #expect(path.contains("?"))
        let components = path.components(separatedBy: "?")
        #expect(components.count == 2)
        #expect(components[0] == "/search")
        #expect(components[1].contains("q=test"))
    }

    @Test
    func `Generate URL path omits base scheme and authority`() {
        let router = TestRouter().baseURL("https://api.example.com/v1?token=deadbeef")
        let path = router.urlPath(for: .home)

        #expect(path == "/v1/home?token=deadbeef")
    }

    // MARK: - Round-trip Tests

    @Test
    func `Round-trip: request -> match -> request`() throws {
        let router = TestRouter()
        let originalRoute = TestRoute.user(id: 42)

        let request = try router.request(for: originalRoute)
        let matchedRoute = try router.match(request: request)
        let finalRequest = try router.request(for: matchedRoute)

        #expect(originalRoute == matchedRoute)
        #expect(request.url?.path == finalRequest.url?.path)
    }

    @Test
    func `Round-trip: url -> match -> url`() throws {
        let router = TestRouter()
        let originalRoute = TestRoute.search(query: "testing")

        let url = router.url(for: originalRoute)
        let matchedRoute = try router.match(url: url)
        let finalURL = router.url(for: matchedRoute)

        #expect(originalRoute == matchedRoute)
        #expect(url.path == finalURL.path)
    }

    @Test
    func `Round-trip: path -> match -> path`() throws {
        let router = TestRouter()
        let originalRoute = TestRoute.api("v1", "users")

        let path = router.urlPath(for: originalRoute)
        let matchedRoute = try router.match(path: path)
        let finalPath = router.urlPath(for: matchedRoute)

        #expect(originalRoute == matchedRoute)
        #expect(path == finalPath)
    }

    // MARK: - Consistency Tests

    @Test
    func `Request(), url(), and url Path() produce consistent paths`() throws {
        let router = TestRouter()
        let route = TestRoute.user(id: 123)

        let request = try router.request(for: route)
        let url = router.url(for: route)
        let urlPath = router.urlPath(for: route)

        #expect(request.url?.path == url.path)
        #expect(url.path == urlPath)
    }

    @Test
    func `All generation methods work with query parameters`() throws {
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

    @Test
    func `Generate paths for routes with numeric IDs`() throws {
        let router = TestRouter()

        // Test various numeric values
        for id in [0, 1, 42, 999, 1000000] {
            let route = TestRoute.user(id: id)
            let request = try router.request(for: route)
            #expect(request.url?.path == "/users/\(id)")
        }
    }

    @Test
    func `Generate paths with empty strings handled appropriately`() {
        let router = TestRouter()
        let route = TestRoute.search(query: "")

        let url = router.url(for: route)
        // Should still generate valid URL even with empty query
        #expect(url.path == "/search")
    }
}
