// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "SudokuKit",
    platforms: [.iOS(.v26), .macOS(.v26)],
    products: [
        .library(name: "SudokuKit", targets: ["SudokuKit"]),
    ],
    targets: [
        .target(name: "SudokuKit"),
        .testTarget(
            name: "SudokuKitTests",
            dependencies: ["SudokuKit"]
        ),
    ]
)
