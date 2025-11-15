import Testing
import Foundation
import URLRouting
import MultipartFormCoding
import RFC_2046

@Suite("RFC_2046.Multipart.Conversion Integration Tests")
struct MultipartConversionIntegrationTests {

    struct TestRequest: Codable, Equatable {
        let name: String
        let subscribed: Bool
    }

    @Test("RFC_2046.Multipart.Conversion exists and is accessible")
    func testConversionExists() {
        let conversion = RFC_2046.Multipart.Conversion(TestRequest.self)
        #expect(!conversion.boundary.value.isEmpty)
        #expect(conversion.contentType.type == "multipart")
        #expect(conversion.contentType.subtype == "form-data")
    }

    @Test("Conversion.multipart() static method works")
    func testStaticMultipartMethod() throws {
        // Use explicit type to initialize conversion
        let conversion = RFC_2046.Multipart.Conversion(TestRequest.self)
        let request = TestRequest(name: "John", subscribed: true)
        let data = try conversion.unapply(request)
        #expect(!data.isEmpty)
    }

    @Test("Generates valid multipart data")
    func testMultipartGeneration() throws {
        let conversion = RFC_2046.Multipart.Conversion(TestRequest.self)
        let request = TestRequest(name: "Test User", subscribed: false)

        let data = try conversion.unapply(request)
        let string = String(data: data, encoding: .utf8)!

        #expect(string.contains(conversion.boundary.value))
        #expect(string.contains("Content-Disposition"))
        #expect(string.contains("name"))
        #expect(string.contains("Test User"))
    }

    @Test("Array encoding with accumulate values strategy")
    func testArrayEncodingAccumulateValues() throws {
        struct RequestWithArray: Codable {
            let tags: [String]
        }

        let conversion = RFC_2046.Multipart.Conversion(
            RequestWithArray.self,
            arrayEncodingStrategy: .accumulateValues
        )
        let request = RequestWithArray(tags: ["swift", "ios"])
        let data = try conversion.unapply(request)
        let string = String(data: data, encoding: .utf8)!

        // Should repeat field name for each value
        let tagCount = string.components(separatedBy: "name=\"tags\"").count - 1
        #expect(tagCount == 2)
    }

    @Test("Array encoding with brackets strategy")
    func testArrayEncodingBrackets() throws {
        struct RequestWithArray: Codable {
            let tags: [String]
        }

        let conversion = RFC_2046.Multipart.Conversion(
            RequestWithArray.self,
            arrayEncodingStrategy: .brackets
        )
        let request = RequestWithArray(tags: ["swift", "ios"])
        let data = try conversion.unapply(request)
        let string = String(data: data, encoding: .utf8)!

        // Should use brackets notation
        #expect(string.contains("name=\"tags[]\""))
    }

    @Test("URL generation with Multipart convenience function")
    func testURLGenerationWithMultipart() throws {
        // Test the new clean Multipart() syntax
        struct UpdateRequest: Codable, Equatable {
            let description: String?

            init(description: String? = nil) {
                self.description = description
            }
        }

        enum API: Equatable {
            case update(id: String, request: UpdateRequest)
        }

        struct Router: ParserPrinter {
            var body: some URLRouting.Router<API> {
                RFC_3986.URI.Route(.case(API.update)) {
                    Method.put
                    Path { "v3" }
                    Path { "routes" }
                    Path { Parse(.string) }
                    Multipart(UpdateRequest.self, arrayEncodingStrategy: .accumulateValues)
                }
            }
        }

        let router = Router()
        let api: API = .update(id: "test-id", request: .init(description: "test"))

        // This should generate a URL with path "/v3/routes/test-id"
        let url = router.url(for: api)

        print("DEBUG: Generated URL path: '\(url.path)'")
        #expect(url.path == "/v3/routes/test-id", "Expected '/v3/routes/test-id', got '\(url.path)'")
    }

    @Test("URL generation with RFC_2046.Multipart.Conversion WITHOUT Headers block")
    func testURLGenerationWithoutHeaders() throws {
        // Test if removing Headers fixes URL generation
        struct UpdateRequest: Codable, Equatable {
            let description: String?

            init(description: String? = nil) {
                self.description = description
            }
        }

        enum API: Equatable {
            case update(id: String, request: UpdateRequest)
        }

        struct Router: ParserPrinter {
            var body: some URLRouting.Router<API> {
                RFC_3986.URI.Route(.case(API.update)) {
                    Method.put
                    Path { "v3" }
                    Path { "routes" }
                    Path { Parse(.string) }
                    Body(RFC_2046.Multipart.Conversion(
                        UpdateRequest.self,
                        arrayEncodingStrategy: .accumulateValues
                    ))
                }
            }
        }

        let router = Router()
        let api: API = .update(id: "test-id", request: .init(description: "test"))

        let url = router.url(for: api)

        print("DEBUG (no headers): Generated URL path: '\(url.path)'")
        #expect(url.path == "/v3/routes/test-id", "Expected '/v3/routes/test-id', got '\(url.path)'")
    }

    @Test("Empty request throws emptyRequest error")
    func testEmptyRequestError() throws {
        // Test that encoding a request with all nil fields throws the expected error
        struct EmptyableRequest: Codable, Equatable {
            let name: String?
            let email: String?

            init(name: String? = nil, email: String? = nil) {
                self.name = name
                self.email = email
            }
        }

        let conversion = RFC_2046.Multipart.Conversion(EmptyableRequest.self)
        let emptyRequest = EmptyableRequest()

        // Attempt to encode the empty request should throw
        #expect(throws: MultipartConversionError.self) {
            try conversion.unapply(emptyRequest)
        }

        // Verify that a non-empty request works fine
        let validRequest = EmptyableRequest(name: "John")
        let data = try conversion.unapply(validRequest)
        #expect(!data.isEmpty)
    }
}
