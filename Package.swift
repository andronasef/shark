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
        .package(url: "https://github.com/migueldeicaza/SwiftTerm.git", from: "1.0.7"),
        .package(url: "https://github.com/krzysztofzablocki/Inject.git", from: "1.2.4")
    ],
    targets: [
        .executableTarget(
            name: "Shark",
            dependencies: [
                .product(name: "SwiftTerm", package: "SwiftTerm"),
                .product(name: "Inject", package: "Inject")
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
