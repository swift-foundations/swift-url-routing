// swift-tools-version:6.2

import PackageDescription

let package = Package(
  name: "swift-url-routing",
  platforms: [
    .iOS(.v17),
    .macOS(.v14),
    .tvOS(.v17),
    .watchOS(.v10),
  ],
  products: [
    .library(name: "URLRouting", targets: ["URLRouting"])
  ],
  dependencies: [
    .package(url: "https://github.com/apple/swift-collections", from: "1.0.3"),
    .package(url: "https://github.com/pointfreeco/swift-case-paths", from: "1.7.2"),
    .package(url: "https://github.com/pointfreeco/swift-parsing", from: "0.14.0"),
    .package(url: "https://github.com/pointfreeco/xctest-dynamic-overlay", from: "1.4.0"),
    .package(url: "https://github.com/swift-standards/swift-rfc-3986.git", from: "0.1.3"),
    .package(url: "https://github.com/swift-standards/swift-rfc-6570.git", from: "0.1.0"),
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
