import Foundation
import Parsing
import Testing
import URLRouting

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

    /// Factory function that creates a parser but might throw during construction
    static func makeEmailParser() throws -> some Parser<Substring, String> {
        // Simulate loading configuration that might fail
        guard ProcessInfo.processInfo.environment["DISABLE_EMAIL_VALIDATION"] == nil else {
            throw ParserConfigurationError.invalidConfiguration("Email validation is disabled")
        }

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
            try Field("email") {
                try Self.makeEmailParser()
            }
        }

        var request = try #require(URIRequestData(string: "/?email=user@example.com"))
        let result = try parser.parse(&request)
        #expect(result == "user@example.com")
    }

    @Test("Parser builder throws if factory function fails")
    func parserBuilderThrowsOnFactoryFailure() throws {
        // Set environment variable to cause factory to fail
        setenv("DISABLE_EMAIL_VALIDATION", "1", 1)
        defer { unsetenv("DISABLE_EMAIL_VALIDATION") }

        do {
            _ = try Query {
                try Field("email") {
                    try Self.makeEmailParser()
                }
            }
            Issue.record("Expected parser construction to throw")
        } catch let error as ParserConfigurationError {
            #expect(error == .invalidConfiguration("Email validation is disabled"))
        }
    }

    @Test("Conditional parser construction with throwing")
    func conditionalParserConstruction() throws {
        // ✅ Throwing allows conditional parser construction
        let strictParser = try Query {
            try Field("email") {
                try Self.makeConditionalParser(useStrict: true)
            }
        }

        let lenientParser = try Query {
            try Field("email") {
                try Self.makeConditionalParser(useStrict: false)
            }
        }

        var request1 = try #require(URIRequestData(string: "/?email=user"))
        let result1 = try strictParser.parse(&request1)
        #expect(result1 == "user")

        var request2 = try #require(URIRequestData(string: "/?email=user@example.com"))
        let result2 = try lenientParser.parse(&request2)
        #expect(result2 == "user@example.com")
    }

    @Test("FormData parser builder with throwing factory")
    func formDataWithThrowingFactory() throws {
        let parser = try Body {
            try FormData {
                try Field("email") {
                    try Self.makeEmailParser()
                }
            }
        }

        var request = URIRequestData(body: .init("email=user@example.com".utf8))
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

        var request = URIRequestData(path: "/user/john")
        let result = try parser.parse(&request)
        #expect(result == "john")
    }

    @Test("Backward compatibility - non-throwing construction still works")
    func backwardCompatibility() throws {
        // ✅ Non-throwing closures still work (backward compatible)
        let parser = Query {
            Field("name", .string)
            Field("age") { Int.parser() }
        }

        var request = try #require(URIRequestData(string: "/?name=John&age=42"))
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
            Field("name", .string)  // Non-throwing - no try needed!
            try Field("email") {  // Throwing factory - needs try
                try Self.makeEmailParser()
            }
            try Field("age") {  // Throwing factory - needs try
                try makeAgeParser()
            }
        }

        var request = try #require(
            URIRequestData(string: "/?name=John&email=john@example.com&age=30")
        )
        let (name, email, age) = try parser.parse(&request)
        #expect(name == "John")
        #expect(email == "john@example.com")
        #expect(age == 30)
    }
}
