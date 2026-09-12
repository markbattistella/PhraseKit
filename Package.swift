// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "PhraseKit",
    platforms: [
        .iOS(.v15),
        .macOS(.v12),
        .macCatalyst(.v15),
        .tvOS(.v15),
        .watchOS(.v9),
        .visionOS(.v1),
    ],
    products: [
        .library(
            name: "PhraseKit",
            targets: ["PhraseKit"]
        )
    ],
    targets: [
        .target(
            name: "PhraseKit",
            resources: [
                .process("Resources/_adjective.json"),
                .process("Resources/_adverb.json"),
                .process("Resources/_noun.json"),
                .process("Resources/_verb.json"),
            ],
            swiftSettings: [
                .swiftLanguageMode(.v6)
            ]
        ),
        .testTarget(
            name: "PhraseKitTests",
            dependencies: ["PhraseKit"],
            swiftSettings: [
                .swiftLanguageMode(.v6)
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)
