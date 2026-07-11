import Foundation
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

        var getRequest = RFC_3986.URI.Request.Data(method: .get)
        #expect(throws: Never.self) { try parser.parse(&getRequest) }

        var postRequest = RFC_3986.URI.Request.Data(method: .post)
        #expect(throws: Never.self) { try parser.parse(&postRequest) }

        var putRequest = RFC_3986.URI.Request.Data(method: .put)
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
        let apiRequest = RFC_3986.URI.Request.Data(path: "/api")
        #expect(try router.parse(apiRequest) == .api)

        let viewRequest = RFC_3986.URI.Request.Data(path: "/view")
        #expect(try router.parse(viewRequest) == .view)

        // Test printing
        #expect(try router.print(.api) == RFC_3986.URI.Request.Data(path: "/api"))
        #expect(try router.print(.view) == RFC_3986.URI.Request.Data(path: "/view"))
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
        let createRequest = RFC_3986.URI.Request.Data(method: .post, path: "/api/create")
        #expect(try router.parse(createRequest) == .api(.create))

        let listRequest = RFC_3986.URI.Request.Data(method: .get, path: "/api/list")
        #expect(try router.parse(listRequest) == .api(.list))

        // Test printing
        #expect(
            try router.print(.api(.create)) == RFC_3986.URI.Request.Data(method: .post, path: "/api/create")
        )
        #expect(try router.print(.api(.list)) == RFC_3986.URI.Request.Data(method: .get, path: "/api/list"))
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
        #expect(try router.parse(RFC_3986.URI.Request.Data(method: .get, path: "/")) == .list)
        #expect(try router.parse(RFC_3986.URI.Request.Data(method: .post, path: "/")) == .create)
        #expect(try router.parse(RFC_3986.URI.Request.Data(method: .get, path: "/42")) == .get(42))
        #expect(try router.parse(RFC_3986.URI.Request.Data(method: .patch, path: "/42")) == .update(42))
        #expect(try router.parse(RFC_3986.URI.Request.Data(method: .delete, path: "/42")) == .delete(42))

        // Test printing
        #expect(try router.print(.list) == RFC_3986.URI.Request.Data(method: .get, path: "/"))
        #expect(try router.print(.create) == RFC_3986.URI.Request.Data(method: .post, path: "/"))
        #expect(try router.print(.get(42)) == RFC_3986.URI.Request.Data(method: .get, path: "/42"))
        #expect(try router.print(.update(42)) == RFC_3986.URI.Request.Data(method: .patch, path: "/42"))
        #expect(try router.print(.delete(42)) == RFC_3986.URI.Request.Data(method: .delete, path: "/42"))
    }
}
