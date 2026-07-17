import Foundation
import Testing
import URLRouting

#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif

@Suite
struct Test {

    @Test
    func `Parse RFC 3986 URI with all components`() throws {
        let uri = try RFC_3986.URI(
            "https://user:pass@api.example.com:8080/users/123?page=1&limit=10#section"
        )
        let requestData = try RFC_3986.URI.Request.Data(uri: uri)

        #expect(requestData.scheme == "https")
        #expect(requestData.userinfo == "user:pass")
        #expect(requestData.host == "api.example.com")
        #expect(requestData.port == 8080)
        #expect(requestData.path.joined(separator: "/") == "users/123")
        #expect(requestData.query["page"]?.first??.description == "1")
        #expect(requestData.query["limit"]?.first??.description == "10")
        #expect(requestData.fragment == "section")
    }

    @Test
    func `Parse relative URI reference`() throws {
        let uri = try RFC_3986.URI("/users/123?page=1")
        let requestData = try RFC_3986.URI.Request.Data(uri: uri)

        #expect(requestData.scheme == nil)
        #expect(requestData.host == nil)
        #expect(requestData.path.joined(separator: "/") == "users/123")
        #expect(requestData.query["page"]?.first??.description == "1")
    }

    @Test
    func `Parse empty URI (same document reference)`() throws {
        let uri = try RFC_3986.URI("")
        let requestData = try RFC_3986.URI.Request.Data(uri: uri)

        #expect(requestData.scheme == nil)
        #expect(requestData.host == nil)
        #expect(requestData.path.isEmpty)
    }

    @Test
    func `Print to RFC 3986 URI`() throws {
        let requestData = RFC_3986.URI.Request.Data(
            scheme: "https",
            host: "api.example.com",
            path: "/users/123",
            query: ["page": ["1"], "limit": ["10"]]
        )

        let uri = try requestData.uri()

        // URI should contain all components
        #expect(uri.value.contains("https://api.example.com"))
        #expect(uri.value.contains("/users/123"))
        #expect(uri.value.contains("page=1"))
        #expect(uri.value.contains("limit=10"))
    }

    @Test
    func `Round-trip URI → RFC 3986.URI.Request.Data → URI`() throws {
        let original = try RFC_3986.URI("https://api.example.com/users/123?page=1#section")
        let requestData = try RFC_3986.URI.Request.Data(uri: original)
        let reconstructed = try requestData.uri()

        // Components should match (order may vary for query)
        #expect(reconstructed.value.contains("https://api.example.com"))
        #expect(reconstructed.value.contains("/users/123"))
        #expect(reconstructed.value.contains("page=1"))
        #expect(reconstructed.value.contains("#section"))
    }

    @Test
    func `Parse URI with userinfo`() throws {
        let uri = try RFC_3986.URI("https://user:password@example.com/resource")
        let requestData = try RFC_3986.URI.Request.Data(uri: uri)

        #expect(requestData.userinfo == "user:password")
        #expect(requestData.host == "example.com")
    }

    @Test
    func `Parse URI with userinfo (no password)`() throws {
        let uri = try RFC_3986.URI("https://user@example.com/resource")
        let requestData = try RFC_3986.URI.Request.Data(uri: uri)

        #expect(requestData.userinfo == "user")
        #expect(requestData.host == "example.com")
    }
}
