import Foundation
import Testing
import URLRouting

// Router-output enum hoisted to file scope for `@Cases` (macro does not apply to
// function-local types). `private` keeps it file-scoped.

private struct ContactForm: Codable, Equatable {
    var name: String
    var age: Int
}

@Cases
private enum FormBodyRoute: Equatable {
    case submit(ContactForm)
}

private struct FormRouter: ParserPrinter, Sendable {
    var body: some URLRouting.Router<FormBodyRoute> {
        URLRouting.Route(.case(FormBodyRoute.cases.submit)) {
            Method.post
            Path { "contact" }
            URLRouting.Body(.form(ContactForm.self))
        }
    }
}

/// Route-level `.form` Body coverage.
///
/// The suite previously exercised `Form.Conversion` only as a standalone conversion
/// (`Conversions/FormConversionTests.swift`); the composed `URLRouting.Body(.form(…))`
/// inside a `Route { … }` was unexercised, leaving its Failure-collapse behavior
/// unpinned. These tests pin it: the Skip-chain's `Either` failure collapses into
/// `RFC_3986.URI.Routing.Error` at the `Route` node, exactly as the `.json` Body
/// path does — parse, print, and round-trip.
@Suite
struct Test {

    @Test
    func `Parse: explicit form-encoded request`() throws {
        let router = FormRouter()
        let request = RFC_3986.URI.Request.Data(
            method: .post,
            path: "/contact",
            body: Foundation.Data("name=Jane&age=30".utf8)
        )
        #expect(try router.parse(request) == .submit(ContactForm(name: "Jane", age: 30)))
    }

    @Test
    func `Print: emits method, path, and form body`() throws {
        let router = FormRouter()
        var data = RFC_3986.URI.Request.Data()
        try router.print(.submit(ContactForm(name: "Jane", age: 30)), into: &data)

        #expect(data.method == .post)
        #expect(data.path.map(String.init) == ["contact"])
        #expect(data.body != nil)
        #expect(!(data.body ?? Foundation.Data()).isEmpty)
    }

    @Test
    func `Round-trip: print then parse`() throws {
        let router = FormRouter()

        for form in [
            ContactForm(name: "Jane", age: 30),
            ContactForm(name: "hello world & more", age: 0),
        ] {
            let route = FormBodyRoute.submit(form)
            var data = RFC_3986.URI.Request.Data()
            try router.print(route, into: &data)
            #expect(try router.parse(data) == route)
        }
    }
}
