// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "SwiftNTP",
    platforms: [
        .iOS(.v10)
    ],
    products: [
        .library(name: "SwiftNTP", targets: ["SwiftNTP"])
    ],
    dependencies: [
        .package(url: "https://github.com/robbiehanson/CocoaAsyncSocket.git", from: "7.6.5")
    ],
    targets: [
        .target(
            name: "SwiftNTP",
            dependencies: ["CocoaAsyncSocket"],
            path: "Sources"
        )
    ]
)
