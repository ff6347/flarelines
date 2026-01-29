// ABOUTME: Tests for ModelManifest data structures and version comparison.
// ABOUTME: Validates JSON decoding, model info formatting, and semantic versioning.

import Foundation
import Testing
@testable import Flarelines

// MARK: - Version Comparison Helper

/// Replicates ManifestFetcher.compareVersions for testing
/// Returns negative if a < b, 0 if equal, positive if a > b
enum VersionComparator {
    static func compare(_ a: String, _ b: String) -> Int {
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

struct ModelManifestTests {

    // MARK: - Version Comparison Tests (Parameterized)

    @Test(arguments: [
        ("1.0.0", "1.0.0", 0),
        ("2.1.3", "2.1.3", 0),
        ("2.0.0", "1.0.0", 1),
        ("1.0.0", "2.0.0", -1),
        ("1.2.0", "1.1.0", 1),
        ("1.1.0", "1.2.0", -1),
        ("1.0.2", "1.0.1", 1),
        ("1.0.1", "1.0.2", -1),
        ("1.0", "1.0.0", 0),
        ("1.0.0", "1.0", 0),
        ("1.1", "1.0.9", 1),
        ("2", "1", 1),
        ("1", "2", -1),
        ("1", "1", 0),
        ("1.10.0", "1.9.0", 1),
        ("1.100.0", "1.99.0", 1),
        ("0.0.1", "0.0.0", 1),
        ("10.0.0", "9.9.9", 1),
    ])
    func versionComparison(a: String, b: String, expected: Int) {
        let result = VersionComparator.compare(a, b)
        if expected == 0 {
            #expect(result == 0, "Expected \(a) == \(b)")
        } else if expected > 0 {
            #expect(result > 0, "Expected \(a) > \(b)")
        } else {
            #expect(result < 0, "Expected \(a) < \(b)")
        }
    }

    @Test func compareEmptyVersions() {
        #expect(VersionComparator.compare("", "") == 0)
        #expect(VersionComparator.compare("1.0.0", "") > 0)
        #expect(VersionComparator.compare("", "1.0.0") < 0)
    }

    // MARK: - ModelInfo Tests

    @Test func modelInfoFormattedSizeForMegabytes() {
        let model = ModelInfo(
            id: "test",
            version: "1.0.0",
            filename: "test.gguf",
            sizeBytes: 500 * 1024 * 1024, // 500 MB
            sha256: "abc123",
            minAppVersion: "1.0.0",
            downloadUrl: "https://example.com/test.gguf"
        )

        // ByteCountFormatter returns localized string, just check it's not empty
        #expect(!model.formattedSize.isEmpty)
        // Should contain MB for this size
        #expect(model.formattedSize.contains("MB") || model.formattedSize.contains("Mo"))
    }

    @Test func modelInfoFormattedSizeForGigabytes() {
        let model = ModelInfo(
            id: "test",
            version: "1.0.0",
            filename: "test.gguf",
            sizeBytes: 2 * 1024 * 1024 * 1024, // 2 GB
            sha256: "abc123",
            minAppVersion: "1.0.0",
            downloadUrl: "https://example.com/test.gguf"
        )

        #expect(!model.formattedSize.isEmpty)
        // Should contain GB for this size
        #expect(model.formattedSize.contains("GB") || model.formattedSize.contains("Go"))
    }

    @Test func modelInfoIdentifiable() {
        let model = ModelInfo(
            id: "unique-id",
            version: "1.0.0",
            filename: "test.gguf",
            sizeBytes: 1000,
            sha256: "abc123",
            minAppVersion: "1.0.0",
            downloadUrl: "https://example.com/test.gguf"
        )

        #expect(model.id == "unique-id")
    }

    @Test func modelInfoEquatable() {
        let model1 = ModelInfo(
            id: "test",
            version: "1.0.0",
            filename: "test.gguf",
            sizeBytes: 1000,
            sha256: "abc123",
            minAppVersion: "1.0.0",
            downloadUrl: "https://example.com/test.gguf"
        )

        let model2 = ModelInfo(
            id: "test",
            version: "1.0.0",
            filename: "test.gguf",
            sizeBytes: 1000,
            sha256: "abc123",
            minAppVersion: "1.0.0",
            downloadUrl: "https://example.com/test.gguf"
        )

        #expect(model1 == model2)
    }

    // MARK: - JSON Decoding Tests

    @Test func decodeModelInfoFromJSON() throws {
        let json = """
        {
            "id": "model-1",
            "version": "2.0.0",
            "filename": "model.gguf",
            "sizeBytes": 1073741824,
            "sha256": "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855",
            "minAppVersion": "1.5.0",
            "downloadUrl": "https://cdn.example.com/model.gguf"
        }
        """

        let data = json.data(using: .utf8)!
        let model = try JSONDecoder().decode(ModelInfo.self, from: data)

        #expect(model.id == "model-1")
        #expect(model.version == "2.0.0")
        #expect(model.filename == "model.gguf")
        #expect(model.sizeBytes == 1073741824)
        #expect(model.sha256 == "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855")
        #expect(model.minAppVersion == "1.5.0")
        #expect(model.downloadUrl == "https://cdn.example.com/model.gguf")
    }

    @Test func decodeModelManifestFromJSON() throws {
        let json = """
        {
            "schemaVersion": 1,
            "currentVersion": "2.0.0",
            "models": [
                {
                    "id": "model-1",
                    "version": "1.0.0",
                    "filename": "v1.gguf",
                    "sizeBytes": 500000000,
                    "sha256": "abc",
                    "minAppVersion": "1.0.0",
                    "downloadUrl": "https://example.com/v1.gguf"
                },
                {
                    "id": "model-2",
                    "version": "2.0.0",
                    "filename": "v2.gguf",
                    "sizeBytes": 800000000,
                    "sha256": "def",
                    "minAppVersion": "1.5.0",
                    "downloadUrl": "https://example.com/v2.gguf"
                }
            ]
        }
        """

        let data = json.data(using: .utf8)!
        let manifest = try JSONDecoder().decode(ModelManifest.self, from: data)

        #expect(manifest.schemaVersion == 1)
        #expect(manifest.currentVersion == "2.0.0")
        #expect(manifest.models.count == 2)
        #expect(manifest.models[0].id == "model-1")
        #expect(manifest.models[1].id == "model-2")
    }
}

// MARK: - ManifestError Tests

struct ManifestErrorTests {

    @Test func networkErrorContainsUnderlyingError() {
        let underlying = NSError(domain: "test", code: -1, userInfo: [NSLocalizedDescriptionKey: "Connection failed"])
        let error = ManifestError.networkError(underlying: underlying)

        #expect(error.errorDescription?.contains("Connection failed") == true)
    }

    @Test func invalidResponseContainsStatusCode() {
        let error = ManifestError.invalidResponse(statusCode: 404)
        #expect(error.errorDescription?.contains("404") == true)
    }

    @Test func noModelsAvailableHasDescription() {
        let error = ManifestError.noModelsAvailable
        #expect(error.errorDescription != nil)
        #expect(!error.errorDescription!.isEmpty)
    }
}
