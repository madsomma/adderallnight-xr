// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "AdderAllNightXR",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "AdderAllNightXR", targets: ["AdderAllNightXR"])
    ],
    targets: [
        .executableTarget(
            name: "AdderAllNightXR",
            path: "sources/AdderAllNightXR"
        )
    ]
)
