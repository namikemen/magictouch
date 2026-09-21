import Foundation

/// Update manifest matching the modern distribution standard (e.g. Tauri / Sparkle JSON style)
public struct UpdateManifest: Codable {
    public let version: String
    public let notes: String?
    public let pubDate: String?
    public let platforms: [String: PlatformAsset]?

    enum CodingKeys: String, CodingKey {
        case version
        case notes
        case pubDate = "pub_date"
        case platforms
    }

    public init(version: String, notes: String?, pubDate: String?, platforms: [String: PlatformAsset]?) {
        self.version = version
        self.notes = notes
        self.pubDate = pubDate
        self.platforms = platforms
    }
}

public struct PlatformAsset: Codable {
    public let url: String
    public let signature: String?

    public init(url: String, signature: String? = nil) {
        self.url = url
        self.signature = signature
    }
}

/// Fallback model for GitHub Releases REST API (/repos/:owner/:repo/releases/latest)
public struct GitHubRelease: Codable {
    public let tagName: String
    public let name: String?
    public let body: String?
    public let htmlUrl: String
    public let assets: [GitHubAsset]

    enum CodingKeys: String, CodingKey {
        case tagName = "tag_name"
        case name
        case body
        case htmlUrl = "html_url"
        case assets
    }

    public init(tagName: String, name: String?, body: String?, htmlUrl: String, assets: [GitHubAsset]) {
        self.tagName = tagName
        self.name = name
        self.body = body
        self.htmlUrl = htmlUrl
        self.assets = assets
    }
}

public struct GitHubAsset: Codable {
    public let name: String
    public let browserDownloadUrl: String

    enum CodingKeys: String, CodingKey {
        case name
        case browserDownloadUrl = "browser_download_url"
    }

    public init(name: String, browserDownloadUrl: String) {
        self.name = name
        self.browserDownloadUrl = browserDownloadUrl
    }
}

/// Robust Semantic Version comparison helper supporting strings like "v1.0.1", "1.2", "2.0.0-beta"
public struct SemVer: Comparable, CustomStringConvertible {
    public let major: Int
    public let minor: Int
    public let patch: Int
    public let raw: String

    public var description: String {
        return raw
    }

    public init(_ versionString: String) {
        self.raw = versionString
        var clean = versionString.trimmingCharacters(in: .whitespacesAndNewlines)
        if clean.hasPrefix("v") || clean.hasPrefix("V") {
            clean.removeFirst()
        }

        // Strip any prerelease suffix like -beta, -rc1
        let core = clean.components(separatedBy: "-").first ?? clean
        let parts = core.components(separatedBy: ".").compactMap { Int($0) }

        self.major = parts.indices.contains(0) ? parts[0] : 0
        self.minor = parts.indices.contains(1) ? parts[1] : 0
        self.patch = parts.indices.contains(2) ? parts[2] : 0
    }

    public static func < (lhs: SemVer, rhs: SemVer) -> Bool {
        if lhs.major != rhs.major {
            return lhs.major < rhs.major
        }
        if lhs.minor != rhs.minor {
            return lhs.minor < rhs.minor
        }
        return lhs.patch < rhs.patch
    }

    public static func == (lhs: SemVer, rhs: SemVer) -> Bool {
        return lhs.major == rhs.major && lhs.minor == rhs.minor && lhs.patch == rhs.patch
    }
}
