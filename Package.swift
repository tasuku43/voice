// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "VoiceAgentInput",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(name: "VoiceAgentInputCore", targets: ["VoiceAgentInputCore"]),
        .executable(name: "voice-agent-input-app", targets: ["VoiceAgentInputApp"]),
        .executable(name: "voice-agent-input-demo", targets: ["VoiceAgentInputDemo"]),
        .executable(name: "TranscribeCLI", targets: ["TranscribeCLI"])
    ],
    targets: [
        .target(
            name: "VoiceAgentInputCore",
            path: "src/VoiceAgentInputCore",
            exclude: ["Context/README.md", "UIBoundary/README.md"]
        ),
        .executableTarget(
            name: "VoiceAgentInputDemo",
            dependencies: ["VoiceAgentInputCore"],
            path: "src/VoiceAgentInputDemo"
        ),
        .executableTarget(
            name: "VoiceAgentInputApp",
            dependencies: ["VoiceAgentInputCore"],
            path: "src/VoiceAgentInputApp",
            exclude: ["Info.plist"]
        ),
        .executableTarget(
            name: "TranscribeCLI",
            dependencies: ["VoiceAgentInputCore"],
            path: "src/TranscribeCLI"
        ),
        .testTarget(
            name: "VoiceAgentInputCoreTests",
            dependencies: ["VoiceAgentInputCore"],
            path: "test/VoiceAgentInputCoreTests"
        )
    ]
)
