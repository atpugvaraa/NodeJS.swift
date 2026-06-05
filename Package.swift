// swift-tools-version: 6.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "NodeJS",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "NodeJS",
            targets: ["NodeJS"]
        )
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "NodeJS",
            dependencies: ["NodeMobile"],
            resources: [
                .copy("../../nodejs-project")
            ]
        ),
        .binaryTarget(
            name: "NodeMobile",
            url:
                "https://github.com/nodejs-mobile/nodejs-mobile/releases/download/v18.20.4/nodejs-mobile-v18.20.4-ios.zip",
            checksum: "8c5ca3a0d1e38de7f182a5642593e82593b820efd375a14b3ecafc4bcfee620e"
        ),
        .testTarget(
            name: "NodeJSTests",
            dependencies: ["NodeJS"]
        ),
    ],
    swiftLanguageModes: [.v6]
)
