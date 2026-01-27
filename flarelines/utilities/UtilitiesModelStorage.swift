// ABOUTME: Manages local file system operations for downloaded GGUF models.
// ABOUTME: Handles storage in Application Support, checksum validation, and disk space queries.

import Foundation
import CommonCrypto

/// Errors that can occur during model storage operations
enum ModelStorageError: Error, LocalizedError {
    case directoryCreationFailed(underlying: Error)
    case modelNotFound(filename: String)
    case deletionFailed(underlying: Error)
    case checksumMismatch(expected: String, actual: String)
    case checksumReadFailed(underlying: Error)
    case insufficientSpace(required: Int64, available: Int64)

    var errorDescription: String? {
        switch self {
        case .directoryCreationFailed(let error):
            return "Failed to create model directory: \(error.localizedDescription)"
        case .modelNotFound(let filename):
            return "Model not found: \(filename)"
        case .deletionFailed(let error):
            return "Failed to delete model: \(error.localizedDescription)"
        case .checksumMismatch(let expected, let actual):
            return "Checksum mismatch. Expected: \(expected), Got: \(actual)"
        case .checksumReadFailed(let error):
            return "Failed to read file for checksum: \(error.localizedDescription)"
        case .insufficientSpace(let required, let available):
            return "Insufficient space. Required: \(required) bytes, Available: \(available) bytes"
        }
    }
}

/// Thread-safe manager for model file storage operations
actor ModelStorage {
    static let shared = ModelStorage()

    private let fileManager = FileManager.default
    private let modelsDirectoryName = "Models"

    private init() {}

    /// Returns the Application Support/Models directory, creating it if needed
    func modelDirectory() throws -> URL {
        let appSupport = try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )

        let modelsDir = appSupport.appendingPathComponent(modelsDirectoryName, isDirectory: true)

        if !fileManager.fileExists(atPath: modelsDir.path) {
            do {
                try fileManager.createDirectory(at: modelsDir, withIntermediateDirectories: true)
            } catch {
                throw ModelStorageError.directoryCreationFailed(underlying: error)
            }
        }

        return modelsDir
    }

    /// Returns the full path for a model file
    func modelPath(for filename: String) throws -> URL {
        let directory = try modelDirectory()
        return directory.appendingPathComponent(filename)
    }

    /// Checks if a model file exists locally
    func modelExists(filename: String) -> Bool {
        guard let path = try? modelPath(for: filename) else {
            return false
        }
        return fileManager.fileExists(atPath: path.path)
    }

    /// Validates the SHA256 checksum of a file against an expected value
    func validateChecksum(at url: URL, expected: String) async throws -> Bool {
        let actualChecksum = try await computeSHA256(at: url)
        let matches = actualChecksum.lowercased() == expected.lowercased()

        if !matches {
            throw ModelStorageError.checksumMismatch(expected: expected, actual: actualChecksum)
        }

        return true
    }

    /// Deletes a model file from storage
    func deleteModel(filename: String) throws {
        let path = try modelPath(for: filename)

        guard fileManager.fileExists(atPath: path.path) else {
            throw ModelStorageError.modelNotFound(filename: filename)
        }

        do {
            try fileManager.removeItem(at: path)
        } catch {
            throw ModelStorageError.deletionFailed(underlying: error)
        }
    }

    /// Returns available disk space in bytes, or -1 if unable to determine
    func availableSpace() -> Int64 {
        do {
            let directory = try modelDirectory()
            let attributes = try fileManager.attributesOfFileSystem(forPath: directory.path)
            if let freeSpace = attributes[.systemFreeSize] as? Int64 {
                return freeSpace
            }
        } catch {
            // Fall through to return -1
        }
        return -1
    }

    /// Checks if there's enough space for a download of the given size
    func hasSpaceFor(bytes: Int64) -> Bool {
        let available = availableSpace()
        guard available > 0 else {
            // If we can't determine space, assume it's available
            return true
        }
        // Require 10% extra space as buffer
        let requiredWithBuffer = Int64(Double(bytes) * 1.1)
        return available >= requiredWithBuffer
    }

    /// Returns the size of a model file in bytes, or nil if not found
    func modelSize(filename: String) -> Int64? {
        guard let path = try? modelPath(for: filename),
              let attributes = try? fileManager.attributesOfItem(atPath: path.path),
              let size = attributes[.size] as? Int64 else {
            return nil
        }
        return size
    }

    // MARK: - Private

    /// Computes SHA256 hash of a file, streaming to handle large files
    private func computeSHA256(at url: URL) async throws -> String {
        let handle: FileHandle
        do {
            handle = try FileHandle(forReadingFrom: url)
        } catch {
            throw ModelStorageError.checksumReadFailed(underlying: error)
        }

        defer {
            try? handle.close()
        }

        var context = CC_SHA256_CTX()
        CC_SHA256_Init(&context)

        let bufferSize = 1024 * 1024 // 1MB chunks for large files

        while autoreleasepool(invoking: {
            guard let data = try? handle.read(upToCount: bufferSize), !data.isEmpty else {
                return false
            }
            data.withUnsafeBytes { buffer in
                _ = CC_SHA256_Update(&context, buffer.baseAddress, CC_LONG(buffer.count))
            }
            return true
        }) {}

        var digest = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        CC_SHA256_Final(&digest, &context)

        return digest.map { String(format: "%02x", $0) }.joined()
    }
}
