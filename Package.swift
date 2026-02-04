// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "JarvisWhispr",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "JarvisWhispr", targets: ["JarvisWhispr"])
    ],
    targets: [
        .executableTarget(
            name: "JarvisWhispr",
            path: "JarvisWhispr",
            resources: [
                .process("Info.plist")
            ]
        )
    ]
)
