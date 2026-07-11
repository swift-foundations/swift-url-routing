// swift-tools-version:6.3.3

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
    .package(url: "https://github.com/swift-foundations/swift-dependencies.git", branch: "main"),
    .package(url: "https://github.com/swift-foundations/swift-logging-extras.git", branch: "main"),
    .package(url: "https://github.com/swift-ietf/swift-rfc-3986.git", branch: "main"),
    .package(url: "https://github.com/swift-ietf/swift-rfc-6570.git", branch: "main"),
    .package(url: "https://github.com/swift-ietf/swift-rfc-2045.git", branch: "main"),
    .package(url: "https://github.com/swift-ietf/swift-rfc-2046.git", branch: "main"),
    .package(url: "https://github.com/swift-ietf/swift-rfc-6265.git", branch: "main"),
    .package(url: "https://github.com/swift-ietf/swift-rfc-7230.git", branch: "main"),
    .package(url: "https://github.com/swift-ietf/swift-rfc-7231.git", branch: "main"),
    .package(url: "https://github.com/swift-ietf/swift-rfc-7578.git", branch: "main"),
    .package(url: "https://github.com/swift-whatwg/swift-whatwg-html.git", branch: "main"),
    .package(path: "../../swift-standards/swift-whatwg-url-encoding"),
    .package(url: "https://github.com/swift-foundations/swift-url-form-coding.git", branch: "main"),
    .package(url: "https://github.com/swift-foundations/swift-multipart-form-coding.git", branch: "main"),
  ],
  targets: [
    .target(
      name: "URLRouting",
      dependencies: [
        .product(name: "Dependencies", package: "swift-dependencies"),
        .product(name: "LoggingExtras", package: "swift-logging-extras"),
        .product(name: "OrderedCollections", package: "swift-collections"),
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
