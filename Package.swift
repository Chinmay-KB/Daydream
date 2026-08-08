// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Daydream",
    platforms: [
        .macOS(.v14)
    ],
    targets: [
        .executableTarget(
            name: "Daydream",
            path: "Sources/Daydream"
        )
    ]
)
