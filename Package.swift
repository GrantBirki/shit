// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "Shit",
    platforms: [
        .macOS(.v26),
    ],
    products: [
        .executable(
            name: "Shit",
            targets: ["Shit"]
        ),
    ],
    targets: [
        .executableTarget(
            name: "Shit",
            path: "Sources",
            resources: [
                .process("Resources"),
            ]
        ),
        .testTarget(
            name: "ShitTests",
            dependencies: ["Shit"],
            path: "Tests"
        ),
    ],
    swiftLanguageModes: [.v6]
)
