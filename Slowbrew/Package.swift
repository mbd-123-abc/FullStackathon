// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Slowbrew",
    platforms: [
        .macOS(.v13)
    ],
    targets: [
        .target(
            name: "Slowbrew",
            path: "Sources/Slowbrew",
            resources: [
                .copy("Resources/Info.plist")
            ]
        ),
        .testTarget(
            name: "SlowbrewTests",
            dependencies: [
                "Slowbrew",
                .product(name: "SwiftCheck", package: "SwiftCheck")
            ],
            path: "Tests/SlowbrewTests"
        )
    ],
    dependencies: [
        .package(
            url: "https://github.com/typelift/SwiftCheck.git",
            from: "0.12.0"
        )
    ]
)
