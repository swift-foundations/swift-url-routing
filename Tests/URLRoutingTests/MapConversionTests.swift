import Foundation
import Parsing
import Testing
import URLRouting

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

@Suite("Map and Conversion")
struct MapConversionTests {

  // Test basic .map() with conversion on router
  @Test(".map() with conversion for route transformation")
  func mapWithConversion() throws {
    enum InnerRoute: Equatable {
      case item(Int)
      case list
    }

    struct InnerRouter: ParserPrinter {
      var body: some URLRouting.Router<InnerRoute> {
        OneOf {
          Route(.case(InnerRoute.item)) {
            Method.get
            Path { Int.parser() }
          }
          Route(.case(InnerRoute.list)) {
            Method.get
          }
        }
      }
    }

    enum OuterRoute: Equatable {
      case inner(InnerRoute)
      case other
    }

    // Create a mapped router that wraps InnerRoute in OuterRoute.inner
    let innerRouter = InnerRouter()
    let mappedRouter = innerRouter.map(
      .convert(
        apply: OuterRoute.inner,
        unapply: { route in
          if case .inner(let inner) = route { return inner }
          return nil
        }
      )
    )

    // Test parsing with mapped router
    let itemRequest = URIRequestData(method: "GET", path: "/42")
    #expect(try mappedRouter.parse(itemRequest) == .inner(.item(42)))

    let listRequest = URIRequestData(method: "GET", path: "/")
    #expect(try mappedRouter.parse(listRequest) == .inner(.list))

    // Test printing with mapped router
    #expect(try mappedRouter.print(.inner(.item(42))) == URIRequestData(method: "GET", path: "/42"))
    #expect(try mappedRouter.print(.inner(.list)) == URIRequestData(method: "GET", path: "/"))
  }

  // Test function-based conversion matching production pattern
  @Test(".map() with function conversion")
  func mapWithFunctionConversion() throws {
    enum ItemRoute: Equatable {
      case get(Int)
      case list
    }

    enum AppRoute: Equatable {
      case items(ItemRoute)
      case home

      static func extractItems(_ route: AppRoute) -> ItemRoute? {
        if case .items(let itemRoute) = route {
          return itemRoute
        }
        return nil
      }
    }

    struct ItemRouter: ParserPrinter {
      var body: some URLRouting.Router<ItemRoute> {
        OneOf {
          Route(.case(ItemRoute.get)) {
            Method.get
            Path { Int.parser() }
          }
          Route(.case(ItemRoute.list)) {
            Method.get
          }
        }
      }
    }

    let itemRouter = ItemRouter()
    let appRouter = itemRouter.map(
      .convert(
        apply: AppRoute.items,
        unapply: AppRoute.extractItems
      )
    )

    // Test parsing
    let getRequest = URIRequestData(method: "GET", path: "/42")
    let result = try appRouter.parse(getRequest)
    #expect(result == .items(.get(42)))

    // Test printing
    #expect(try appRouter.print(.items(.get(42))) == URIRequestData(method: "GET", path: "/42"))
  }

  // Test composition with .map() matching repotraffic pattern
  @Test("Router composition with .map()")
  func routerComposition() throws {
    enum APIRoute: Equatable {
      case get(Int)
      case list
    }

    struct APIRouter: ParserPrinter {
      var body: some URLRouting.Router<APIRoute> {
        OneOf {
          Route(.case(APIRoute.get)) {
            Method.get
            Path { Int.parser() }
          }
          Route(.case(APIRoute.list)) {
            Method.get
          }
        }
      }
    }

    enum AppRoute: Equatable {
      case api(APIRoute)
      case home

      static func extractAPI(_ route: AppRoute) -> APIRoute? {
        if case .api(let apiRoute) = route {
          return apiRoute
        }
        return nil
      }
    }

    // Map API router to app router
    let apiRouter = APIRouter()
    let mappedAPIRouter = apiRouter.map(
      .convert(
        apply: AppRoute.api,
        unapply: AppRoute.extractAPI
      )
    )

    // Test that the mapped router works
    let getRequest = URIRequestData(method: "GET", path: "/42")
    #expect(try mappedAPIRouter.parse(getRequest) == .api(.get(42)))

    let listRequest = URIRequestData(method: "GET", path: "/")
    #expect(try mappedAPIRouter.parse(listRequest) == .api(.list))

    // Test printing
    #expect(try mappedAPIRouter.print(.api(.get(42))) == URIRequestData(method: "GET", path: "/42"))
    #expect(try mappedAPIRouter.print(.api(.list)) == URIRequestData(method: "GET", path: "/"))
  }

  // Test chained .map() operations
  @Test("Chained .map() transformations")
  func chainedMaps() throws {
    enum Level1: Equatable {
      case value(Int)
    }

    enum Level2: Equatable {
      case level1(Level1)
    }

    enum Level3: Equatable {
      case level2(Level2)
    }

    struct Level1Router: ParserPrinter {
      var body: some URLRouting.Router<Level1> {
        Route(.case(Level1.value)) {
          Method.get
          Path { Int.parser() }
        }
      }
    }

    let router1 = Level1Router()
    let router2 = router1.map(.convert(
      apply: Level2.level1,
      unapply: { if case .level1(let v) = $0 { return v }; return nil }
    ))
    let router3 = router2.map(.convert(
      apply: Level3.level2,
      unapply: { if case .level2(let v) = $0 { return v }; return nil }
    ))

    // Test parsing through all layers
    let request = URIRequestData(method: "GET", path: "/42")
    #expect(try router3.parse(request) == .level2(.level1(.value(42))))

    // Test printing through all layers
    #expect(try router3.print(.level2(.level1(.value(42)))) == URIRequestData(method: "GET", path: "/42"))
  }
}
