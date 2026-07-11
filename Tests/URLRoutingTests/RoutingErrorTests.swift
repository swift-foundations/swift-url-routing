import Foundation
import Testing
import URLRouting

// All routing types hoisted to file scope so `@Cases` can synthesize the `.cases`
// witnesses (the macro does not apply to function-local types). Multi-value cases
// carry NO argument labels so their synthesized `Case.Path` tuple matches the
// builder's unlabeled `(A, B)` output.

@Cases
private enum RE_BookRoute {
    case fetch
}

private struct Options {
    var sort: Sort = .name
    var direction: Direction = .asc
    var count: Int = 10

    enum Direction: String, CaseIterable, Decodable {
        case asc, desc
    }
    enum Sort: String, CaseIterable, Decodable {
        case name
        case category = "category"
    }
}

@Cases
private enum BooksRoute {
    case book(UUID, RE_BookRoute)
    case search(Options)
}

@Cases
private enum UserRoute {
    case books(BooksRoute)
    case fetch
}

private struct CreateUser: Codable {
    let bio: String
    let name: String
}

@Cases
private enum UsersRoute {
    case create(CreateUser)
    case user(Int, UserRoute)
}

@Cases
private enum SiteRoute {
    case aboutUs
    case contactUs
    case home
    case users(UsersRoute)
}

private struct BookRouter: ParserPrinter {
    var body: some URLRouting.Router<RE_BookRoute> {
        Route(.case(RE_BookRoute.cases.fetch))
    }
}

private struct BooksRouter: ParserPrinter {
    var body: some URLRouting.Router<BooksRoute> {
        OneOf {
            Route(.case(BooksRoute.cases.book)) {
                Path { UUID.parser() }
                BookRouter()
            }
            Route(.case(BooksRoute.cases.search)) {
                Path { "search" }
                // The builder pairs left-associatively, so three fields arrive as the
                // nested tuple `((Sort, Direction), Int)` rather than a flat 3-tuple.
                Parse(
                    .memberwise(
                        { (values: ((Options.Sort, Options.Direction), Int)) in
                            Options(sort: values.0.0, direction: values.0.1, count: values.1)
                        },
                        { (($0.sort, $0.direction), $0.count) }
                    )
                ) {
                    Query {
                        RFC_3986.URI.Query.Field("sort", default: .name) { Options.Sort.parser() }
                        RFC_3986.URI.Query.Field("direction", default: .asc) { Options.Direction.parser() }
                        RFC_3986.URI.Query.Field("count", default: 10) { Int.parser() }
                    }
                }
            }
        }
    }
}

private struct UserRouter: ParserPrinter {
    var body: some URLRouting.Router<UserRoute> {
        OneOf {
            Route(.case(UserRoute.cases.books)) {
                Path { "books" }
                BooksRouter()
            }

            Route(.case(UserRoute.cases.fetch))
        }
    }
}

private struct UsersRouter: ParserPrinter {
    var body: some URLRouting.Router<UsersRoute> {
        OneOf {
            Route(.case(UsersRoute.cases.create)) {
                Method.post
                RFC_7230.Body.Parser(.json(CreateUser.self))
            }

            Route(.case(UsersRoute.cases.user)) {
                Path { Int.parser() }
                UserRouter()
            }
        }
    }
}

private struct SiteRouter: ParserPrinter {
    var body: some URLRouting.Router<SiteRoute> {
        OneOf {
            Route(.case(SiteRoute.cases.aboutUs)) {
                Path { "about-us" }
            }
            Route(.case(SiteRoute.cases.contactUs)) {
                Path { "contact-us" }
            }
            Route(.case(SiteRoute.cases.home))

            Route(.case(SiteRoute.cases.users)) {
                Path { "users" }
                UsersRouter()
            }
        }
    }
}

@Suite("Routing Error Formatting")
struct RoutingErrorTests {
    @Test("Complex router rejects unmatched input")
    func complexRouterError() throws {
        // "/123" matches none of the site routes; parsing must throw a routing error.
        #expect(throws: RFC_3986.URI.Routing.Error.self) {
            _ = try SiteRouter().parse(RFC_3986.URI.Request.Data(path: "/123"))
        }
    }
}
