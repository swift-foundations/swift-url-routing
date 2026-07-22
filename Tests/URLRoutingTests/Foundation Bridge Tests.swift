import Foundation
import Testing
import URLRouting

#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif

@Suite
struct `Foundation Bridge Tests` {

    // MARK: - URLRequest → RFC_3986.URI.Request.Data

    @Test
    func `Parse URLRequest with all components`() throws {
        var request = URLRequest(url: URL(string: "https://api.example.com/users/123")!)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer token", forHTTPHeaderField: "Authorization")
        request.httpBody = Data("{\"name\":\"test\"}".utf8)

        let requestData = RFC_3986.URI.Request.Data(request: request)
        #expect(requestData != nil)
        #expect(requestData?.method == .post)
        #expect(requestData?.scheme == "https")
        #expect(requestData?.host == "api.example.com")
        #expect(requestData?.path.joined(separator: "/") == "users/123")
        #expect(requestData?.headers["content-type"]?.first??.description == "application/json")
        #expect(requestData?.body != nil)
    }

    @Test
    func `Parse URL with query parameters`() throws {
        let url = URL(string: "https://api.example.com/search?q=swift&page=1&limit=20")!
        let requestData = RFC_3986.URI.Request.Data(url: url)

        #expect(requestData != nil)
        #expect(requestData?.scheme == "https")
        #expect(requestData?.host == "api.example.com")
        #expect(requestData?.path.joined(separator: "/") == "search")
        #expect(requestData?.query["q"]?.first??.description == "swift")
        #expect(requestData?.query["page"]?.first??.description == "1")
        #expect(requestData?.query["limit"]?.first??.description == "20")
    }

    @Test
    func `Parse URL string`() throws {
        let requestData = RFC_3986.URI.Request.Data(string: "https://api.example.com/users/123")

        #expect(requestData != nil)
        #expect(requestData?.scheme == "https")
        #expect(requestData?.host == "api.example.com")
        #expect(requestData?.path.joined(separator: "/") == "users/123")
    }

    @Test
    func `Parse URL with fragment`() throws {
        let requestData = RFC_3986.URI.Request.Data(string: "https://example.com/docs#section-1")

        #expect(requestData != nil)
        #expect(requestData?.path.joined(separator: "/") == "docs")
        #expect(requestData?.fragment == "section-1")
    }

    // MARK: - RFC_3986.URI.Request.Data → URLRequest

    @Test
    func `Print to URLRequest`() throws {
        let requestData = RFC_3986.URI.Request.Data(
            method: .post,
            scheme: "https",
            host: "api.example.com",
            path: "/users",
            headers: ["Content-Type": ["application/json"], "Authorization": ["Bearer token"]],
            body: Data("{\"name\":\"test\"}".utf8)
        )

        let request = URLRequest(data: requestData)
        #expect(request != nil)
        #expect(request?.httpMethod == "POST")
        #expect(request?.url?.scheme == "https")
        #expect(request?.url?.host == "api.example.com")
        #expect(request?.url?.path == "/users")
        #expect(request?.value(forHTTPHeaderField: "Content-Type") == "application/json")
        #expect(request?.value(forHTTPHeaderField: "Authorization") == "Bearer token")
        #expect(request?.httpBody != nil)
    }

    @Test
    func `Print to URLRequest with query parameters`() throws {
        let requestData = RFC_3986.URI.Request.Data(
            scheme: "https",
            host: "api.example.com",
            path: "/search",
            query: ["q": ["swift"], "page": ["1"]]
        )

        let request = URLRequest(data: requestData)
        #expect(request != nil)
        #expect(request?.url?.query?.contains("q=swift") == true)
        #expect(request?.url?.query?.contains("page=1") == true)
    }

    @Test
    func `Foundation bridge preserves interleaved query pairs`() throws {
        let requestData = try RFC_3986.URI.Request.Data(uriString: "/r?b=2&a=1&b=3")

        #expect(URLComponents(data: requestData).percentEncodedQuery == "b=2&a=1&b=3")
    }

    // MARK: - URLComponents Bridge

    @Test
    func `URLComponents from RFC 3986.URI.Request.Data`() throws {
        let requestData = RFC_3986.URI.Request.Data(
            scheme: "https",
            userinfo: "user:password",
            host: "example.com",
            port: 8080,
            path: "/resource",
            query: ["key": ["value"]],
            fragment: "section"
        )

        let components = URLComponents(data: requestData)
        #expect(components.scheme == "https")
        #expect(components.user == "user")
        #expect(components.password == "password")
        #expect(components.host == "example.com")
        #expect(components.port == 8080)
        #expect(components.path == "/resource")
        #expect(
            components.queryItems?.contains(where: { $0.name == "key" && $0.value == "value" })
                == true
        )
        #expect(components.fragment == "section")
    }

    @Test
    func `URLComponents with userinfo (no password)`() throws {
        let requestData = RFC_3986.URI.Request.Data(
            scheme: "https",
            userinfo: "user",
            host: "example.com",
            path: "/resource"
        )

        let components = URLComponents(data: requestData)
        #expect(components.user == "user")
        #expect(components.password == nil)
    }

    // MARK: - RFC 3986 URI → Foundation URL

    @Test
    func `Foundation URL from RFC 3986 URI`() throws {
        let uri = RFC_3986.URI(unchecked: "https://api.example.com/users/123")
        let url = try URL(uri: uri)

        #expect(url.absoluteString == "https://api.example.com/users/123")
        #expect(url.scheme == "https")
        #expect(url.host == "api.example.com")
        #expect(url.path == "/users/123")
    }

    // MARK: - Round-trip Tests

    @Test
    func `Round-trip URLRequest → RFC 3986.URI.Request.Data → URLRequest`() throws {
        var original = URLRequest(url: URL(string: "https://api.example.com/users/123?page=1")!)
        original.httpMethod = "GET"
        original.addValue("application/json", forHTTPHeaderField: "Accept")

        let requestData = RFC_3986.URI.Request.Data(request: original)
        #expect(requestData != nil)

        let reconstructed = URLRequest(data: requestData!)
        #expect(reconstructed != nil)
        #expect(reconstructed?.httpMethod == original.httpMethod)
        #expect(reconstructed?.url?.absoluteString == original.url?.absoluteString)
        #expect(reconstructed?.value(forHTTPHeaderField: "Accept") == "application/json")
    }

    @Test
    func `Round-trip URL → RFC 3986.URI.Request.Data → URL`() throws {
        let original = URL(string: "https://api.example.com/users/123?page=1#section")!
        let requestData = RFC_3986.URI.Request.Data(url: original)
        #expect(requestData != nil)

        let components = URLComponents(data: requestData!)
        let reconstructed = components.url
        #expect(reconstructed != nil)
        #expect(reconstructed?.scheme == original.scheme)
        #expect(reconstructed?.host == original.host)
        #expect(reconstructed?.path == original.path)
        #expect(reconstructed?.fragment == original.fragment)
    }
}
