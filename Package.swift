// swift-tools-version:6.3.3

import PackageDescription

let package = Package(
  name: "swift-url-routing",
  platforms: [
    // Bumped to match the institute ecosystem floor (all deps require v26 after
    // the W2 update-first; swift-dual / swift-parser-primitives / RFC packages
    // are all .v26). Forced by resolution, not a discretionary choice.
    .iOS(.v26),
    .macOS(.v26),
    .tvOS(.v26),
    .watchOS(.v26),
  ],
  products: [
    .library(name: "URLRouting", targets: ["URLRouting"]),
    .library(name: "URL Routing Test Support", targets: ["URL Routing Test Support"]),
  ],
  dependencies: [
    .package(url: "https://github.com/apple/swift-collections.git", from: "1.0.3"),
    .package(url: "https://github.com/swift-primitives/swift-parser-primitives.git", branch: "main"),
    .package(url: "https://github.com/swift-primitives/swift-coder-primitives.git", branch: "main"),
    .package(url: "https://github.com/swift-foundations/swift-dual.git", branch: "main"),
    .package(url: "https://github.com/swift-foundations/swift-dependencies.git", branch: "main"),
    .package(url: "https://github.com/swift-foundations/swift-logger-dependencies.git", branch: "main"),
    .package(url: "https://github.com/apple/swift-log.git", from: "1.0.0"),
    .package(url: "https://github.com/swift-ietf/swift-rfc-3986.git", branch: "main"),
    .package(url: "https://github.com/swift-primitives/swift-collection-primitives.git", branch: "main"),
    .package(url: "https://github.com/swift-primitives/swift-byte-primitives.git", branch: "main"),
    .package(url: "https://github.com/swift-ietf/swift-rfc-2045.git", branch: "main"),
    .package(url: "https://github.com/swift-ietf/swift-rfc-2046.git", branch: "main"),
    .package(url: "https://github.com/swift-ietf/swift-rfc-6265.git", branch: "main"),
    .package(url: "https://github.com/swift-ietf/swift-rfc-7230.git", branch: "main"),
    .package(url: "https://github.com/swift-ietf/swift-rfc-7231.git", branch: "main"),
    .package(url: "https://github.com/swift-ietf/swift-rfc-7578.git", branch: "main"),
    .package(url: "https://github.com/swift-whatwg/swift-whatwg-html.git", branch: "main"),
    .package(url: "https://github.com/swift-whatwg/swift-whatwg-url.git", branch: "main"),
    .package(url: "https://github.com/swift-foundations/swift-url-form-coding.git", branch: "main"),
    .package(url: "https://github.com/swift-foundations/swift-multipart-form-coding.git", branch: "main"),
    .package(url: "https://github.com/swift-foundations/swift-http-body.git", branch: "main"),
    .package(url: "https://github.com/swift-standards/swift-media-type-standard.git", branch: "main"),
  ],
  targets: [
    .target(
      name: "URLRouting",
      dependencies: [
        .product(name: "Dependencies", package: "swift-dependencies"),
        .product(name: "Logger Dependencies", package: "swift-logger-dependencies"),
        .product(name: "Logging", package: "swift-log"),
        .product(name: "OrderedCollections", package: "swift-collections"),
        // Institute L1 parser engine — narrow per-family products (routing W2 swap
        // off pointfree `Parsing`). Umbrella `Parser Primitives` avoided per R2.
        .product(name: "Parser Primitive", package: "swift-parser-primitives"),
        .product(name: "Parser Take Primitives", package: "swift-parser-primitives"),
        .product(name: "Parser Skip Primitives", package: "swift-parser-primitives"),
        .product(name: "Parser Map Primitives", package: "swift-parser-primitives"),
        .product(name: "Parser Conversion Primitives", package: "swift-parser-primitives"),
        .product(name: "Parser Witness Primitives", package: "swift-parser-primitives"),
        .product(name: "Parser Error Primitives", package: "swift-parser-primitives"),
        .product(name: "Parser Rest Primitives", package: "swift-parser-primitives"),
        .product(name: "Parser Always Primitives", package: "swift-parser-primitives"),
        .product(name: "Parser End Primitives", package: "swift-parser-primitives"),
        .product(name: "Parser OneOf Primitives", package: "swift-parser-primitives"),
        .product(name: "Parser Match Primitives", package: "swift-parser-primitives"),
        .product(name: "Parser Conformance Primitives", package: "swift-parser-primitives"),
        // Coder-unification (B2): `Parser.Bidirectional` and the combinator
        // emission rows now live in swift-coder-primitives.
        .product(name: "Coder Parser Primitives", package: "swift-coder-primitives"),
        // Enum-case addressing for the `.case(\.case)` Route overloads (W1). The
        // `Dual` product re-exports `Case_Paths` (Case.Path + @Cases) transitively.
        .product(name: "Dual", package: "swift-dual"),
        .product(name: "RFC 3986", package: "swift-rfc-3986"),
        .product(name: "Collection Slice Primitives", package: "swift-collection-primitives"),
        .product(name: "Byte Primitive", package: "swift-byte-primitives"),
        .product(name: "RFC 2045", package: "swift-rfc-2045"),
        .product(name: "RFC 2046", package: "swift-rfc-2046"),
        .product(name: "RFC 6265", package: "swift-rfc-6265"),
        .product(name: "RFC 7230", package: "swift-rfc-7230"),
        .product(name: "RFC 7231", package: "swift-rfc-7231"),
        .product(name: "RFC 7578", package: "swift-rfc-7578"),
        .product(name: "WHATWG HTML Forms", package: "swift-whatwg-html"),
        .product(name: "WHATWG HTML Shared", package: "swift-whatwg-html"),
        .product(name: "WHATWG HTML FormData", package: "swift-whatwg-html"),
        .product(name: "WHATWG Form URL Encoded", package: "swift-whatwg-url"),
        .product(name: "URLFormCoding", package: "swift-url-form-coding"),
        .product(name: "MultipartFormCoding", package: "swift-multipart-form-coding"),
        .product(name: "HTTP Body", package: "swift-http-body"),
        .product(name: "Media Type Standard", package: "swift-media-type-standard"),
      ]
    ),
    .target(
      name: "URL Routing Test Support",
      dependencies: [
        "URLRouting"
      ],
      path: "Tests/Support"
    ),
    .testTarget(
      name: "URLRoutingTests",
      dependencies: [
        "URLRouting",
        "URL Routing Test Support",
        .product(name: "WHATWG HTML Forms", package: "swift-whatwg-html"),
        .product(name: "RFC 3986", package: "swift-rfc-3986"),
        .product(name: "RFC 7230", package: "swift-rfc-7230"),
      ]
    ),
  ]
)
