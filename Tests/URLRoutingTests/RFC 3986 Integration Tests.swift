import Foundation
import Testing
import URLRouting

#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif

@Suite
struct `RFC 3986 Integration Tests` {

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

        #expect(reconstructed.value == original.value)
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

    // MARK: - Batch 3 ratified behavior classes (plan §Batch 3, fork F2)

    @Test
    func `Percent-encoded slash inside a segment does not split (ratified class 1)`() throws {
        let uri = try RFC_3986.URI("/files/a%2Fb/details")
        let requestData = try RFC_3986.URI.Request.Data(uri: uri)

        #expect(requestData.path.map(String.init) == ["files", "a/b", "details"])
    }

    @Test
    func `Percent-encoded slash round-trips through print (ratified class 1)`() throws {
        let requestData = try RFC_3986.URI.Request.Data(uriString: "/files/a%2Fb/details")
        let printed = try requestData.uriString

        #expect(printed == "/files/a%2Fb/details")
    }

    @Test
    func `Empty query value and absent query value stay distinct (ratified class 3)`() throws {
        let uri = try RFC_3986.URI("/search?empty=&absent&filled=x")
        let requestData = try RFC_3986.URI.Request.Data(uri: uri)

        #expect(requestData.query["empty"]?.first == .some(.some("")))
        #expect(requestData.query["absent"]?.first == .some(.none))
        #expect(requestData.query["filled"]?.first == .some(.some("x")))

        let printed = try requestData.uriString
        #expect(printed == "/search?empty=&absent&filled=x")
    }

    @Test
    func `Percent-normalization uses uppercase hex and decodes segments (ratified class 2)`() throws
    {
        let uri = try RFC_3986.URI("/tags/caf%c3%a9?q=a%20b")
        let requestData = try RFC_3986.URI.Request.Data(uri: uri)

        #expect(requestData.path.map(String.init) == ["tags", "café"])
        #expect(requestData.query["q"]?.first??.description == "a b")

        // Re-print normalizes to UPPERCASE hex per RFC 3986 Section 6.2.2.2.
        let printed = try requestData.uriString
        #expect(printed == "/tags/caf%C3%A9?q=a%20b")
    }

    @Test
    func `Query pair order is preserved through parse and print`() throws {
        let requestData = try RFC_3986.URI.Request.Data(uriString: "/r?b=2&a=1&b=3")

        #expect(try requestData.uriString == "/r?b=2&a=1&b=3")
        #expect(requestData.query["b"]?.map { $0.map(String.init) } == ["2", "3"])
        #expect(requestData.query["a"]?.map { $0.map(String.init) } == ["1"])
    }

    @Test
    func `Query pair order follows incremental field consumption and emission`() throws {
        var requestData = try RFC_3986.URI.Request.Data(uriString: "/r?b=2&a=1&b=3")

        requestData.query["b"]?.removeFirst()
        #expect(try requestData.uriString == "/r?a=1&b=3")

        requestData.query.fields.updateValue(
            forKey: "b",
            insertingDefault: [],
            at: requestData.query.fields.count,
            with: { $0.append("4") }
        )
        #expect(try requestData.uriString == "/r?a=1&b=3&b=4")
    }

    @Test
    func `Base request data preserves ordered query pairs on both sides`() throws {
        let base = try RFC_3986.URI.Request.Data(uriString: "/r?x=1&y=2&x=3")
        let parser = URLRouting.Query {
            RFC_3986.URI.Query.Field("b")
            RFC_3986.URI.Query.Field("a")
            RFC_3986.URI.Query.Field("b")
        }
        .baseRequestData(base)

        let requestData = try parser.print((("4", "5"), "6"))

        #expect(try requestData.uriString == "/r?x=1&y=2&x=3&b=4&a=5&b=6")
    }
}
