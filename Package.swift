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
            .package(url: "https://github.com/ivorost/BlackUtils.git", .branch("main")),
            .package(url: "https://github.com/ivorost/Starscream.git", from: "4.0.0")
    ],
    targets: [
        .target(
            name: "BlackMedia",
            dependencies: [ "BlackUtils", "Starscream" ],
            path: "Code"
        )
    ]
)
