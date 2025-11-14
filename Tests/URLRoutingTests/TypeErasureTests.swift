import Foundation
import Parsing
import Testing
import URLRouting

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

@Suite("Type Erasure")
struct TypeErasureTests {

  // Test basic AnyParserPrinter usage
  @Test("AnyParserPrinter erases concrete type")
  func anyParserPrinterBasic() throws {
    let concreteParser = Method.get
    let erased = AnyParserPrinter(concreteParser)

    var request = URIRequestData(method: "GET")
    #expect(throws: Never.self) { try erased.parse(&request) }
    #expect(try erased.print() == URIRequestData(method: "GET"))
  }

  // Test existential router type matching production pattern
  @Test("Existential router with AnyParserPrinter")
  func existentialRouter() throws {
    enum MyRoute: Equatable {
      case get(Int)
      case list
    }

    struct MyRouter: ParserPrinter {
      var body: some URLRouting.Router<MyRoute> {
        OneOf {
          Route(.case(MyRoute.get)) {
            Method.get
            Path { Int.parser() }
          }
          Route(.case(MyRoute.list)) {
            Method.get
          }
        }
      }
    }

    // Store router as existential type
    let router: any ParserPrinter<URIRequestData, MyRoute> = AnyParserPrinter(MyRouter())

    let getRequest = URIRequestData(method: "GET", path: "/42")
    #expect(try router.parse(getRequest) == .get(42))
    #expect(try router.print(.get(42)) == URIRequestData(method: "GET", path: "/42"))

    let listRequest = URIRequestData(method: "GET", path: "/")
    #expect(try router.parse(listRequest) == .list)
    #expect(try router.print(.list) == URIRequestData(method: "GET", path: "/"))
  }

  // Test .eraseToAnyParserPrinter() convenience method
  @Test(".eraseToAnyParserPrinter() method")
  func eraseToAnyParserPrinterMethod() throws {
    enum ItemRoute: Equatable {
      case item(Int)
    }

    struct ItemRouter: ParserPrinter {
      var body: some URLRouting.Router<ItemRoute> {
        Route(.case(ItemRoute.item)) {
          Method.get
          Path { Int.parser() }
        }
      }
    }

    let router = ItemRouter()
    let erased = router.eraseToAnyParserPrinter()

    let request = URIRequestData(method: "GET", path: "/123")
    #expect(try erased.parse(request) == .item(123))
    #expect(try erased.print(.item(123)) == URIRequestData(method: "GET", path: "/123"))
  }

  // Test composition with erased routers matching production pattern
  @Test("Composition with erased routers")
  func compositionWithErasedRouters() throws {
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

    enum AppRoute: Equatable {
      case api(APIRoute)

      static func extractAPI(_ route: AppRoute) -> APIRoute? {
        if case .api(let apiRoute) = route {
          return apiRoute
        }
        return nil
      }
    }

    // Map and erase to match production pattern
    let apiRouter = APIRouter()
    let mappedRouter = apiRouter.map(
      .convert(
        apply: AppRoute.api,
        unapply: AppRoute.extractAPI
      )
    )
    let erased = mappedRouter.eraseToAnyParserPrinter()

    // Store as existential type
    let router: any ParserPrinter<URIRequestData, AppRoute> = erased

    let createRequest = URIRequestData(method: "POST", path: "/create")
    #expect(try router.parse(createRequest) == .api(.create))
    #expect(try router.print(.api(.create)) == URIRequestData(method: "POST", path: "/create"))
  }
}
