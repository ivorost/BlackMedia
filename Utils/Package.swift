// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "BlackUtils",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v14),
    ],
    products: [
        .library(
            name: "BlackUtils",
            type: .static,
            targets: ["BlackUtils"]
        )
    ],
    targets: [
        .target(
            name: "BlackUtils",
            path: "Code"
        )
    ]
)
