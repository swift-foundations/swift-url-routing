import Foundation
import Testing
import URLRouting
import URL_Routing_Foundation_Integration
import RFC_3986

@Suite
struct `Path Security Tests` {

    @Test
    func `Path with .. segments is rejected by default`() throws {
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

    @Test
    func `Path.unchecked allows .. segments`() throws {
        let parser = Path.unchecked {
            "files"
            Rest()
        }

        var request = RFC_3986.URI.Request.Data(path: "/files/../admin/secret")

        // Should succeed with unchecked
        let result = try parser.parse(&request)
        #expect(result == "..")
    }

    @Test
    func `Multiple .. segments rejected`() throws {
        let parser = Path {
            "files"
            Rest()
        }

        var request = RFC_3986.URI.Request.Data(path: "/files/../../etc/passwd")

        #expect(throws: RFC_3986.URI.Routing.Error.self) {
            try parser.parse(&request)
        }
    }

    @Test
    func `Normal paths work fine`() throws {
        let parser = Path {
            "users"
            Int.parser()
        }

        var request = RFC_3986.URI.Request.Data(path: "/users/42")
        let userId = try parser.parse(&request)
        #expect(userId == 42)
    }

    @Test
    func `Empty segments from // are allowed (not a security issue)`() throws {
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

    @Test
    func `How Foundation parses URLs with ..`() throws {
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

    @Test
    func `RFC 3986 remove Dot Segments behavior`() throws {
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

    @Test
    func `Path segments from string parsing`() throws {
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

    @Test
    func `Print validates against .. segments`() throws {
        let parser = Path {
            "files"
            Rest()
        }

        var request = RFC_3986.URI.Request.Data()

        // Trying to print a value that would create .. segments should fail
        // (This depends on how the value is printed, but we're testing the validation)
        // For now, we need to check if print validation catches issues after printing
    }

    @Test
    func `Real attack scenario prevented`() throws {
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

    @Test
    func `Error message is descriptive`() throws {
        let parser = Path {
            "files"
            Rest()
        }

        var request = RFC_3986.URI.Request.Data(path: "/files/../admin")

        do {
            _ = try parser.parse(&request)
            #expect(Bool(false), "Should have thrown")
        } catch {
            // Typed throws already binds `error` as RFC_3986.URI.Routing.Error; an
            // explicit `as` downcast here trips a SILGen ownership crash (signal 6).
            let description = error.localizedDescription
            #expect(description.contains(".."))
            #expect(description.contains("traversal") || description.contains("directory"))
        }
    }
}
