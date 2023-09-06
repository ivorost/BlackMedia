// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "BlackMedia",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v14),
    ],
    products: [
        .library(
            name: "BlackMedia",
            type: .static,
            targets: ["BlackMedia"]
        )
    ],
    dependencies: [
         .package(url: "../Utils", from: "1.0.0")
    ],
    targets: [
        .target(
            name: "BlackMedia",
            path: "Code"
        )
    ]
)
