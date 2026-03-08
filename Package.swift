// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ExamSimulator",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "ExamSimulator", targets: ["ExamSimulator"]),
        .library(name: "ExamSimulatorCore", targets: ["ExamSimulatorCore"]),
    ],
    targets: [
        .executableTarget(
            name: "ExamSimulator",
            dependencies: ["ExamSimulatorCore"],
            path: "Sources/ExamSimulator",
            resources: [
                .copy("Resources/QAs"),
                .copy("Resources/Languages"),
                .copy("Resources/AppConfig.json"),
            ]
        ),
        .target(
            name: "ExamSimulatorCore",
            dependencies: [],
            path: "Sources/ExamSimulatorCore"
        ),
        .testTarget(
            name: "ExamSimulatorCoreTests",
            dependencies: ["ExamSimulatorCore"],
            path: "Tests/ExamSimulatorCoreTests"
        ),
    ]
)
