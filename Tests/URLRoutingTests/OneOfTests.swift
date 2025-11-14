import Foundation
import Parsing
import Testing
import URLRouting

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

@Suite("OneOf Combinator")
struct OneOfTests {

  // Test OneOf with simple route alternatives
  @Test("OneOf with method alternatives")
  func methodAlternatives() throws {
    let parser = OneOf {
      Method.get
      Method.post
    }

    var getRequest = URIRequestData(method: "GET")
    #expect(throws: Never.self) { try parser.parse(&getRequest) }

    var postRequest = URIRequestData(method: "POST")
    #expect(throws: Never.self) { try parser.parse(&postRequest) }

    var putRequest = URIRequestData(method: "PUT")
    #expect(throws: (any Error).self) { try parser.parse(&putRequest) }
  }

  // Test OneOf with path alternatives matching production pattern
  @Test("OneOf with path alternatives")
  func pathAlternatives() throws {
    enum TestRoute: Equatable {
      case api
      case view
    }

    struct TestRouter: ParserPrinter {
      var body: some URLRouting.Router<TestRoute> {
        OneOf {
          Route(.case(TestRoute.api)) {
            Path { "api" }
          }
          Route(.case(TestRoute.view)) {
            Path { "view" }
          }
        }
      }
    }

    let router = TestRouter()

    // Test parsing
    let apiRequest = URIRequestData(path: "/api")
    #expect(try router.parse(apiRequest) == .api)

    let viewRequest = URIRequestData(path: "/view")
    #expect(try router.parse(viewRequest) == .view)

    // Test printing
    #expect(try router.print(.api) == URIRequestData(path: "/api"))
    #expect(try router.print(.view) == URIRequestData(path: "/view"))
  }

  // Test OneOf with nested routers matching production pattern
  @Test("OneOf with nested routers")
  func nestedRouters() throws {
    enum APIRoute: Equatable {
      case create
      case list
    }

    struct APIRouter: ParserPrinter {
      var body: some URLRouting.Router<APIRoute> {
        OneOf {
          Route(.case(APIRoute.create)) {
            Method.post
            Path { "create" }
          }
          Route(.case(APIRoute.list)) {
            Method.get
            Path { "list" }
          }
        }
      }
    }

    enum MainRoute: Equatable {
      case api(APIRoute)
    }

    struct MainRouter: ParserPrinter {
      var body: some URLRouting.Router<MainRoute> {
        Route(.case(MainRoute.api)) {
          Path { "api" }
          APIRouter()
        }
      }
    }

    let router = MainRouter()

    // Test nested API routes
    let createRequest = URIRequestData(method: "POST", path: "/api/create")
    #expect(try router.parse(createRequest) == .api(.create))

    let listRequest = URIRequestData(method: "GET", path: "/api/list")
    #expect(try router.parse(listRequest) == .api(.list))

    // Test printing
    #expect(try router.print(.api(.create)) == URIRequestData(method: "POST", path: "/api/create"))
    #expect(try router.print(.api(.list)) == URIRequestData(method: "GET", path: "/api/list"))
  }

  // Test OneOf with complex route combinations
  @Test("OneOf with method and path combinations")
  func methodAndPathCombinations() throws {
    enum RESTRoute: Equatable {
      case list
      case create
      case get(Int)
      case update(Int)
      case delete(Int)
    }

    struct RESTRouter: ParserPrinter {
      var body: some URLRouting.Router<RESTRoute> {
        OneOf {
          Route(.case(RESTRoute.list)) {
            Method.get
          }
          Route(.case(RESTRoute.create)) {
            Method.post
          }
          Route(.case(RESTRoute.get)) {
            Method.get
            Path { Int.parser() }
          }
          Route(.case(RESTRoute.update)) {
            Method.patch
            Path { Int.parser() }
          }
          Route(.case(RESTRoute.delete)) {
            Method.delete
            Path { Int.parser() }
          }
        }
      }
    }

    let router = RESTRouter()

    // Test all CRUD operations
    #expect(try router.parse(URIRequestData(method: "GET", path: "/")) == .list)
    #expect(try router.parse(URIRequestData(method: "POST", path: "/")) == .create)
    #expect(try router.parse(URIRequestData(method: "GET", path: "/42")) == .get(42))
    #expect(try router.parse(URIRequestData(method: "PATCH", path: "/42")) == .update(42))
    #expect(try router.parse(URIRequestData(method: "DELETE", path: "/42")) == .delete(42))

    // Test printing
    #expect(try router.print(.list) == URIRequestData(method: "GET", path: "/"))
    #expect(try router.print(.create) == URIRequestData(method: "POST", path: "/"))
    #expect(try router.print(.get(42)) == URIRequestData(method: "GET", path: "/42"))
    #expect(try router.print(.update(42)) == URIRequestData(method: "PATCH", path: "/42"))
    #expect(try router.print(.delete(42)) == URIRequestData(method: "DELETE", path: "/42"))
  }
}
