import Foundation
import Testing
import URLRouting
import WHATWG_HTML_Forms

#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif

/// Tests demonstrating throwing function support in parser builder closures.
///
/// The throwing support allows parser *construction* to throw, which is useful when:
/// 1. Building parsers conditionally based on configuration that might fail
/// 2. Using throwing factory functions to create parsers
/// 3. Loading parser configuration from external sources
@Suite("Throwing Functions Support")
struct ThrowingFunctionsTests {

    // MARK: - Domain Types

    enum ParserConfigurationError: Error, Equatable {
        case invalidConfiguration(String)
    }

    /// Factory function that creates a parser (demonstrates throwing support in parser construction)
    static func makeEmailParser() throws -> some Parser<Substring, String> {
        return Rest().map(.string)
    }

    /// Conditional parser factory
    static func makeConditionalParser(useStrict: Bool) throws -> Parsers.MapConversion<Rest<Substring>, Conversions.SubstringToString> {
        // In real code, this might check configuration that could fail
        // For this example, we just return the same parser
        return Rest().map(.string)
    }

    // MARK: - Tests Demonstrating Throwing Support

    @Test("Parser builder CAN use throwing factory functions")
    func parserBuilderCanUseThrowingFactory() throws {
        // ✅ Now we CAN use throwing functions during parser construction!
        let parser = try Query {
            try RFC_3986.URI.Query.Field("email") {
                try Self.makeEmailParser()
            }
        }

        var request = try #require(RFC_3986.URI.Request.Data(string: "/?email=user@example.com"))
        let result = try parser.parse(&request)
        #expect(result == "user@example.com")
    }

    @Test("Conditional parser construction with throwing")
    func conditionalParserConstruction() throws {
        // ✅ Throwing allows conditional parser construction
        let strictParser = try Query {
            try RFC_3986.URI.Query.Field("email") {
                try Self.makeConditionalParser(useStrict: true)
            }
        }

        let lenientParser = try Query {
            try RFC_3986.URI.Query.Field("email") {
                try Self.makeConditionalParser(useStrict: false)
            }
        }

        var request1 = try #require(RFC_3986.URI.Request.Data(string: "/?email=user"))
        let result1 = try strictParser.parse(&request1)
        #expect(result1 == "user")

        var request2 = try #require(RFC_3986.URI.Request.Data(string: "/?email=user@example.com"))
        let result2 = try lenientParser.parse(&request2)
        #expect(result2 == "user@example.com")
    }

    @Test("FormData parser builder with throwing factory")
    func formDataWithThrowingFactory() throws {
        let parser = try Body {
            try FormData {
                try Form.Data.Field("email") {
                    try Self.makeEmailParser()
                }
            }
        }

        var request = RFC_3986.URI.Request.Data(body: .init("email=user@example.com".utf8))
        let result = try parser.parse(&request)
        #expect(result == "user@example.com")
    }

    @Test("Path parser builder with throwing factory")
    func pathWithThrowingFactory() throws {
        func makeUserParser() throws -> Parsers.MapConversion<Rest<Substring>, Conversions.SubstringToString> {
            // Could throw during configuration loading
            return Rest().map(.string)
        }

        let parser = try Path {
            "user"
            try makeUserParser()
        }

        var request = RFC_3986.URI.Request.Data(path: "/user/john")
        let result = try parser.parse(&request)
        #expect(result == "john")
    }

    @Test("Backward compatibility - non-throwing construction still works")
    func backwardCompatibility() throws {
        // ✅ Non-throwing closures still work (backward compatible)
        let parser = Query {
            RFC_3986.URI.Query.Field("name", .string)
            RFC_3986.URI.Query.Field("age") { Int.parser() }
        }

        var request = try #require(RFC_3986.URI.Request.Data(string: "/?name=John&age=42"))
        let (name, age) = try parser.parse(&request)
        #expect(name == "John")
        #expect(age == 42)
    }

    @Test("Multiple fields with mixed throwing and non-throwing")
    func mixedThrowingAndNonThrowing() throws {
        func makeAgeParser() throws -> Parsers.IntParser<Substring.UTF8View, Int> {
            Int.parser()
        }

        let parser = try Query {
            RFC_3986.URI.Query.Field("name", .string)  // Non-throwing - no try needed!
            try RFC_3986.URI.Query.Field("email") {  // Throwing factory - needs try
                try Self.makeEmailParser()
            }
            try RFC_3986.URI.Query.Field("age") {  // Throwing factory - needs try
                try makeAgeParser()
            }
        }

        var request = try #require(
            RFC_3986.URI.Request.Data(string: "/?name=John&email=john@example.com&age=30")
        )
        let (name, email, age) = try parser.parse(&request)
        #expect(name == "John")
        #expect(email == "john@example.com")
        #expect(age == 30)
    }

    // MARK: - Regression Tests for Ambiguous Init

    @Test("Path with Rest().map() without explicit try should not be ambiguous")
    func pathWithMapNoExplicitTry() throws {
        // This reproduces the swift-mailgun-types pattern that caused ambiguous init errors
        let parser = Path {
            "api"
            Rest().map(.string)  // No explicit try - should not be ambiguous
        }

        var request = RFC_3986.URI.Request.Data(path: "/api/value")
        let result = try parser.parse(&request)
        #expect(result == "value")
    }

    @Test("Query with Field without explicit try should not be ambiguous")
    func queryWithFieldNoExplicitTry() throws {
        // Another pattern that could cause ambiguity
        let parser = Query {
            RFC_3986.URI.Query.Field("name") { Rest().map(.string) }  // No explicit try
        }

        var request = try #require(RFC_3986.URI.Request.Data(string: "/?name=test"))
        let result = try parser.parse(&request)
        #expect(result == "test")
    }

    @Test("Headers with Field without explicit try should not be ambiguous")
    func headersWithFieldNoExplicitTry() throws {
        // Test the Headers parser ambiguity
        let parser = Headers {
            RFC_7230.Header.Field.Parser("X-Custom") { Rest().map(.string) }  // No explicit try
        }

        var request = RFC_3986.URI.Request.Data()
        request.headers.fields["x-custom"] = ["value"]
        let result = try parser.parse(&request)
        #expect(result == "value")
    }

    @Test("Body with FormData Field without explicit try should not be ambiguous")
    func bodyWithFormDataFieldNoExplicitTry() throws {
        // Test Body parser ambiguity
        let parser = Body {
            FormData {
                Form.Data.Field("email") { Rest().map(.string) }  // No explicit try
            }
        }

        var request = RFC_3986.URI.Request.Data(body: .init("email=test@example.com".utf8))
        let result = try parser.parse(&request)
        #expect(result == "test@example.com")
    }

    // MARK: - ContentType Convenience Parser Tests

    @Test("ContentType with String literal")
    func contentTypeWithString() throws {
        let parser = Headers {
            ContentType { "multipart/form-data" }
        }

        var request = RFC_3986.URI.Request.Data()
        request.headers.fields["content-type"] = ["multipart/form-data"]
        let result = try parser.parse(&request)
        #expect(result == ())
    }

    @Test("ContentType with RFC_2045.ContentType.headerValue")
    func contentTypeWithRFC2045HeaderValue() throws {
        let contentType = RFC_2045.ContentType(
            type: "multipart",
            subtype: "form-data",
            parameters: ["boundary": "----boundary123"]
        )

        let parser = Headers {
            ContentType { contentType.headerValue }
        }

        var request = RFC_3986.URI.Request.Data()
        request.headers.fields["content-type"] = ["multipart/form-data; boundary=----boundary123"]
        let result = try parser.parse(&request)
        #expect(result == ())
    }
}
