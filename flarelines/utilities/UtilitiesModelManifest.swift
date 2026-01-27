// ABOUTME: Fetches and parses the model manifest from Cloudflare R2.
// ABOUTME: Provides cached access to available model information.

import Foundation

/// Errors that can occur during manifest operations
enum ManifestError: Error, LocalizedError {
    case networkError(underlying: Error)
    case invalidResponse(statusCode: Int)
    case decodingFailed(underlying: Error)
    case noModelsAvailable
    case manifestExpired

    var errorDescription: String? {
        switch self {
        case .networkError(let error):
            return "Network error fetching manifest: \(error.localizedDescription)"
        case .invalidResponse(let code):
            return "Invalid response from server: HTTP \(code)"
        case .decodingFailed(let error):
            return "Failed to decode manifest: \(error.localizedDescription)"
        case .noModelsAvailable:
            return "No models available in manifest"
        case .manifestExpired:
            return "Cached manifest has expired"
        }
    }
}

/// Information about a downloadable model
struct ModelInfo: Codable, Identifiable, Equatable {
    let id: String
    let version: String
    let filename: String
    let sizeBytes: Int64
    let sha256: String
    let minAppVersion: String
    let downloadUrl: String

    /// Formatted file size for display
    var formattedSize: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useGB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: sizeBytes)
    }
}

/// The full model manifest from the server
struct ModelManifest: Codable {
    let schemaVersion: Int
    let models: [ModelInfo]
    let currentVersion: String
}

/// Thread-safe fetcher for the model manifest with caching
actor ManifestFetcher {
    static let shared = ManifestFetcher()

    private let manifestURL = URL(string: "https://pub-e89520e024ba41e299dfd77556755146.r2.dev/models.json")!
    private let cacheValidityDuration: TimeInterval = 3600 // 1 hour

    private var cachedManifest: ModelManifest?
    private var cacheTimestamp: Date?

    private init() {}

    /// Fetches the manifest, using cache if still valid
    func fetchManifest(forceRefresh: Bool = false) async throws -> ModelManifest {
        // Return cached manifest if still valid and not forcing refresh
        if !forceRefresh, let cached = cachedManifest, let timestamp = cacheTimestamp {
            if Date().timeIntervalSince(timestamp) < cacheValidityDuration {
                return cached
            }
        }

        // Fetch from network
        let manifest = try await fetchFromNetwork()

        // Update cache
        cachedManifest = manifest
        cacheTimestamp = Date()

        return manifest
    }

    /// Returns the current/latest model from the manifest
    func currentModel() async throws -> ModelInfo? {
        let manifest = try await fetchManifest()

        // Find model matching currentVersion
        if let model = manifest.models.first(where: { $0.version == manifest.currentVersion }) {
            return model
        }

        // Fall back to first model if no version match
        return manifest.models.first
    }

    /// Returns all available models
    func allModels() async throws -> [ModelInfo] {
        let manifest = try await fetchManifest()
        return manifest.models
    }

    /// Clears the cached manifest
    func clearCache() {
        cachedManifest = nil
        cacheTimestamp = nil
    }

    /// Checks if the app version meets minimum requirements for a model
    func isAppVersionCompatible(with model: ModelInfo) -> Bool {
        guard let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String else {
            return true // If we can't determine app version, assume compatible
        }
        return compareVersions(appVersion, model.minAppVersion) >= 0
    }

    // MARK: - Private

    private func fetchFromNetwork() async throws -> ModelManifest {
        var request = URLRequest(url: manifestURL)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.timeoutInterval = 30

        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw ManifestError.networkError(underlying: error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ManifestError.invalidResponse(statusCode: 0)
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw ManifestError.invalidResponse(statusCode: httpResponse.statusCode)
        }

        do {
            let decoder = JSONDecoder()
            return try decoder.decode(ModelManifest.self, from: data)
        } catch {
            throw ManifestError.decodingFailed(underlying: error)
        }
    }

    /// Compares semantic version strings. Returns negative if a < b, 0 if equal, positive if a > b
    private func compareVersions(_ a: String, _ b: String) -> Int {
        let aParts = a.split(separator: ".").compactMap { Int($0) }
        let bParts = b.split(separator: ".").compactMap { Int($0) }

        let maxLength = max(aParts.count, bParts.count)

        for i in 0..<maxLength {
            let aVal = i < aParts.count ? aParts[i] : 0
            let bVal = i < bParts.count ? bParts[i] : 0

            if aVal != bVal {
                return aVal - bVal
            }
        }

        return 0
    }
}
