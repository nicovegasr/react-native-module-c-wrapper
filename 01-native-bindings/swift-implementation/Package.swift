// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Caesar",
    platforms: [.iOS(.v16)],
    products: [
        .library(name: "Caesar", targets: ["Caesar"])
    ],
    targets: [
        .binaryTarget(
            name: "CCaesar",
            path: "vendor/Caesar.xcframework"
        ),
        .target(
            name: "Caesar",
            dependencies: ["CCaesar"]
        ),
        .testTarget(
            name: "CaesarTests",
            dependencies: ["Caesar"]
        )
    ]
)
