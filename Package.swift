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
        .package(url: "https://github.com/migueldeicaza/SwiftTerm.git", "1.0.7"..<"1.19.0"),
        .package(url: "https://github.com/krzysztofzablocki/Inject.git", from: "1.2.4"),
        .package(url: "https://github.com/firebase/firebase-ios-sdk.git", from: "11.0.0")
    ],
    targets: [
        .executableTarget(
            name: "Shark",
            dependencies: [
                .product(name: "SwiftTerm", package: "SwiftTerm"),
                .product(name: "Inject", package: "Inject"),
                .product(name: "FirebaseAnalytics", package: "firebase-ios-sdk"),
                .product(name: "FirebaseCrashlytics", package: "firebase-ios-sdk")
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
