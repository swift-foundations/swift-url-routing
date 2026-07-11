import Foundation
import Testing
import URLRouting

#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif

// Router-output enums hoisted for `@Cases`; conversion-only enums stay local.

@Cases
private enum TEMyRoute: Equatable {
    case get(Int)
    case list
}

@Cases
private enum TEItemRoute: Equatable {
    case item(Int)
}

@Cases
private enum TEAPIRoute: Equatable {
    case create
    case list
}

@Suite("Type Erasure")
struct TypeErasureTests {

    // Test basic AnyParserPrinter usage
    @Test("AnyParserPrinter erases concrete type")
    func anyParserPrinterBasic() throws {
        let concreteParser = Method.get
        let erased = AnyParserPrinter(concreteParser)

        var request = RFC_3986.URI.Request.Data(method: .get)
        #expect(throws: Never.self) { try erased.parse(&request) }
        #expect(try erased.print() == RFC_3986.URI.Request.Data(method: .get))
    }

    // Test existential router type matching production pattern
    @Test("Existential router with AnyParserPrinter")
    func existentialRouter() throws {
        typealias MyRoute = TEMyRoute

        struct MyRouter: ParserPrinter {
            var body: some URLRouting.Router<MyRoute> {
                OneOf {
                    Route(.case(MyRoute.cases.get)) {
                        Method.get
                        Path { Int.parser() }
                    }
                    Route(.case(MyRoute.cases.list)) {
                        Method.get
                    }
                }
            }
        }

        // Store router as existential type
        let router: any ParserPrinter<RFC_3986.URI.Request.Data, MyRoute> = AnyParserPrinter(MyRouter())

        let getRequest = RFC_3986.URI.Request.Data(method: .get, path: "/42")
        #expect(try router.parse(getRequest) == .get(42))
        #expect(try router.print(.get(42)) == RFC_3986.URI.Request.Data(method: .get, path: "/42"))

        let listRequest = RFC_3986.URI.Request.Data(method: .get, path: "/")
        #expect(try router.parse(listRequest) == .list)
        #expect(try router.print(.list) == RFC_3986.URI.Request.Data(method: .get, path: "/"))
    }

    // Test .eraseToAnyParserPrinter() convenience method
    @Test(".eraseToAnyParserPrinter() method")
    func eraseToAnyParserPrinterMethod() throws {
        typealias ItemRoute = TEItemRoute

        struct ItemRouter: ParserPrinter {
            var body: some URLRouting.Router<ItemRoute> {
                Route(.case(ItemRoute.cases.item)) {
                    Method.get
                    Path { Int.parser() }
                }
            }
        }

        let router = ItemRouter()
        let erased = router.eraseToAnyParserPrinter()

        let request = RFC_3986.URI.Request.Data(method: .get, path: "/123")
        #expect(try erased.parse(request) == .item(123))
        #expect(try erased.print(.item(123)) == RFC_3986.URI.Request.Data(method: .get, path: "/123"))
    }

    // Test composition with erased routers matching production pattern
    @Test("Composition with erased routers")
    func compositionWithErasedRouters() throws {
        typealias APIRoute = TEAPIRoute

        struct APIRouter: ParserPrinter {
            var body: some URLRouting.Router<APIRoute> {
                OneOf {
                    Route(.case(APIRoute.cases.create)) {
                        Method.post
                        Path { "create" }
                    }
                    Route(.case(APIRoute.cases.list)) {
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
        let router: any ParserPrinter<RFC_3986.URI.Request.Data, AppRoute> = erased

        let createRequest = RFC_3986.URI.Request.Data(method: .post, path: "/create")
        #expect(try router.parse(createRequest) == .api(.create))
        #expect(try router.print(.api(.create)) == RFC_3986.URI.Request.Data(method: .post, path: "/create"))
    }
}
