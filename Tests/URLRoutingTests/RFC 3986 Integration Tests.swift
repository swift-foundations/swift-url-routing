import Foundation
import RFC_3986
import Testing
import URLRouting

#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif

@Suite("RFC 3986 URI Integration")
struct RFC3986IntegrationTests {

    @Test("Parse RFC 3986 URI with all components")
    func parseCompleteURI() throws {
        let uri = try RFC_3986.URI(
            "https://user:pass@api.example.com:8080/users/123?page=1&limit=10#section"
        )
        let requestData = try URIRequestData(uri: uri)

        #expect(requestData.scheme == "https")
        #expect(requestData.userinfo == "user:pass")
        #expect(requestData.host == "api.example.com")
        #expect(requestData.port == 8080)
        #expect(requestData.path.joined(separator: "/") == "users/123")
        #expect(requestData.query["page"]?.first??.description == "1")
        #expect(requestData.query["limit"]?.first??.description == "10")
        #expect(requestData.fragment == "section")
    }

    @Test("Parse relative URI reference")
    func parseRelativeReference() throws {
        let uri = try RFC_3986.URI("/users/123?page=1")
        let requestData = try URIRequestData(uri: uri)

        #expect(requestData.scheme == nil)
        #expect(requestData.host == nil)
        #expect(requestData.path.joined(separator: "/") == "users/123")
        #expect(requestData.query["page"]?.first??.description == "1")
    }

    @Test("Parse empty URI (same document reference)")
    func parseEmptyURI() throws {
        let uri = try RFC_3986.URI("")
        let requestData = try URIRequestData(uri: uri)

        #expect(requestData.scheme == nil)
        #expect(requestData.host == nil)
        #expect(requestData.path.isEmpty)
    }

    @Test("Print to RFC 3986 URI")
    func printToURI() throws {
        let requestData = URIRequestData(
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

    @Test("Round-trip URI → URIRequestData → URI")
    func roundTripURI() throws {
        let original = try RFC_3986.URI("https://api.example.com/users/123?page=1#section")
        let requestData = try URIRequestData(uri: original)
        let reconstructed = try requestData.uri()

        // Components should match (order may vary for query)
        #expect(reconstructed.value.contains("https://api.example.com"))
        #expect(reconstructed.value.contains("/users/123"))
        #expect(reconstructed.value.contains("page=1"))
        #expect(reconstructed.value.contains("#section"))
    }

    @Test("Parse URI with userinfo")
    func parseUserinfo() throws {
        let uri = try RFC_3986.URI("https://user:password@example.com/resource")
        let requestData = try URIRequestData(uri: uri)

        #expect(requestData.userinfo == "user:password")
        #expect(requestData.host == "example.com")
    }

    @Test("Parse URI with userinfo (no password)")
    func parseUserinfoNoPassword() throws {
        let uri = try RFC_3986.URI("https://user@example.com/resource")
        let requestData = try URIRequestData(uri: uri)

        #expect(requestData.userinfo == "user")
        #expect(requestData.host == "example.com")
    }
}
