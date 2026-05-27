// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "AdjustGodotPlugin",
    platforms: [.iOS(.v13)],
    products: [
        .library(
            name: "AdjustGodotPlugin",
            type: .static,
            targets: ["AdjustGodotPlugin"]),
    ],
    dependencies: [
        .package(url: "https://github.com/adjust/ios_sdk", from: "5.6.0"),
    ],
    targets: [
        .target(
            name: "AdjustGodotPlugin",
            dependencies: [
                .product(name: "AdjustSdk", package: "ios_sdk"),
            ],
            path: "src",
            publicHeadersPath: "",
            cxxSettings: [
                .headerSearchPath("../include/godot"),
                .headerSearchPath("../include/godot/platform/ios"),
                .headerSearchPath("../include/godot/drivers/apple_embedded"),
                .unsafeFlags(["-std=c++17"]),
                .define("DEBUG_ENABLED")
            ]
        )
    ]
)
