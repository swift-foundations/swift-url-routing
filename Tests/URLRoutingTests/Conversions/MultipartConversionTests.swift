import Testing
import Foundation
import URLRouting

@Suite("RFC_2046.Multipart.Conversion Integration Tests")
struct MultipartConversionIntegrationTests {

    struct TestRequest: Codable, Equatable {
        let name: String
        let subscribed: Bool
    }

    @Test("RFC_2046.Multipart.Conversion exists and is accessible")
    func testConversionExists() {
        let conversion = RFC_2046.Multipart.Conversion(TestRequest.self)
        #expect(!conversion.boundary.rawValue.isEmpty)
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

        #expect(string.contains(conversion.boundary.rawValue))
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
        #expect(throws: RFC_2046.Multipart.Conversion<EmptyableRequest>.Error.self) {
            try conversion.unapply(emptyRequest)
        }

        // Verify that a non-empty request works fine
        let validRequest = EmptyableRequest(name: "John")
        let data = try conversion.unapply(validRequest)
        #expect(!data.isEmpty)
    }

    // MARK: - Bool Encoder Tests

    @Test("Bool encoding with trueFalse strategy")
    func testBoolEncodingTrueFalse() throws {
        struct BoolRequest: Codable {
            let active: Bool
            let verified: Bool
        }

        let encoder = RFC_2046.Multipart.Encoder()
        encoder.boolEncoder = .trueFalse

        let conversion = RFC_2046.Multipart.Conversion(
            BoolRequest.self,
            encoder: encoder
        )

        let request = BoolRequest(active: true, verified: false)
        let data = try conversion.unapply(request)
        let string = String(data: data, encoding: .utf8)!

        #expect(string.contains("true"))
        #expect(string.contains("false"))
    }

    @Test("Bool encoding with yesNo strategy")
    func testBoolEncodingYesNo() throws {
        struct BoolRequest: Codable {
            let consent: Bool
        }

        let encoder = RFC_2046.Multipart.Encoder()
        encoder.boolEncoder = .yesNo

        let conversion = RFC_2046.Multipart.Conversion(
            BoolRequest.self,
            encoder: encoder
        )

        let requestYes = BoolRequest(consent: true)
        let dataYes = try conversion.unapply(requestYes)
        let stringYes = String(data: dataYes, encoding: .utf8)!
        #expect(stringYes.contains("yes"))

        let requestNo = BoolRequest(consent: false)
        let dataNo = try conversion.unapply(requestNo)
        let stringNo = String(data: dataNo, encoding: .utf8)!
        #expect(stringNo.contains("no"))
    }

    @Test("Bool encoding with numeric strategy")
    func testBoolEncodingNumeric() throws {
        struct BoolRequest: Codable {
            let enabled: Bool
        }

        let encoder = RFC_2046.Multipart.Encoder()
        encoder.boolEncoder = .numeric

        let conversion = RFC_2046.Multipart.Conversion(
            BoolRequest.self,
            encoder: encoder
        )

        let requestTrue = BoolRequest(enabled: true)
        let dataTrue = try conversion.unapply(requestTrue)
        let stringTrue = String(data: dataTrue, encoding: .utf8)!
        #expect(stringTrue.contains("1"))

        let requestFalse = BoolRequest(enabled: false)
        let dataFalse = try conversion.unapply(requestFalse)
        let stringFalse = String(data: dataFalse, encoding: .utf8)!
        #expect(stringFalse.contains("0"))
    }

    @Test("Bool encoding with custom strategy")
    func testBoolEncodingCustom() throws {
        struct BoolRequest: Codable {
            let agreed: Bool
        }

        let encoder = RFC_2046.Multipart.Encoder()
        encoder.boolEncoder = Bool.Encoder { $0 ? "AGREE" : "DISAGREE" }

        let conversion = RFC_2046.Multipart.Conversion(
            BoolRequest.self,
            encoder: encoder
        )

        let request = BoolRequest(agreed: true)
        let data = try conversion.unapply(request)
        let string = String(data: data, encoding: .utf8)!

        #expect(string.contains("AGREE"))
    }

    // MARK: - Date Encoder Tests

    @Test("Date encoding with iso8601 strategy")
    func testDateEncodingISO8601() throws {
        struct DateRequest: Codable {
            let createdAt: Date
        }

        let encoder = RFC_2046.Multipart.Encoder()
        encoder.dateEncoder = .iso8601

        let conversion = RFC_2046.Multipart.Conversion(
            DateRequest.self,
            encoder: encoder
        )

        let date = Date(timeIntervalSince1970: 1609459200) // 2021-01-01T00:00:00Z
        let request = DateRequest(createdAt: date)
        let data = try conversion.unapply(request)
        let string = String(data: data, encoding: .utf8)!

        #expect(string.contains("2021-01-01"))
    }

    @Test("Date encoding with secondsSince1970 strategy")
    func testDateEncodingSecondsSince1970() throws {
        struct DateRequest: Codable {
            let timestamp: Date
        }

        let encoder = RFC_2046.Multipart.Encoder()
        encoder.dateEncoder = .secondsSince1970

        let conversion = RFC_2046.Multipart.Conversion(
            DateRequest.self,
            encoder: encoder
        )

        let date = Date(timeIntervalSince1970: 1234567890)
        let request = DateRequest(timestamp: date)
        let data = try conversion.unapply(request)
        let string = String(data: data, encoding: .utf8)!

        #expect(string.contains("1234567890"))
    }

    @Test("Date encoding with millisecondsSince1970 strategy")
    func testDateEncodingMillisecondsSince1970() throws {
        struct DateRequest: Codable {
            let timestamp: Date
        }

        let encoder = RFC_2046.Multipart.Encoder()
        encoder.dateEncoder = .millisecondsSince1970

        let conversion = RFC_2046.Multipart.Conversion(
            DateRequest.self,
            encoder: encoder
        )

        // Use a clean number: 1234567 seconds = 1234567000 milliseconds
        let date = Date(timeIntervalSince1970: 1234567.0)
        let request = DateRequest(timestamp: date)
        let data = try conversion.unapply(request)
        let string = String(data: data, encoding: .utf8)!

        // Should contain milliseconds
        #expect(string.contains("1234567000"))
    }

    @Test("Date encoding with custom strategy")
    func testDateEncodingCustom() throws {
        struct DateRequest: Codable {
            let date: Date
        }

        let encoder = RFC_2046.Multipart.Encoder()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        encoder.dateEncoder = Date.Encoder { formatter.string(from: $0) }

        let conversion = RFC_2046.Multipart.Conversion(
            DateRequest.self,
            encoder: encoder
        )

        let date = Date(timeIntervalSince1970: 1609459200) // 2021-01-01
        let request = DateRequest(date: date)
        let data = try conversion.unapply(request)
        let string = String(data: data, encoding: .utf8)!

        #expect(string.contains("2021-01-01"))
    }

    // MARK: - Custom Value Encoder Tests

    @Test("Custom value encoder for special types")
    func testCustomValueEncoder() throws {
        // Create a custom type that will go through the generic encode<T> method
        struct CustomValue: Codable {
            let value: String
        }

        struct RequestWithCustomType: Codable {
            let name: String
            let metadata: CustomValue
        }

        let encoder = RFC_2046.Multipart.Encoder()
        encoder.customValueEncoder = { value, key in
            if key == "metadata", let custom = value as? CustomValue {
                return "CUSTOM:\(custom.value)"
            }
            return nil
        }

        let conversion = RFC_2046.Multipart.Conversion(
            RequestWithCustomType.self,
            encoder: encoder
        )

        let request = RequestWithCustomType(
            name: "test",
            metadata: CustomValue(value: "special")
        )
        let data = try conversion.unapply(request)
        let string = String(data: data, encoding: .utf8)!

        // customValueEncoder should be called for the CustomValue type
        #expect(string.contains("CUSTOM:special"))
        #expect(string.contains("test"))
    }

    // MARK: - Combined Configuration Tests

    @Test("Multiple encoder configurations together")
    func testCombinedEncoderConfiguration() throws {
        struct ComplexRequest: Codable {
            let name: String
            let active: Bool
            let createdAt: Date
            let tags: [String]
        }

        let encoder = RFC_2046.Multipart.Encoder()
        encoder.boolEncoder = .yesNo
        encoder.dateEncoder = .iso8601
        encoder.arrayEncodingStrategy = .brackets

        let conversion = RFC_2046.Multipart.Conversion(
            ComplexRequest.self,
            encoder: encoder
        )

        let request = ComplexRequest(
            name: "Test",
            active: true,
            createdAt: Date(timeIntervalSince1970: 1609459200),
            tags: ["swift", "server"]
        )

        let data = try conversion.unapply(request)
        let string = String(data: data, encoding: .utf8)!

        // Check bool encoding
        #expect(string.contains("yes"))
        // Check date encoding
        #expect(string.contains("2021"))
        // Check array encoding
        #expect(string.contains("tags[]"))
    }

    @Test("Custom encoder persists across multiple uses")
    func testEncoderReuse() throws {
        struct SimpleRequest: Codable {
            let value: Bool
        }

        let encoder = RFC_2046.Multipart.Encoder()
        encoder.boolEncoder = .numeric

        let conversion = RFC_2046.Multipart.Conversion(
            SimpleRequest.self,
            encoder: encoder
        )

        // First use
        let request1 = SimpleRequest(value: true)
        let data1 = try conversion.unapply(request1)
        let string1 = String(data: data1, encoding: .utf8)!
        #expect(string1.contains("1"))

        // Second use - encoder configuration should persist
        let request2 = SimpleRequest(value: false)
        let data2 = try conversion.unapply(request2)
        let string2 = String(data: data2, encoding: .utf8)!
        #expect(string2.contains("0"))
    }
}
