// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Foodapomo",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "Foodapomo", targets: ["Foodapomo"])
    ],
    targets: [
        .executableTarget(
            name: "Foodapomo",
            path: "Sources/Foodapomo"
        )
    ]
)
