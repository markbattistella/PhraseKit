// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "PhraseKit",
	platforms: [
		.iOS(.v12),
		.macOS(.v10_14),
		.macCatalyst(.v13),
		.tvOS(.v12),
        .watchOS(.v5),
        .visionOS(.v1)
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
                .process("Resources/_verb.json")
            ],
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
		),
        .testTarget(
            name: "PhraseKitTests",
            dependencies: ["PhraseKit"]
        )
    ]
)
