import Foundation
import Parsing
import Testing
import URLRouting
import WHATWG_HTML_Forms

#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif

@Suite("URL Routing")
struct URLRoutingTests {

    @Test("Method parser")
    func method() throws {
        var request = RFC_3986.URI.Request.Data(method: .post)
        #expect(throws: Never.self) { try Method.post.parse(&request) }
        #expect(try Method.post.print() == RFC_3986.URI.Request.Data(method: .post))
    }

    @Test("Host parser")
    func host() throws {
        var request = RFC_3986.URI.Request.Data(host: "foo")
        #expect(throws: Never.self) { try Host.custom("foo").parse(&request) }
        #expect(try Host.custom("foo").print() == RFC_3986.URI.Request.Data(host: "foo"))
    }

    @Test("Scheme parser")
    func scheme() throws {
        var request = RFC_3986.URI.Request.Data(scheme: "http")
        #expect(throws: Never.self) { try Scheme.http.parse(&request) }
        #expect(try Scheme.http.print() == RFC_3986.URI.Request.Data(scheme: "http"))
    }

    @Test("Path parser with integer")
    func pathWithInt() throws {
        #expect(try Path { Int.parser() }.parse(RFC_3986.URI.Request.Data(path: "/123")) == 123)
    }

    @Test("Path parser error formatting")
    func pathError() throws {
        do {
            _ = try Path { Int.parser() }.parse(RFC_3986.URI.Request.Data(path: "/123-foo"))
            Issue.record("Expected error to be thrown")
        } catch {
            #expect(
                "\(error)" == """
                    error: unexpected input
                     --> input:1:5
                    1 | /123-foo
                      |     ^ expected end of input
                    """
            )
        }
    }

    @Test("Form data parsing")
    func formData() throws {
        let p = Body {
            FormData {
                Form.Data.Field("name", .string)
                Form.Data.Field("age") { Int.parser() }
            }
        }

        var request = RFC_3986.URI.Request.Data(body: .init("name=Blob&age=42&debug=1".utf8))
        let (name, age) = try p.parse(&request)
        #expect(name == "Blob")
        #expect(age == 42)
        #expect(request.body.map { String(decoding: $0, as: UTF8.self) } == "debug=1")
    }

    @Test("Headers parsing")
    func headers() throws {
        let p = Headers {
            RFC_7230.Header.Field.Parser("X-Haha", .string)
        }

        var req = URLRequest(url: URL(string: "/")!)
        req.addValue("Hello", forHTTPHeaderField: "X-Haha")
        req.addValue("Blob", forHTTPHeaderField: "X-Haha")
        let requestData = try #require(RFC_3986.URI.Request.Data(request: req))
        var request = requestData

        let name = try p.parse(&request)
        #expect(name == "Hello")

        // Headers should remain case-insensitive (isCaseSensitive: false)
        let remaining = request.headers
        #expect(remaining["x-haha"]?.first??.description == "Blob")
    }

    @Test("Query parsing")
    func query() throws {
        let p = Query {
            RFC_3986.URI.Query.Field("name")
            RFC_3986.URI.Query.Field("age") { Int.parser() }
        }

        var request = try #require(RFC_3986.URI.Request.Data(string: "/?name=Blob&age=42&debug=1"))
        let (name, age) = try p.parse(&request)
        #expect(name == "Blob")
        #expect(age == 42)

        let remaining = request.query
        #expect(remaining["debug"]?.first??.description == "1")

        #expect(
            try p.print(("Blob", 42)) == RFC_3986.URI.Request.Data(query: ["name": ["Blob"], "age": ["42"]])
        )
    }

    @Test("Query with default value")
    func queryDefault() throws {
        let p = Query {
            RFC_3986.URI.Query.Field("page", default: 1) {
                Int.parser()
            }
        }

        var request = try #require(RFC_3986.URI.Request.Data(string: "/"))
        let page = try p.parse(&request)
        #expect(page == 1)
        #expect(request.query.isEmpty)

        #expect(
            try p.print(10) == RFC_3986.URI.Request.Data(query: ["page": ["10"]])
        )
        #expect(
            try p.print(1) == RFC_3986.URI.Request.Data(query: [:])
        )
    }

    @Test("Fragment parsing")
    func fragment() throws {
        // test default initializer
        let q1 = URIFragment()

        var request = try #require(RFC_3986.URI.Request.Data(string: "#fragment"))
        #expect(try q1.parse(&request) == "fragment")
        #expect(try q1.print("fragment") == RFC_3986.URI.Request.Data(fragment: "fragment"))

        struct Timestamp: Equatable, RawRepresentable {
            let rawValue: String
        }

        // test conversion initializer
        let q2 = URIFragment(.string.representing(Timestamp.self))
        request = try #require(
            RFC_3986.URI.Request.Data(
                string: "https://www.pointfree.co/episodes/ep182-invertible-parsing-map#t802"
            )
        )
        #expect(try q2.parse(&request) == Timestamp(rawValue: "t802"))
        #expect(
            try q2.print(Timestamp(rawValue: "t802")) == RFC_3986.URI.Request.Data(fragment: "t802")
        )

        // test parser builder initializer
        let p3 = URIFragment {
            "section1"
        }

        request = try #require(RFC_3986.URI.Request.Data(string: "#section1"))
        #expect(throws: Never.self) { try p3.parse(&request) }

        request = try #require(RFC_3986.URI.Request.Data(string: "#section2"))
        #expect(throws: (any Error).self) { try p3.parse(&request) }

        #expect(
            try p3.print() == RFC_3986.URI.Request.Data(fragment: "section1")
        )

        enum AppRoute: Equatable {
            case privacyPolicy(section: String)
        }

        // routing example
        let r = Route(.case(AppRoute.privacyPolicy(section:))) {
            Path {
                "legal"
                "privacy"
            }
            URIFragment()
        }

        request = try #require(RFC_3986.URI.Request.Data(string: "/legal/privacy#faq"))
        #expect(try r.parse(&request) == .privacyPolicy(section: "faq"))
        #expect(
            try r.print(.privacyPolicy(section: "faq"))
                == RFC_3986.URI.Request.Data(path: "/legal/privacy", fragment: "faq")
        )
    }

    @Test("Cookies parsing")
    func cookies() throws {
        struct Session: Equatable {
            var userId: Int
            var isAdmin: Bool
        }

        let p = Cookies {
            RFC_6265.Cookie.Field("userId") { Int.parser() }
            RFC_6265.Cookie.Field("isAdmin") { Bool.parser() }
        }
        .map(.memberwise(Session.init(userId:isAdmin:)))

        var request = RFC_3986.URI.Request.Data(headers: ["cookie": ["userId=42; isAdmin=true"]])
        #expect(try p.parse(&request) == Session(userId: 42, isAdmin: true))
        #expect(
            try p.print(Session(userId: 42, isAdmin: true))
                == RFC_3986.URI.Request.Data(headers: ["cookie": ["userId=42; isAdmin=true"]])
        )
    }

    @Test("JSON cookies parsing")
    func jsonCookies() throws {
        struct Session: Codable, Equatable {
            var userId: Int
        }

        let p = Cookies {
            RFC_6265.Cookie.Field("pf_session", .utf8.data.json(Session.self))
        }

        var request = RFC_3986.URI.Request.Data(headers: ["cookie": [#"pf_session={"userId":42}; foo=bar"#]])
        #expect(try p.parse(&request) == Session(userId: 42))
        #expect(
            try p.print(Session(userId: 42))
                == RFC_3986.URI.Request.Data(headers: ["cookie": [#"pf_session={"userId":42}"#]])
        )
    }

    @Test("Base URL routing")
    func baseURL() throws {
        enum AppRoute { case home, episodes }

        let router = OneOf {
            Route(AppRoute.home)
            Route(AppRoute.episodes) {
                Path { "episodes" }
            }
        }

        #expect(
            URLRequest(
                data:
                    try router
                    .baseURL("https://api.pointfree.co/v1?token=deadbeef")
                    .print(.episodes)
            )?.url?.absoluteString == "https://api.pointfree.co/v1/episodes?token=deadbeef"
        )

        #expect(
            URLRequest(
                data:
                    try router
                    .baseURL("http://localhost:8080/v1?token=deadbeef")
                    .print(.episodes)
            )?.url?.absoluteString == "http://localhost:8080/v1/episodes?token=deadbeef"
        )
    }
}
