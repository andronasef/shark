// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Shark",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "Shark",
            targets: ["Shark"]
        )
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "Shark",
            dependencies: [],
            path: "Sources/Shark"
        ),
        .testTarget(
            name: "SharkTests",
            dependencies: ["Shark"],
            path: "Tests/SharkTests"
        )
    ]
)
