import Foundation
import Testing
import URLRouting

#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif

@Suite
struct Test {
    #if os(macOS) || os(iOS) || os(tvOS) || os(watchOS)
        @Test
        @available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
        func jsonDecoderNoDecoder() async throws {
            struct Response: Equatable, Decodable {
                let decodableValue: String
            }
            enum AppRoute {
                case test
            }
            let sut = URLRouting.Client<AppRoute>(request: { _ in
                ("{\"decodableValue\":\"result\"}".data(using: .utf8)!, URLResponse())
            })
            let response = try await sut.decodedResponse(for: .test, as: Response.self)
            #expect(response.value == Response(decodableValue: "result"))
        }

        @Test
        @available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
        func jsonDecoderCustomDecoder() async throws {
            struct Response: Equatable, Decodable {
                let decodableValue: String
            }
            enum AppRoute {
                case test
            }
            let customDecoder = JSONDecoder()
            customDecoder.keyDecodingStrategy = .convertFromSnakeCase
            let sut = URLRouting.Client<AppRoute>(
                request: { _ in
                    ("{\"decodable_value\":\"result\"}".data(using: .utf8)!, URLResponse())
                },
                decoder: customDecoder
            )
            let response = try await sut.decodedResponse(for: .test, as: Response.self)
            #expect(response.value == Response(decodableValue: "result"))
        }

        @Test
        @available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
        func jsonDecoderCustomDecoderForRequest() async throws {
            struct Response: Equatable, Decodable {
                let decodableValue: String
            }
            enum AppRoute {
                case test
            }
            let customDecoder = JSONDecoder()
            customDecoder.keyDecodingStrategy = .convertFromSnakeCase
            let sut = URLRouting.Client<AppRoute>(
                request: { _ in
                    ("{\"decodableValue\":\"result\"}".data(using: .utf8)!, URLResponse())
                },
                decoder: customDecoder
            )
            let response = try await sut.decodedResponse(
                for: .test,
                as: Response.self,
                decoder: .init()
            )
            #expect(response.value == Response(decodableValue: "result"))
        }
    #endif
}
