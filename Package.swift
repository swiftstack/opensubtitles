// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "OpenSubtitles",
    platforms: [
        .iOS(.v16),
        .macOS(.v13),
    ],
    products: [
        .library(
            name: "OpenSubtitles",
            targets: ["OpenSubtitles"]),
    ],
    dependencies: [
        .package(name: "HTTP"),
        .package(name: "RPC"),
        .package(name: "Radix"),
        .package(name: "FileSystem"),
        .package(name: "DCompression"),
        .package(name: "Test"),
    ],
    targets: [
        .target(
            name: "OpenSubtitles",
            dependencies: [
                .product(name: "HTTP", package: "http"),
                .product(name: "XMLRPC", package: "RPC"),
                .product(name: "Base64", package: "Radix"),
                .product(name: "FileSystem", package: "filesystem"),
                .product(name: "DCompression", package: "DCompression"),
            ],
            swiftSettings: swift6),
        .executableTarget(
            name: "Tests/OpenSubtitles",
            dependencies: [
                .target(name: "OpenSubtitles"),
                .product(name: "Test", package: "test"),
            ],
            path: "Tests/OpenSubtitles",
            resources: [.copy("test_hash")],
            swiftSettings: swift6),
    ]
)

let swift6: [SwiftSetting] = [
    .enableUpcomingFeature("ConciseMagicFile"),
    .enableUpcomingFeature("ForwardTrailingClosures"),
    .enableUpcomingFeature("ExistentialAny"),
    .enableUpcomingFeature("StrictConcurrency"),
    .enableUpcomingFeature("ImplicitOpenExistentials"),
    .enableUpcomingFeature("BareSlashRegexLiterals"),
]

// MARK: - custom package source

#if canImport(ObjectiveC)
import Darwin.C
#else
import Glibc
#endif

extension Package.Dependency {
    enum Source: String {
        case local, remote, github

        static var `default`: Self { .github }

        var baseUrl: String {
            switch self {
            case .local: return "../"
            case .remote: return "https://swiftstack.io/"
            case .github: return "https://github.com/swiftstack/"
            }
        }

        func url(for name: String) -> String {
            return self == .local
                ? baseUrl + name.lowercased()
                : baseUrl + name.lowercased() + ".git"
        }
    }

    static func package(name: String) -> Package.Dependency {
        guard let pointer = getenv("SWIFTSTACK") else {
            return .package(name: name, source: .default)
        }
        guard let source = Source(rawValue: String(cString: pointer)) else {
            fatalError("Invalid source. Use local, remote or github")
        }
        return .package(name: name, source: source)
    }

    static func package(name: String, source: Source) -> Package.Dependency {
        return source == .local
            ? .package(name: name, path: source.url(for: name))
            : .package(url: source.url(for: name), branch: "dev")
    }
}
