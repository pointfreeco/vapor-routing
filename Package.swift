// swift-tools-version:5.5

import PackageDescription

let package = Package(
  name: "vapor-routing",
  platforms: [
    .macOS(.v12)
  ],
  products: [
    .library(
      name: "VaporRouting",
      targets: ["VaporRouting"]
    )
  ],
  dependencies: [
    .package(url: "https://github.com/vapor/vapor.git", from: "4.0.0"),
    .package(url: "https://github.com/pointfreeco/swift-url-routing", from: "0.1.0"),
  ],
  targets: [
    .target(
      name: "VaporRouting",
      dependencies: [
        .product(name: "Vapor", package: "vapor"),
        .product(name: "URLRouting", package: "swift-url-routing"),
      ]
    ),
    .testTarget(
      name: "VaporRoutingTests",
      dependencies: [
        "VaporRouting",
        .product(name: "XCTVapor", package: "vapor"),
      ]
    ),
  ]
)

#if swift(>=5.6)
  // Add the documentation compiler plugin if possible
  package.dependencies.append(
    .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.0.0")
  )
#endif
