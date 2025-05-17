// swift-tools-version: 5.7

import PackageDescription

let package = Package(
    name: "Backend",
    platforms: [
        .macOS(.v13),
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "Backend",
            targets: ["Backend"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/hmlongco/Resolver.git", from: "1.0.0"),
        .package(
            url: "https://github.com/Swiftgram/TDLibKit",
            revision: "5a4cc650a56d82d5c6e08f281366ffef80aca59c"),
        .package(path: "../Utilities"),
        .package(path: "../Storage"),
        .package(path: "../Logs")
    ],
    targets: [.target(
        name: "Backend",
        dependencies: [
            .product(name: "TDLibKit", package: "tdlibkit"),
            "Utilities",
            "Storage",
            "Logs",
            "Resolver"
        ]
    )]
)
