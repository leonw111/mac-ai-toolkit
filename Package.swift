// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "mac-ai-toolkit",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "MacAIToolkit",
            targets: ["MacAIToolkit"]
        ),
    ],
    dependencies: [
        // Vapor for HTTP Server
        .package(url: "https://github.com/vapor/vapor.git", from: "4.89.0"),
    ],
    targets: [
        .target(
            name: "MacAIToolkit",
            dependencies: [
                .product(name: "Vapor", package: "vapor"),
            ],
            path: "mac-ai-toolkit"
        ),
    ]
)
