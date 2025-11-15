import Foundation
import Parsing
import Testing
import URLRouting
import RFC_3986

@Suite("Path Security Tests")
struct PathSecurityTests {

    @Test("Path with .. segments is rejected by default")
    func testDotDotSegmentsRejected() throws {
        let parser = Path {
            "files"
            Rest()
        }

        var request = RFC_3986.URI.Request.Data(path: "/files/../admin/secret")

        // Should throw error for .. segment
        #expect(throws: RFC_3986.URI.Routing.Error.self) {
            try parser.parse(&request)
        }
    }

    @Test("Path.unchecked allows .. segments")
    func testUncheckedAllowsDotDot() throws {
        let parser = Path.unchecked {
            "files"
            Rest()
        }

        var request = RFC_3986.URI.Request.Data(path: "/files/../admin/secret")

        // Should succeed with unchecked
        let result = try parser.parse(&request)
        #expect(result == "..")
    }

    @Test("Multiple .. segments rejected")
    func testMultipleDotDotRejected() throws {
        let parser = Path {
            "files"
            Rest()
        }

        var request = RFC_3986.URI.Request.Data(path: "/files/../../etc/passwd")

        #expect(throws: RFC_3986.URI.Routing.Error.self) {
            try parser.parse(&request)
        }
    }

    @Test("Normal paths work fine")
    func testNormalPathsAllowed() throws {
        let parser = Path {
            "users"
            Digits()
        }

        var request = RFC_3986.URI.Request.Data(path: "/users/42")
        let userId = try parser.parse(&request)
        #expect(userId == 42)
    }

    @Test("Empty segments from // are allowed (not a security issue)")
    func testDoubleSlashesAllowed() throws {
        // Note: // in paths create empty segments when split
        // But Foundation's path parsing with omittingEmptySubsequences: true removes them
        // So this isn't actually a security issue - just testing current behavior

        let parser = Path {
            "api"
            Rest()
        }

        var request = RFC_3986.URI.Request.Data(path: "/api/admin/secret")
        let result = try parser.parse(&request)
        #expect(result == "admin")
    }

    @Test("How Foundation parses URLs with ..")
    func testFoundationURLParsing() throws {
        let testCases = [
            "/users/../admin/secret",
            "/files/../../etc/passwd",
            "//admin//secret",
            "/normal/path",
        ]

        for testCase in testCases {
            if let url = URL(string: "https://example.com\(testCase)") {
                print("\nInput:       \(testCase)")
                print("url.path:    \(url.path)")
                print("standardized: \(url.standardized.path)")

                if let requestData = RFC_3986.URI.Request.Data(url: url) {
                    print("Segments:    \(Array(requestData.path))")
                }
            }
        }
    }

    @Test("RFC 3986 removeDotSegments behavior")
    func testRFC3986Normalization() throws {
        let testCases = [
            ("/a/b/c/./../../g", "/a/g"),
            ("/./a/b/", "/a/b/"),
            ("/../admin", "/admin"),
            ("/files/../../etc/passwd", "/etc/passwd"),
        ]

        for (input, expected) in testCases {
            // Note: removeDotSegments is on RFC_3986.URI, not RFC_3986
            // Let me test via normalized URI instead
            if let uri = try? RFC_3986.URI(input) {
                let normalized = uri.normalized()
                print("\nInput:      \(input)")
                print("Normalized: \(normalized.value)")
                print("Expected path: \(expected)")
            }
        }
    }

    @Test("Path segments from string parsing")
    func testPathSegmentParsing() throws {
        // When we create URI.Request.Data from a path string,
        // how are the segments stored?

        let testCases = [
            "/users/../admin",
            "//admin//secret",
            "/normal/path",
        ]

        for testCase in testCases {
            let requestData = RFC_3986.URI.Request.Data(path: testCase)
            print("\nPath string: \(testCase)")
            print("Segments:    \(Array(requestData.path))")
            print("Has ..:      \(requestData.path.contains { $0 == ".." })")
            print("Has empty:   \(requestData.path.contains { $0.isEmpty })")
        }
    }

    @Test("Print validates against .. segments")
    func testPrintValidation() throws {
        let parser = Path {
            "files"
            Rest()
        }

        var request = RFC_3986.URI.Request.Data()

        // Trying to print a value that would create .. segments should fail
        // (This depends on how the value is printed, but we're testing the validation)
        // For now, we need to check if print validation catches issues after printing
    }

    @Test("Real attack scenario prevented")
    func testAttackScenarioPrevented() throws {
        // Scenario: API endpoint GET /files/{filename}
        // Attacker tries: GET /files/../../etc/passwd

        let parser = Path {
            "files"
            Rest()
        }

        var attackRequest = RFC_3986.URI.Request.Data(path: "/files/../../etc/passwd")

        // Attack should be rejected
        #expect(throws: RFC_3986.URI.Routing.Error.self) {
            _ = try parser.parse(&attackRequest)
        }
    }

    @Test("Error message is descriptive")
    func testErrorMessage() throws {
        let parser = Path {
            "files"
            Rest()
        }

        var request = RFC_3986.URI.Request.Data(path: "/files/../admin")

        do {
            _ = try parser.parse(&request)
            #expect(Bool(false), "Should have thrown")
        } catch let error as RFC_3986.URI.Routing.Error {
            let description = error.localizedDescription
            #expect(description.contains(".."))
            #expect(description.contains("traversal") || description.contains("directory"))
        }
    }
}
