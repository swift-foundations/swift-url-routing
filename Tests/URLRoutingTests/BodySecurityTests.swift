import Testing
import Foundation
import URLRouting
import RFC_3986
import RFC_7230
import Parsing

@Suite("Body Security Tests")
struct BodySecurityTests {

    // MARK: - Size Validation Tests

    @Test("Body within default size limit succeeds")
    func testBodyWithinDefaultLimit() throws {
        let parser = Body()

        // Create a 1 MiB body (well under 10 MiB default)
        let bodyData = Data(repeating: 0, count: 1024 * 1024)
        var request = RFC_3986.URI.Request.Data(body: bodyData)

        #expect(throws: Never.self) {
            _ = try parser.parse(&request)
        }
    }

    @Test("Body exceeding default size limit throws error")
    func testBodyExceedingDefaultLimit() throws {
        let parser = Body()

        // Create an 11 MiB body (exceeds 10 MiB default)
        let bodyData = Data(repeating: 0, count: 11 * 1024 * 1024)
        var request = RFC_3986.URI.Request.Data(body: bodyData)

        #expect(throws: RFC_3986.URI.Routing.Error.self) {
            _ = try parser.parse(&request)
        }
    }

    @Test("Body at exact default size limit succeeds")
    func testBodyAtExactDefaultLimit() throws {
        let parser = Body()

        // Create exactly 10 MiB body
        let bodyData = Data(repeating: 0, count: 10 * 1024 * 1024)
        var request = RFC_3986.URI.Request.Data(body: bodyData)

        #expect(throws: Never.self) {
            _ = try parser.parse(&request)
        }
    }

    @Test("Custom size limit is enforced")
    func testCustomSizeLimit() throws {
        // Set a small 1 KiB limit
        let parser = Body(
            maxSize: Measurement(value: 1, unit: UnitInformationStorage.kibibytes)
        )

        // Try to parse 2 KiB body
        let bodyData = Data(repeating: 0, count: 2048)
        var request = RFC_3986.URI.Request.Data(body: bodyData)

        #expect(throws: RFC_3986.URI.Routing.Error.self) {
            _ = try parser.parse(&request)
        }
    }

    @Test("Large custom limit allows large bodies")
    func testLargeCustomLimit() throws {
        // Set a 50 MiB limit
        let parser = Body(
            maxSize: Measurement(value: 50, unit: UnitInformationStorage.mebibytes)
        )

        // Parse a 20 MiB body
        let bodyData = Data(repeating: 0, count: 20 * 1024 * 1024)
        var request = RFC_3986.URI.Request.Data(body: bodyData)

        #expect(throws: Never.self) {
            _ = try parser.parse(&request)
        }
    }

    // MARK: - Error Message Tests

    @Test("Error message includes actual and max sizes")
    func testErrorMessageFormat() throws {
        let parser = Body(
            maxSize: Measurement(value: 1, unit: UnitInformationStorage.kibibytes)
        )

        let bodyData = Data(repeating: 0, count: 2048)
        var request = RFC_3986.URI.Request.Data(body: bodyData)

        do {
            _ = try parser.parse(&request)
            #expect(Bool(false), "Should have thrown error")
        } catch let error as RFC_3986.URI.Routing.Error {
            let description = error.errorDescription ?? ""
            #expect(description.contains("Body size"))
            #expect(description.contains("exceeds"))
        }
    }

    // MARK: - Integration with Conversions

    @Test("JSON body parser respects size limit")
    func testJSONBodySizeLimit() throws {
        struct Comment: Codable {
            let message: String
        }

        let parser = Body(
            .json(Comment.self),
            maxSize: Measurement(value: 1, unit: UnitInformationStorage.kibibytes)
        )

        // Create a large JSON payload (>1 KiB)
        let largeComment = Comment(message: String(repeating: "x", count: 2000))
        let largeJSON = try JSONEncoder().encode(largeComment)

        var request = RFC_3986.URI.Request.Data(body: largeJSON)

        #expect(throws: RFC_3986.URI.Routing.Error.self) {
            _ = try parser.parse(&request)
        }
    }

    @Test("Small JSON body within limit succeeds")
    func testSmallJSONBody() throws {
        struct Comment: Codable {
            let message: String
        }

        let parser = Body(
            .json(Comment.self),
            maxSize: Measurement(value: 1, unit: UnitInformationStorage.kibibytes)
        )

        let smallComment = Comment(message: "Hello")
        let smallJSON = try JSONEncoder().encode(smallComment)

        var request = RFC_3986.URI.Request.Data(body: smallJSON)

        let result = try parser.parse(&request)
        #expect(result.message == "Hello")
    }

    // MARK: - Default vs Custom Limits

    @Test("Default max size is 10 MiB")
    func testDefaultMaxSize() {
        let expected = Measurement(value: 10, unit: UnitInformationStorage.mebibytes)
        #expect(RFC_7230.Body.Parser<Rest<Data>>.defaultMaxSize == expected)
    }

    @Test("Empty body doesn't trigger size validation")
    func testEmptyBodyDoesNotTriggerSizeValidation() throws {
        let parser = Body(
            maxSize: Measurement(value: 1, unit: UnitInformationStorage.bytes)
        )

        var request = RFC_3986.URI.Request.Data()
        // No body set - should fail with "missing" error, not size error

        do {
            _ = try parser.parse(&request)
            #expect(Bool(false), "Should have thrown missing body error")
        } catch let error as RFC_3986.URI.Routing.Error {
            // Should be missing error, not size error
            if case .missing = error.failure {
                // Expected
            } else {
                #expect(Bool(false), "Expected missing error, got: \(error)")
            }
        }
    }

    // MARK: - Real-World Scenarios

    @Test("Realistic API endpoint with reasonable limit")
    func testRealisticAPIEndpoint() throws {
        struct CreatePostRequest: Codable {
            let title: String
            let content: String
            let tags: [String]
        }

        // Typical API might allow 5 MiB for post creation
        let parser = Body(
            .json(CreatePostRequest.self),
            maxSize: Measurement(value: 5, unit: UnitInformationStorage.mebibytes)
        )

        let post = CreatePostRequest(
            title: "My Blog Post",
            content: String(repeating: "Lorem ipsum ", count: 1000),
            tags: ["swift", "web", "api"]
        )

        let json = try JSONEncoder().encode(post)
        var request = RFC_3986.URI.Request.Data(body: json)

        let result = try parser.parse(&request)
        #expect(result.title == "My Blog Post")
    }

    @Test("Prevent DoS attack with massive body")
    func testPreventDoSAttack() throws {
        let parser = Body()

        // Simulate attacker trying to send 100 MiB body
        let attackBody = Data(repeating: 0, count: 100 * 1024 * 1024)
        var request = RFC_3986.URI.Request.Data(body: attackBody)

        #expect(throws: RFC_3986.URI.Routing.Error.self) {
            _ = try parser.parse(&request)
        }
    }
}
