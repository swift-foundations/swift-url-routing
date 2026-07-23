import Foundation
import Tagged_Primitives
import Testing
import URLRouting
import URL_Routing_Foundation_Integration

// Phantom tags: plain, empty enums that discriminate otherwise-identical
// identifiers at the type level.
private enum User {}
private enum Order {}
private enum Session {}

// Parallel-namespace suite: the vended surface extends a generic-constrained
// wrapper and returns generic parser-printers, so there is no non-generic own
// type to host the suite.
@Suite
struct `Tagged+parser Tests` {
    @Suite struct Unit {}
    @Suite struct `Edge Case` {}
    @Suite struct Integration {}
}

extension `Tagged+parser Tests`.Unit {
    @Test
    func `Int parser round-trips a tagged integer through a component`() throws {
        let parser = Tagged<User, Int>.parser()

        var input: Substring = "42"
        let value = try parser.parse(&input)

        #expect(value.underlying == 42)
        #expect(input.isEmpty)

        let printed: Substring = try parser.print(value)
        #expect(printed == "42")
    }

    @Test
    func `UUID parser round-trips a tagged identifier through a component`() throws {
        let parser = Tagged<Session, UUID>.parser()
        let uuid = UUID()

        var input = Substring(uuid.uuidString)
        let value = try parser.parse(&input)

        #expect(value.underlying == uuid)
        #expect(input.isEmpty)

        let printed: Substring = try parser.print(value)
        #expect(printed == Substring(uuid.uuidString))
    }
}

extension `Tagged+parser Tests`.`Edge Case` {
    @Test
    func `Int parser rejects a non-numeric component`() {
        let parser = Tagged<User, Int>.parser()
        var input: Substring = "not-a-number"

        #expect(throws: (any Swift.Error).self) {
            _ = try parser.parse(&input)
        }
    }

    @Test
    func `Int parser rejects a partially-numeric component`() {
        // A route component is atomic: `"42-foo"` is not an `Int`, so the whole
        // component fails rather than consuming the `42` prefix.
        let parser = Tagged<User, Int>.parser()
        var input: Substring = "42-foo"

        #expect(throws: (any Swift.Error).self) {
            _ = try parser.parse(&input)
        }
    }

    @Test
    func `UUID parser rejects a malformed component`() {
        let parser = Tagged<Session, UUID>.parser()
        var input: Substring = "not-a-uuid"

        #expect(throws: (any Swift.Error).self) {
            _ = try parser.parse(&input)
        }
    }
}

extension `Tagged+parser Tests`.Integration {
    @Test
    func `distinct phantom tags over the same underlying parse independently`() throws {
        // `Tagged<User, Int>` and `Tagged<Order, Int>` are DIFFERENT types over
        // the same `Underlying`; their parsers produce values that cannot be
        // cross-assigned. This test exercises both — that it type-checks at all
        // IS the phantom-distinctness check.
        let userParser = Tagged<User, Int>.parser()
        let orderParser = Tagged<Order, Int>.parser()

        var userInput: Substring = "7"
        let user = try userParser.parse(&userInput)

        var orderInput: Substring = "7"
        let order = try orderParser.parse(&orderInput)

        #expect(user.underlying == order.underlying)

        // Round-tripping through each keeps the wire form identical while the
        // Swift types stay distinct.
        let userPrinted: Substring = try userParser.print(user)
        let orderPrinted: Substring = try orderParser.print(order)
        #expect(userPrinted == "7")
        #expect(orderPrinted == "7")
    }
}
