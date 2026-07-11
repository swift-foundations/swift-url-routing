import Foundation
import Testing
import URLRouting

#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif

// File-scope value types for the memberwise-group and body shapes. `private` keeps
// them file-scoped so the names may recur in other test files.

private struct Paging: Equatable {
    var limit: Int
    var cursor: String
}

private struct AddCollaborator: Codable, Equatable {
    var permission: String
}

@Suite("Optionally Combinator")
struct OptionallyTests {

    // MARK: - Shape 1: optional query Field (carrier: Fields, via Query over Data)

    @Test("Optionally query Field: parse present + absent")
    func optionalFieldParse() throws {
        let query = URLRouting.Query {
            Optionally { Field("page") { Int.parser() } }
        }

        // Present → .some, field consumed from the carrier.
        var present = RFC_3986.URI.Request.Data(query: ["page": ["3"]])
        #expect(try query.parse(&present) == .some(3))
        #expect(present.query.isEmpty)

        // Absent → nil, carrier untouched.
        let emptyData = RFC_3986.URI.Request.Data(query: [:])
        var absent = emptyData
        #expect(try query.parse(&absent) == Int?.none)
        #expect(absent == emptyData)
    }

    @Test("Optionally query Field: print some + none")
    func optionalFieldPrint() throws {
        let query = URLRouting.Query {
            Optionally { Field("page") { Int.parser() } }
        }

        // Some → field emitted; round-trips back to the same value.
        var some = RFC_3986.URI.Request.Data()
        try query.print(.some(7), into: &some)
        #expect(!some.query.isEmpty)
        #expect(try query.parse(&some) == .some(7))

        // None → nothing emitted.
        var none = RFC_3986.URI.Request.Data()
        try query.print(Int?.none, into: &none)
        #expect(none.query.isEmpty)
    }

    @Test("Optionally query Field: round-trip")
    func optionalFieldRoundTrip() throws {
        let query = URLRouting.Query {
            Optionally { Field("page") { Int.parser() } }
        }

        for value in [Int?.some(1), Int?.some(42), Int?.none] {
            var data = RFC_3986.URI.Request.Data()
            try query.print(value, into: &data)
            #expect(try query.parse(&data) == value)
        }
    }

    // MARK: - Shape 2: optional memberwise Query group (carrier: Data)

    // The group is built inline (not via a helper) because the memberwise
    // `Parse<Converted<…>>` carries `Failure == Either<RFC_3986.URI.Routing.Error,
    // Never>` (the L1 `Converted` node unions the upstream failure with the
    // conversion's total `Never`); in a full router the surrounding `Query` / `Route`
    // re-pins that to the routing domain, but standalone it cannot be named as a clean
    // `URLRouting.Router` opaque type. `Optionally` faithfully inherits that failure.

    @Test("Optionally memberwise group: parse full group")
    func optionalGroupParsePresent() throws {
        let group = Optionally {
            Parse(.memberwise(Paging.init, { ($0.limit, $0.cursor) })) {
                URLRouting.Query {
                    Field("limit") { Int.parser() }
                    Field("cursor") { Parse(.string) }
                }
            }
        }

        var data = RFC_3986.URI.Request.Data(query: ["limit": ["10"], "cursor": ["abc"]])
        #expect(try group.parse(&data) == .some(Paging(limit: 10, cursor: "abc")))
        #expect(data.query.isEmpty)
    }

    @Test("Optionally memberwise group: backtracks cleanly on partial consumption")
    func optionalGroupBacktrackNoLeak() throws {
        let group = Optionally {
            Parse(.memberwise(Paging.init, { ($0.limit, $0.cursor) })) {
                URLRouting.Query {
                    Field("limit") { Int.parser() }
                    Field("cursor") { Parse(.string) }
                }
            }
        }

        // "limit" present, required "cursor" absent: the group consumes "limit" then
        // fails on "cursor". Value-copy backtracking must restore the WHOLE carrier
        // (limit included) — this is the partial-consumption leak test.
        let original = RFC_3986.URI.Request.Data(query: ["limit": ["10"]])
        var data = original
        #expect(try group.parse(&data) == Paging?.none)
        #expect(data == original)  // "limit" was restored, not leaked
    }

    @Test("Optionally memberwise group: print some + none, round-trip")
    func optionalGroupPrint() throws {
        let group = Optionally {
            Parse(.memberwise(Paging.init, { ($0.limit, $0.cursor) })) {
                URLRouting.Query {
                    Field("limit") { Int.parser() }
                    Field("cursor") { Parse(.string) }
                }
            }
        }

        // Some → both fields emitted; round-trips.
        var some = RFC_3986.URI.Request.Data()
        try group.print(.some(Paging(limit: 5, cursor: "x")), into: &some)
        #expect(!some.query.isEmpty)
        #expect(try group.parse(&some) == .some(Paging(limit: 5, cursor: "x")))

        // None → nothing emitted.
        var none = RFC_3986.URI.Request.Data()
        try group.print(Paging?.none, into: &none)
        #expect(none.query.isEmpty)
    }

    // MARK: - Shape 3: optional Body (carrier: Data)

    private func bodyRouter() -> some URLRouting.Router<AddCollaborator?> {
        Optionally {
            URLRouting.Body(.json(AddCollaborator.self))
        }
    }

    @Test("Optionally Body: parse present + absent")
    func optionalBodyParse() throws {
        let router = bodyRouter()
        let payload = AddCollaborator(permission: "push")

        // Present → .some (round-tripped through print to avoid hand-encoding JSON).
        var present = RFC_3986.URI.Request.Data()
        try router.print(.some(payload), into: &present)
        #expect(present.body != nil)
        #expect(try router.parse(&present) == .some(payload))

        // Absent → nil, carrier untouched.
        let emptyData = RFC_3986.URI.Request.Data()
        var absent = emptyData
        #expect(try router.parse(&absent) == AddCollaborator?.none)
        #expect(absent == emptyData)
    }

    @Test("Optionally Body: print none emits nothing")
    func optionalBodyPrintNone() throws {
        let router = bodyRouter()

        var none = RFC_3986.URI.Request.Data()
        try router.print(AddCollaborator?.none, into: &none)
        #expect(none.body == nil)
    }

    @Test("Optionally Body: round-trip")
    func optionalBodyRoundTrip() throws {
        let router = bodyRouter()

        for value in [AddCollaborator?.some(.init(permission: "admin")), AddCollaborator?.none] {
            var data = RFC_3986.URI.Request.Data()
            try router.print(value, into: &data)
            #expect(try router.parse(&data) == value)
        }
    }
}
