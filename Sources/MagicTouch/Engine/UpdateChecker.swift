import Foundation
import AppKit
import Combine

/// Engine responsible for checking for application updates, tracking download progress,
/// and launching the updated DMG installer.
public final class UpdateChecker: NSObject, ObservableObject, URLSessionDownloadDelegate {
    public static let shared = UpdateChecker()

    // Configurable URLs
    public let repoOwner = "namikemen"
    public let repoName = "magictouch"

    public var manifestURL: URL {
        URL(string: "https://github.com/\(repoOwner)/\(repoName)/releases/latest/download/latest.json")!
    }

    public var releasesApiURL: URL {
        URL(string: "https://api.github.com/repos/\(repoOwner)/\(repoName)/releases/latest")!
    }

    // Published state
    @Published public var currentVersion: String = "0.1.1"
    @Published public var isChecking: Bool = false
    @Published public var isUpdateAvailable: Bool = false
    @Published public var latestVersion: String = ""
    @Published public var releaseNotes: String = ""
    @Published public var downloadURL: URL? = nil
    @Published public var releasePageURL: URL? = nil
    @Published public var isDownloading: Bool = false
    @Published public var downloadProgress: Double = 0.0
    @Published public var statusMessage: String? = nil
    @Published public var isDismissed: Bool = false

    private var downloadTask: URLSessionDownloadTask?
    private lazy var urlSession: URLSession = {
        let config = URLSessionConfiguration.default
        return URLSession(configuration: config, delegate: self, delegateQueue: OperationQueue.main)
    }()

    override private init() {
        super.init()
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            self.currentVersion = version
        }
    }

    // MARK: - Check for Updates
    public func checkForUpdates(manual: Bool = false) {
        guard !isChecking else { return }

        DispatchQueue.main.async {
            self.isChecking = true
            if manual {
                self.statusMessage = "Checking for updates..."
                self.isDismissed = false
            }
        }

        // Try downloading latest.json manifest first
        var request = URLRequest(url: manifestURL)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.timeoutInterval = 10

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }

            if let data = data,
               let httpResponse = response as? HTTPURLResponse,
               (200...299).contains(httpResponse.statusCode),
               let manifest = try? JSONDecoder().decode(UpdateManifest.self, from: data) {
                self.processManifest(manifest, manual: manual)
            } else {
                // Fallback to GitHub Releases API
                self.fetchFromGitHubAPI(manual: manual)
            }
        }.resume()
    }

    private func fetchFromGitHubAPI(manual: Bool) {
        var request = URLRequest(url: releasesApiURL)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.timeoutInterval = 10
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        request.setValue("MagicTouch-App", forHTTPHeaderField: "User-Agent")

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }

            DispatchQueue.main.async {
                self.isChecking = false
            }

            if let error = error {
                DispatchQueue.main.async {
                    if manual {
                        let nsErr = error as NSError
                        if nsErr.domain == NSURLErrorDomain && nsErr.code == NSURLErrorNotConnectedToInternet {
                            self.statusMessage = "No internet connection."
                        } else {
                            self.statusMessage = "Connection failed: \(error.localizedDescription)"
                        }
                    }
                }
                return
            }

            guard let data = data, let httpResponse = response as? HTTPURLResponse else {
                DispatchQueue.main.async {
                    if manual {
                        self.statusMessage = "No response from server."
                    }
                }
                return
            }

            if httpResponse.statusCode == 404 {
                DispatchQueue.main.async {
                    if manual {
                        self.statusMessage = "No releases published yet on GitHub."
                    }
                }
                return
            }

            if httpResponse.statusCode == 403 {
                DispatchQueue.main.async {
                    if manual {
                        self.statusMessage = "GitHub API rate limit reached. Try later."
                    }
                }
                return
            }

            guard (200...299).contains(httpResponse.statusCode),
                  let release = try? JSONDecoder().decode(GitHubRelease.self, from: data) else {
                DispatchQueue.main.async {
                    if manual {
                        self.statusMessage = "Unable to read release metadata."
                    }
                }
                return
            }

            self.processGitHubRelease(release, manual: manual)
        }.resume()
    }

    private func processManifest(_ manifest: UpdateManifest, manual: Bool) {
        DispatchQueue.main.async {
            self.isChecking = false

            let remoteVer = SemVer(manifest.version)
            let localVer = SemVer(self.currentVersion)

            if remoteVer > localVer {
                self.latestVersion = manifest.version
                self.releaseNotes = manifest.notes ?? "A new version of MagicTouch is available."

                // Prefer DMG download url, fallback to platform url
                if let dmgUrlString = manifest.platforms?["dmg"]?.url, let url = URL(string: dmgUrlString) {
                    self.downloadURL = url
                } else if let darwinUrlString = manifest.platforms?["darwin-universal"]?.url, let url = URL(string: darwinUrlString) {
                    self.downloadURL = url
                } else {
                    self.downloadURL = URL(string: "https://github.com/\(self.repoOwner)/\(self.repoName)/releases/latest")
                }

                self.releasePageURL = URL(string: "https://github.com/\(self.repoOwner)/\(self.repoName)/releases/latest")
                self.isUpdateAvailable = true
                self.statusMessage = "Update available: v\(manifest.version)"
            } else {
                self.isUpdateAvailable = false
                if manual {
                    self.statusMessage = "MagicTouch is up to date (v\(self.currentVersion))."
                }
            }
        }
    }

    private func processGitHubRelease(_ release: GitHubRelease, manual: Bool) {
        DispatchQueue.main.async {
            self.isChecking = false

            let remoteVer = SemVer(release.tagName)
            let localVer = SemVer(self.currentVersion)

            if remoteVer > localVer {
                self.latestVersion = release.tagName
                self.releaseNotes = release.body ?? "A new version of MagicTouch is available."
                self.releasePageURL = URL(string: release.htmlUrl)

                // Look for DMG or zip asset
                if let dmgAsset = release.assets.first(where: { $0.name.lowercased().hasSuffix(".dmg") }),
                   let url = URL(string: dmgAsset.browserDownloadUrl) {
                    self.downloadURL = url
                } else if let zipAsset = release.assets.first(where: { $0.name.lowercased().hasSuffix(".zip") || $0.name.lowercased().hasSuffix(".tar.gz") }),
                          let url = URL(string: zipAsset.browserDownloadUrl) {
                    self.downloadURL = url
                } else {
                    self.downloadURL = URL(string: release.htmlUrl)
                }

                self.isUpdateAvailable = true
                self.statusMessage = "Update available: \(release.tagName)"
            } else {
                self.isUpdateAvailable = false
                if manual {
                    self.statusMessage = "MagicTouch is up to date (v\(self.currentVersion))."
                }
            }
        }
    }

    // MARK: - Download and Install
    public func startDownload() {
        guard let url = downloadURL, !isDownloading else {
            if let pageURL = releasePageURL ?? downloadURL {
                NSWorkspace.shared.open(pageURL)
            }
            return
        }

        // If it's a web page rather than a direct binary file, just open in browser
        let pathExt = url.pathExtension.lowercased()
        if pathExt != "dmg" && pathExt != "gz" && pathExt != "zip" {
            NSWorkspace.shared.open(url)
            return
        }

        isDownloading = true
        downloadProgress = 0.0
        statusMessage = "Starting download..."

        downloadTask = urlSession.downloadTask(with: url)
        downloadTask?.resume()
    }

    public func dismiss() {
        isDismissed = true
    }

    // MARK: - URLSessionDownloadDelegate
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        guard totalBytesExpectedToWrite > 0 else { return }
        let progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
        DispatchQueue.main.async {
            self.downloadProgress = progress
            self.statusMessage = String(format: "Downloading: %.0f%%", progress * 100.0)
        }
    }

    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        let fileManager = FileManager.default
        let downloadsDirectory = fileManager.urls(for: .downloadsDirectory, in: .userDomainMask).first!

        let filename = downloadTask.originalRequest?.url?.lastPathComponent ?? "MagicTouch-Update.dmg"
        let destinationURL = downloadsDirectory.appendingPathComponent(filename)

        do {
            if fileManager.fileExists(atPath: destinationURL.path) {
                try fileManager.removeItem(at: destinationURL)
            }
            try fileManager.moveItem(at: location, to: destinationURL)

            DispatchQueue.main.async {
                self.isDownloading = false
                self.downloadProgress = 1.0
                self.statusMessage = "Downloaded to Downloads folder!"

                // Open the downloaded DMG or reveal in Finder
                NSWorkspace.shared.open(destinationURL)
            }
        } catch {
            DispatchQueue.main.async {
                self.isDownloading = false
                self.statusMessage = "Failed to save update: \(error.localizedDescription)"
            }
        }
    }

    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            DispatchQueue.main.async {
                self.isDownloading = false
                self.statusMessage = "Download error: \(error.localizedDescription)"
            }
        }
    }
}
