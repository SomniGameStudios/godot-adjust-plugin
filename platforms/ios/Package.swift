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
        .package(url: "https://github.com/adjust/ios_sdk", exact: "5.7.0"),
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
                // Godot's iOS debug template exports the DEBUG_ENABLED ABI
                // (MethodDefinition bind_methodfi, D_METHODP); the release
                // template does not. The define must match the build config
                // or the exported app fails to link.
                .define("DEBUG_ENABLED", .when(configuration: .debug))
            ]
        )
    ]
)
