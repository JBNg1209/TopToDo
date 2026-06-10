// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "TopToDo",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .executable(name: "TopToDo", targets: ["TopToDoApp"]),
        .executable(name: "TopToDoValidation", targets: ["TopToDoValidation"]),
        .library(name: "TopToDoCore", targets: ["TopToDoCore"]),
    ],
    targets: [
        .target(
            name: "TopToDoCore"
        ),
        .executableTarget(
            name: "TopToDoApp",
            dependencies: ["TopToDoCore"]
        ),
        .executableTarget(
            name: "TopToDoValidation",
            dependencies: ["TopToDoCore"]
        ),
    ]
)
