// swift-tools-version:6.2

import PackageDescription

let package = Package(
  name: "swift-url-routing",
  platforms: [
    .iOS(.v18),
    .macOS(.v15),
    .tvOS(.v18),
    .watchOS(.v11),
  ],
  products: [
    .library(name: "URLRouting", targets: ["URLRouting"])
  ],
  dependencies: [
    .package(url: "https://github.com/apple/swift-collections", from: "1.0.3"),
    .package(url: "https://github.com/pointfreeco/swift-case-paths", from: "1.7.2"),
    .package(path: "../swift-parsing"),
    .package(url: "https://github.com/pointfreeco/xctest-dynamic-overlay", from: "1.7.0"),
    .package(url: "https://github.com/swift-standards/swift-rfc-3986.git", from: "0.1.3"),
    .package(url: "https://github.com/swift-standards/swift-rfc-6570.git", from: "0.1.0"),
    .package(url: "https://github.com/swift-standards/swift-rfc-2045.git", from: "0.1.0"),
    .package(path: "../../swift-standards/swift-rfc-2046"),
    .package(path: "../../swift-standards/swift-rfc-6265"),
    .package(path: "../../swift-standards/swift-rfc-7230"),
    .package(path: "../../swift-standards/swift-rfc-7231"),
    .package(path: "../../swift-standards/swift-rfc-7578"),
    .package(path: "../../swift-standards/swift-whatwg-html"),
    .package(path: "../../swift-standards/swift-whatwg-url-encoding"),
    .package(path: "../swift-url-form-coding"),
    .package(path: "../swift-multipart-form-coding"),
  ],
  targets: [
    .target(
      name: "URLRouting",
      dependencies: [
        .product(name: "IssueReporting", package: "xctest-dynamic-overlay"),
        .product(name: "OrderedCollections", package: "swift-collections"),
        .product(name: "Parsing", package: "swift-parsing"),
        .product(name: "RFC 3986", package: "swift-rfc-3986"),
        .product(name: "RFC_6570", package: "swift-rfc-6570"),
        .product(name: "RFC 2045", package: "swift-rfc-2045"),
        .product(name: "RFC 2046", package: "swift-rfc-2046"),
        .product(name: "RFC 6265", package: "swift-rfc-6265"),
        .product(name: "RFC 7230", package: "swift-rfc-7230"),
        .product(name: "RFC 7231", package: "swift-rfc-7231"),
        .product(name: "RFC 7578", package: "swift-rfc-7578"),
        .product(name: "WHATWG HTML Forms", package: "swift-whatwg-html"),
        .product(name: "WHATWG HTML FormData", package: "swift-whatwg-html"),
        .product(name: "WHATWG URL Encoding", package: "swift-whatwg-url-encoding"),
        .product(name: "URLFormCoding", package: "swift-url-form-coding"),
        .product(name: "MultipartFormCoding", package: "swift-multipart-form-coding"),
      ]
    ),
    .testTarget(
      name: "URLRoutingTests",
      dependencies: [
        "URLRouting"
      ]
    ),
  ]
)
