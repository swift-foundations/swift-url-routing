import Foundation
import Testing
import URLRouting

#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif

// Router-output enums are hoisted to file scope so `@Cases` can synthesize their
// `.cases` witnesses (the macro does not apply to function-local types). Enums used
// only through `.convert(apply:unapply:)` (explicit closures) stay function-local.

@Cases
private enum InnerRoute: Equatable {
    case item(Int)
    case list
}

@Cases
private enum MapItemRoute: Equatable {
    case get(Int)
    case list
}

@Cases
private enum MapAPIRoute: Equatable {
    case get(Int)
    case list
}

@Cases
private enum Level1: Equatable {
    case value(Int)
}

@Suite
struct `Map Conversion Tests` {

    // Test basic .map() with conversion on router
    @Test
    func `.map() with conversion for route transformation`() throws {
        enum OuterRoute: Equatable {
            case inner(InnerRoute)
            case other
        }

        struct InnerRouter: ParserPrinter {
            var body: some URLRouting.Router<InnerRoute> {
                OneOf {
                    Route(.case(InnerRoute.cases.item)) {
                        Method.get
                        Path { Int.parser() }
                    }
                    Route(.case(InnerRoute.cases.list)) {
                        Method.get
                    }
                }
            }
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
        let itemRequest = RFC_3986.URI.Request.Data(method: .get, path: "/42")
        #expect(try mappedRouter.parse(itemRequest) == .inner(.item(42)))

        let listRequest = RFC_3986.URI.Request.Data(method: .get, path: "/")
        #expect(try mappedRouter.parse(listRequest) == .inner(.list))

        // Test printing with mapped router
        #expect(
            try mappedRouter.print(.inner(.item(42))) == RFC_3986.URI.Request.Data(method: .get, path: "/42")
        )
        #expect(try mappedRouter.print(.inner(.list)) == RFC_3986.URI.Request.Data(method: .get, path: "/"))
    }

    // Test function-based conversion matching production pattern
    @Test
    func `.map() with function conversion`() throws {
        enum AppRoute: Equatable {
            case items(MapItemRoute)
            case home

            static func extractItems(_ route: AppRoute) -> MapItemRoute? {
                if case .items(let itemRoute) = route {
                    return itemRoute
                }
                return nil
            }
        }

        struct ItemRouter: ParserPrinter {
            var body: some URLRouting.Router<MapItemRoute> {
                OneOf {
                    Route(.case(MapItemRoute.cases.get)) {
                        Method.get
                        Path { Int.parser() }
                    }
                    Route(.case(MapItemRoute.cases.list)) {
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
        let getRequest = RFC_3986.URI.Request.Data(method: .get, path: "/42")
        let result = try appRouter.parse(getRequest)
        #expect(result == .items(.get(42)))

        // Test printing
        #expect(try appRouter.print(.items(.get(42))) == RFC_3986.URI.Request.Data(method: .get, path: "/42"))
    }

    // Test composition with .map() matching repotraffic pattern
    @Test
    func `Router composition with .map()`() throws {
        struct APIRouter: ParserPrinter {
            var body: some URLRouting.Router<MapAPIRoute> {
                OneOf {
                    Route(.case(MapAPIRoute.cases.get)) {
                        Method.get
                        Path { Int.parser() }
                    }
                    Route(.case(MapAPIRoute.cases.list)) {
                        Method.get
                    }
                }
            }
        }

        enum AppRoute: Equatable {
            case api(MapAPIRoute)
            case home

            static func extractAPI(_ route: AppRoute) -> MapAPIRoute? {
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
        let getRequest = RFC_3986.URI.Request.Data(method: .get, path: "/42")
        #expect(try mappedAPIRouter.parse(getRequest) == .api(.get(42)))

        let listRequest = RFC_3986.URI.Request.Data(method: .get, path: "/")
        #expect(try mappedAPIRouter.parse(listRequest) == .api(.list))

        // Test printing
        #expect(
            try mappedAPIRouter.print(.api(.get(42))) == RFC_3986.URI.Request.Data(method: .get, path: "/42")
        )
        #expect(try mappedAPIRouter.print(.api(.list)) == RFC_3986.URI.Request.Data(method: .get, path: "/"))
    }

    // Test chained .map() operations
    @Test
    func `Chained .map() transformations`() throws {
        enum Level2: Equatable {
            case level1(Level1)
        }

        enum Level3: Equatable {
            case level2(Level2)
        }

        struct Level1Router: ParserPrinter {
            var body: some URLRouting.Router<Level1> {
                Route(.case(Level1.cases.value)) {
                    Method.get
                    Path { Int.parser() }
                }
            }
        }

        let router1 = Level1Router()
        let router2 = router1.map(
            .convert(
                apply: Level2.level1,
                unapply: {
                    if case .level1(let v) = $0 { return v }
                    return nil
                }
            )
        )
        let router3 = router2.map(
            .convert(
                apply: Level3.level2,
                unapply: {
                    if case .level2(let v) = $0 { return v }
                    return nil
                }
            )
        )

        // Test parsing through all layers
        let request = RFC_3986.URI.Request.Data(method: .get, path: "/42")
        #expect(try router3.parse(request) == .level2(.level1(.value(42))))

        // Test printing through all layers
        #expect(
            try router3.print(.level2(.level1(.value(42))))
                == RFC_3986.URI.Request.Data(method: .get, path: "/42")
        )
    }
}
