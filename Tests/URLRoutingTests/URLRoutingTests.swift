import Foundation
import Parsing
import Testing
import URLRouting

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

@Suite("URL Routing")
struct URLRoutingTests {

  @Test("Method parser")
  func method() throws {
    var request = URIRequestData(method: "POST")
    #expect(throws: Never.self) { try Method.post.parse(&request) }
    #expect(try Method.post.print() == URIRequestData(method: "POST"))
  }

  @Test("Host parser")
  func host() throws {
    var request = URIRequestData(host: "foo")
    #expect(throws: Never.self) { try Host.custom("foo").parse(&request) }
    #expect(try Host.custom("foo").print() == URIRequestData(host: "foo"))
  }

  @Test("Scheme parser")
  func scheme() throws {
    var request = URIRequestData(scheme: "http")
    #expect(throws: Never.self) { try Scheme.http.parse(&request) }
    #expect(try Scheme.http.print() == URIRequestData(scheme: "http"))
  }

  @Test("Path parser with integer")
  func pathWithInt() throws {
    #expect(try Path { Int.parser() }.parse(URIRequestData(path: "/123")) == 123)
  }

  @Test("Path parser error formatting")
  func pathError() throws {
    do {
      _ = try Path { Int.parser() }.parse(URIRequestData(path: "/123-foo"))
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
        Field("name", .string)
        Field("age") { Int.parser() }
      }
    }

    var request = URIRequestData(body: .init("name=Blob&age=42&debug=1".utf8))
    let (name, age) = try p.parse(&request)
    #expect(name == "Blob")
    #expect(age == 42)
    #expect(request.body.map { String(decoding: $0, as: UTF8.self) } == "debug=1")
  }

  @Test("Headers parsing")
  func headers() throws {
    let p = Headers {
      Field("X-Haha", .string)
    }

    var req = URLRequest(url: URL(string: "/")!)
    req.addValue("Hello", forHTTPHeaderField: "X-Haha")
    req.addValue("Blob", forHTTPHeaderField: "X-Haha")
    let requestData = try #require(URIRequestData(request: req))
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
      Field("name")
      Field("age") { Int.parser() }
    }

    var request = try #require(URIRequestData(string: "/?name=Blob&age=42&debug=1"))
    let (name, age) = try p.parse(&request)
    #expect(name == "Blob")
    #expect(age == 42)

    let remaining = request.query
    #expect(remaining["debug"]?.first??.description == "1")

    #expect(
      try p.print(("Blob", 42)) == URIRequestData(query: ["name": ["Blob"], "age": ["42"]])
    )
  }

  @Test("Query with default value")
  func queryDefault() throws {
    let p = Query {
      Field("page", default: 1) {
        Int.parser()
      }
    }

    var request = try #require(URIRequestData(string: "/"))
    let page = try p.parse(&request)
    #expect(page == 1)
    #expect(request.query.isEmpty)

    #expect(
      try p.print(10) == URIRequestData(query: ["page": ["10"]])
    )
    #expect(
      try p.print(1) == URIRequestData(query: [:])
    )
  }

  @Test("Fragment parsing")
  func fragment() throws {
    // test default initializer
    let q1 = URIFragment()

    var request = try #require(URIRequestData(string: "#fragment"))
    #expect(try q1.parse(&request) == "fragment")
    #expect(try q1.print("fragment") == URIRequestData(fragment: "fragment"))

    struct Timestamp: Equatable, RawRepresentable {
      let rawValue: String
    }

    // test conversion initializer
    let q2 = URIFragment(.string.representing(Timestamp.self))
    request = try #require(
      URIRequestData(string: "https://www.pointfree.co/episodes/ep182-invertible-parsing-map#t802")
    )
    #expect(try q2.parse(&request) == Timestamp(rawValue: "t802"))
    #expect(
      try q2.print(Timestamp(rawValue: "t802")) == URIRequestData(fragment: "t802")
    )

    // test parser builder initializer
    let p3 = URIFragment {
      "section1"
    }

    request = try #require(URIRequestData(string: "#section1"))
    #expect(throws: Never.self) { try p3.parse(&request) }

    request = try #require(URIRequestData(string: "#section2"))
    #expect(throws: (any Error).self) { try p3.parse(&request) }

    #expect(
      try p3.print() == URIRequestData(fragment: "section1")
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

    request = try #require(URIRequestData(string: "/legal/privacy#faq"))
    #expect(try r.parse(&request) == .privacyPolicy(section: "faq"))
    #expect(
      try r.print(.privacyPolicy(section: "faq")) == URIRequestData(path: "/legal/privacy", fragment: "faq")
    )
  }

  @Test("Cookies parsing")
  func cookies() throws {
    struct Session: Equatable {
      var userId: Int
      var isAdmin: Bool
    }

    let p = Cookies {
      Field("userId") { Int.parser() }
      Field("isAdmin") { Bool.parser() }
    }
    .map(.memberwise(Session.init(userId:isAdmin:)))

    var request = URIRequestData(headers: ["cookie": ["userId=42; isAdmin=true"]])
    #expect(try p.parse(&request) == Session(userId: 42, isAdmin: true))
    #expect(
      try p.print(Session(userId: 42, isAdmin: true)) == URIRequestData(headers: ["cookie": ["userId=42; isAdmin=true"]])
    )
  }

  @Test("JSON cookies parsing")
  func jsonCookies() throws {
    struct Session: Codable, Equatable {
      var userId: Int
    }

    let p = Cookies {
      Field("pf_session", .utf8.data.json(Session.self))
    }

    var request = URIRequestData(headers: ["cookie": [#"pf_session={"userId":42}; foo=bar"#]])
    #expect(try p.parse(&request) == Session(userId: 42))
    #expect(
      try p.print(Session(userId: 42)) == URIRequestData(headers: ["cookie": [#"pf_session={"userId":42}"#]])
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
        data: try router
          .baseURL("https://api.pointfree.co/v1?token=deadbeef")
          .print(.episodes)
      )?.url?.absoluteString == "https://api.pointfree.co/v1/episodes?token=deadbeef"
    )

    #expect(
      URLRequest(
        data: try router
          .baseURL("http://localhost:8080/v1?token=deadbeef")
          .print(.episodes)
      )?.url?.absoluteString == "http://localhost:8080/v1/episodes?token=deadbeef"
    )
  }
}
