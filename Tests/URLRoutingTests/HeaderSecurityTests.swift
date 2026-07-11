import Foundation
import Testing
import URLRouting
import RFC_7230

@Suite("Header Security Tests")
struct HeaderSecurityTests {

    @Test("CRLF injection in header values is rejected")
    func testCRLFInjectionRejected() throws {
        let parser = Headers {
            RFC_7230.Header.Field.Parser("X-Custom-Header", .string)
        }

        // Test CR injection
        #expect(throws: RFC_7230.Header.Field.ValidationError.self) {
            var request = RFC_3986.URI.Request.Data()
            try parser.print("value\rwith\rCR", into: &request)
        }

        // Test LF injection
        #expect(throws: RFC_7230.Header.Field.ValidationError.self) {
            var request = RFC_3986.URI.Request.Data()
            try parser.print("value\nwith\nLF", into: &request)
        }

        // Test CRLF injection (classic header injection attack)
        #expect(throws: RFC_7230.Header.Field.ValidationError.self) {
            var request = RFC_3986.URI.Request.Data()
            try parser.print("value\r\nX-Evil: injected", into: &request)
        }

        // Test CRLF with body injection
        #expect(throws: RFC_7230.Header.Field.ValidationError.self) {
            var request = RFC_3986.URI.Request.Data()
            try parser.print("normal\r\n\r\n<script>alert('xss')</script>", into: &request)
        }
    }

    @Test("Valid header values are accepted")
    func testValidHeaderValues() throws {
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

    @Test("Content-Type header with CRLF is rejected")
    func testContentTypeCRLFRejected() throws {
        let parser = Headers {
            ContentType { Prefix { $0 != ";" } }
        }

        #expect(throws: RFC_7230.Header.Field.ValidationError.self) {
            var request = RFC_3986.URI.Request.Data()
            try parser.print("text/html\r\nX-Evil: injected", into: &request)
        }
    }

    @Test("Multiple header values without CRLF")
    func testMultipleHeaderValues() throws {
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
