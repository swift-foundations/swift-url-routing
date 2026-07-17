import Testing
import Foundation
import URLRouting
import RFC_3986
import RFC_7230

@Suite
struct `Body Security Tests` {

    // MARK: - Size Validation Tests

    @Test
    func `Body within default size limit succeeds`() throws {
        let parser = Body()

        // Create a 1 MiB body (well under 10 MiB default)
        let bodyData = Data(repeating: 0, count: 1024 * 1024)
        var request = RFC_3986.URI.Request.Data(body: bodyData)

        #expect(throws: Never.self) {
            _ = try parser.parse(&request)
        }
    }

    @Test
    func `Body exceeding default size limit throws error`() throws {
        let parser = Body()

        // Create an 11 MiB body (exceeds 10 MiB default)
        let bodyData = Data(repeating: 0, count: 11 * 1024 * 1024)
        var request = RFC_3986.URI.Request.Data(body: bodyData)

        #expect(throws: RFC_3986.URI.Routing.Error.self) {
            _ = try parser.parse(&request)
        }
    }

    @Test
    func `Body at exact default size limit succeeds`() throws {
        let parser = Body()

        // Create exactly 10 MiB body
        let bodyData = Data(repeating: 0, count: 10 * 1024 * 1024)
        var request = RFC_3986.URI.Request.Data(body: bodyData)

        #expect(throws: Never.self) {
            _ = try parser.parse(&request)
        }
    }

    @Test
    func `Custom size limit is enforced`() throws {
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

    @Test
    func `Large custom limit allows large bodies`() throws {
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

    @Test
    func `Error message includes actual and max sizes`() throws {
        let parser = Body(
            maxSize: Measurement(value: 1, unit: UnitInformationStorage.kibibytes)
        )

        let bodyData = Data(repeating: 0, count: 2048)
        var request = RFC_3986.URI.Request.Data(body: bodyData)

        do {
            _ = try parser.parse(&request)
            #expect(Bool(false), "Should have thrown error")
        } catch let error {
            let description = error.errorDescription ?? ""
            #expect(description.contains("Body size"))
            #expect(description.contains("exceeds"))
        }
    }

    // MARK: - Integration with Conversions

    @Test
    func `JSON body parser respects size limit`() throws {
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

    @Test
    func `Small JSON body within limit succeeds`() throws {
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

    @Test
    func `Default max size is 10 Mi B`() {
        let expected = Measurement(value: 10, unit: UnitInformationStorage.mebibytes)
        #expect(RFC_7230.Body.Parser<Rest<Data>>.defaultMaxSize == expected)
    }

    @Test
    func `Empty body doesn't trigger size validation`() throws {
        let parser = Body(
            maxSize: Measurement(value: 1, unit: UnitInformationStorage.bytes)
        )

        var request = RFC_3986.URI.Request.Data()
        // No body set - should fail with "missing" error, not size error

        do {
            _ = try parser.parse(&request)
            #expect(Bool(false), "Should have thrown missing body error")
        } catch let error {
            // Should be missing error, not size error
            if case .missing = error.failure {
                // Expected
            } else {
                #expect(Bool(false), "Expected missing error, got: \(error)")
            }
        }
    }

    // MARK: - Real-World Scenarios

    @Test
    func `Realistic API endpoint with reasonable limit`() throws {
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

    @Test
    func `Prevent Do S attack with massive body`() throws {
        let parser = Body()

        // Simulate attacker trying to send 100 MiB body
        let attackBody = Data(repeating: 0, count: 100 * 1024 * 1024)
        var request = RFC_3986.URI.Request.Data(body: attackBody)

        #expect(throws: RFC_3986.URI.Routing.Error.self) {
            _ = try parser.parse(&request)
        }
    }
}
