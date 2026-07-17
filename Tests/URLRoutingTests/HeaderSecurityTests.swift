import Foundation
import Testing
import URLRouting
import RFC_7230

@Suite
struct `Header Security Tests` {

    @Test
    func `CRLF injection in header values is rejected`() throws {
        let parser = Headers {
            RFC_7230.Header.Field.Parser("X-Custom-Header", .string)
        }

        // Test CR injection
        // The header-field validation error is wrapped into the unified routing error
        // at the `Headers` print boundary (its message preserves the CR/LF detail).
        #expect(throws: RFC_3986.URI.Routing.Error.self) {
            var request = RFC_3986.URI.Request.Data()
            try parser.print("value\rwith\rCR", into: &request)
        }

        // Test LF injection
        // The header-field validation error is wrapped into the unified routing error
        // at the `Headers` print boundary (its message preserves the CR/LF detail).
        #expect(throws: RFC_3986.URI.Routing.Error.self) {
            var request = RFC_3986.URI.Request.Data()
            try parser.print("value\nwith\nLF", into: &request)
        }

        // Test CRLF injection (classic header injection attack)
        // The header-field validation error is wrapped into the unified routing error
        // at the `Headers` print boundary (its message preserves the CR/LF detail).
        #expect(throws: RFC_3986.URI.Routing.Error.self) {
            var request = RFC_3986.URI.Request.Data()
            try parser.print("value\r\nX-Evil: injected", into: &request)
        }

        // Test CRLF with body injection
        // The header-field validation error is wrapped into the unified routing error
        // at the `Headers` print boundary (its message preserves the CR/LF detail).
        #expect(throws: RFC_3986.URI.Routing.Error.self) {
            var request = RFC_3986.URI.Request.Data()
            try parser.print("normal\r\n\r\n<script>alert('xss')</script>", into: &request)
        }
    }

    @Test
    func `Valid header values are accepted`() throws {
        let parser = Headers {
            RFC_7230.Header.Field.Parser("X-Custom-Header", .string)
        }

        // Standard header value
        do {
            var request = RFC_3986.URI.Request.Data()
            try parser.print("application/json", into: &request)
            #expect(request.headers["x-custom-header"]?.first??.description == "application/json")
        }

        // Value with spaces
        do {
            var request = RFC_3986.URI.Request.Data()
            try parser.print("Bearer token123", into: &request)
            #expect(request.headers["x-custom-header"]?.first??.description == "Bearer token123")
        }

        // Value with special characters (but no CRLF)
        do {
            var request = RFC_3986.URI.Request.Data()
            try parser.print("text/html; charset=utf-8", into: &request)
            #expect(request.headers["x-custom-header"]?.first??.description == "text/html; charset=utf-8")
        }
    }

    @Test
    func `Content-Type header with CRLF is rejected`() throws {
        // `Prefix { … }` (pointfree) was a printer; the institute `Parser.Prefix.While`
        // is parse-only, so the Content-Type value uses the bidirectional `Rest()` —
        // it echoes the whole value through header-field validation, which is what this
        // CRLF-rejection test exercises.
        let parser = Headers {
            ContentType { Rest() }
        }

        // The header-field validation error is wrapped into the unified routing error
        // at the `Headers` print boundary (its message preserves the CR/LF detail).
        #expect(throws: RFC_3986.URI.Routing.Error.self) {
            var request = RFC_3986.URI.Request.Data()
            try parser.print("text/html\r\nX-Evil: injected", into: &request)
        }
    }

    @Test
    func `Multiple header values without CRLF`() throws {
        let parser = Headers {
            RFC_7230.Header.Field.Parser("X-Custom-Header", .string)
        }

        var request = RFC_3986.URI.Request.Data()
        try parser.print("value1", into: &request)
        try parser.print("value2", into: &request)

        let values = request.headers["x-custom-header"]
        #expect(values?.count == 2)
        #expect(values?.first??.description == "value2")  // Last printed is first
        #expect(values?.last??.description == "value1")
    }
}
