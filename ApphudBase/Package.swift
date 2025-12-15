// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ApphudBase",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "ApphudBase",
            targets: ["ApphudBase"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/apphud/ApphudSDK.git", exact: "3.6.2")
    ],
    targets: [
        .target(
            name: "ApphudBase",
            dependencies: [
                .product(name: "ApphudSDK", package: "ApphudSDK")
            ]
        ),
    ]
)
