import Testing
import Foundation
import URLRouting
import URLFormCoding

@Suite("Form.Conversion Integration Tests")
struct FormConversionIntegrationTests {

    struct TestRequest: Codable, Equatable {
        let name: String
        let age: Int
    }

    @Test("Form.Conversion exists and is accessible")
    func testConversionExists() throws {
        let conversion = Form.Conversion(TestRequest.self)
        let request = TestRequest(name: "Test", age: 25)
        // Just verify it can encode
        let data = try conversion.unapply(request)
        #expect(!data.isEmpty)
    }

    @Test("URLRouting.Conversion.form() static method works")
    func testStaticFormMethod() throws {
        // Use explicit type to call static method on concrete type
        let conversion: Form.Conversion<TestRequest> = .form(TestRequest.self)
        let request = TestRequest(name: "John", age: 30)
        let data = try conversion.unapply(request)
        #expect(!data.isEmpty)
    }

    @Test("Round-trip encoding and decoding")
    func testRoundTrip() throws {
        let conversion = Form.Conversion(TestRequest.self)
        let original = TestRequest(name: "Jane", age: 25)

        let encoded = try conversion.unapply(original)
        let decoded = try conversion.apply(encoded)

        #expect(decoded == original)
    }
}
