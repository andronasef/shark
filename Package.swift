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
    dependencies: [
        .package(url: "https://github.com/migueldeicaza/SwiftTerm.git", from: "1.0.7")
    ],
    targets: [
        .executableTarget(
            name: "Shark",
            dependencies: [
                .product(name: "SwiftTerm", package: "SwiftTerm")
            ],
            path: "Sources/Shark"
        ),
        .testTarget(
            name: "SharkTests",
            dependencies: ["Shark"],
            path: "Tests/SharkTests"
        )
    ]
)
