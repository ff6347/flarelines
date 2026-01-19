// ABOUTME: Downloads GGUF models from remote URLs with background URLSession support.
// ABOUTME: Provides progress tracking, resume capability, and SHA256 checksum validation.

import Foundation
import CryptoKit

// MARK: - Errors

enum ModelDownloadError: LocalizedError {
    case downloadInProgress
    case noActiveDownload
    case checksumMismatch(expected: String, actual: String)
    case fileMoveFailed(underlying: Error)
    case invalidResponse(statusCode: Int)
    case noResumeData

    var errorDescription: String? {
        switch self {
        case .downloadInProgress:
            return "A download is already in progress"
        case .noActiveDownload:
            return "No active download to cancel or pause"
        case .checksumMismatch(let expected, let actual):
            return "Checksum validation failed. Expected: \(expected), got: \(actual)"
        case .fileMoveFailed(let underlying):
            return "Failed to move downloaded file: \(underlying.localizedDescription)"
        case .invalidResponse(let statusCode):
            return "Server returned status code \(statusCode)"
        case .noResumeData:
            return "No resume data available"
        }
    }
}

// MARK: - Network Status

enum NetworkType {
    case wifi
    case cellular
    case unknown
}

// MARK: - ModelDownloader

@Observable
final class ModelDownloader: NSObject {
    /// Shared instance for app-wide download state
    static let shared = ModelDownloader()

    // MARK: - Published State

    var downloadProgress: Double = 0
    var bytesDownloaded: Int64 = 0
    var totalBytes: Int64 = 0
    var isDownloading: Bool = false
    var error: Error?

    // MARK: - Private State

    private var backgroundSession: URLSession?
    private var downloadTask: URLSessionDownloadTask?
    private var resumeData: Data?
    private var pendingDestination: URL?
    private var pendingChecksum: String?
    private var downloadContinuation: CheckedContinuation<Void, Error>?

    private static let backgroundSessionIdentifier = "com.wolfsbit.modeldownload"

    // MARK: - Initialization

    override init() {
        super.init()
        setupBackgroundSession()
    }

    private func setupBackgroundSession() {
        let config = URLSessionConfiguration.background(
            withIdentifier: Self.backgroundSessionIdentifier
        )
        config.isDiscretionary = false
        config.sessionSendsLaunchEvents = true
        config.allowsCellularAccess = true

        backgroundSession = URLSession(
            configuration: config,
            delegate: self,
            delegateQueue: nil
        )
    }

    // MARK: - Public API

    /// Downloads a model from the specified URL to the destination path.
    /// Validates the SHA256 checksum after download completes.
    ///
    /// - Parameters:
    ///   - url: Remote URL to download from (e.g., Cloudflare R2)
    ///   - destination: Local file URL where the model should be saved
    ///   - expectedSHA256: Expected SHA256 hash for checksum validation
    /// - Throws: ModelDownloadError if download fails or checksum doesn't match
    func downloadModel(from url: URL, to destination: URL, expectedSHA256: String) async throws {
        // Atomically check and set isDownloading to prevent duplicate downloads
        let canStart = await MainActor.run {
            if isDownloading {
                return false
            }
            isDownloading = true
            downloadProgress = 0
            bytesDownloaded = 0
            totalBytes = 0
            error = nil
            return true
        }

        guard canStart else {
            throw ModelDownloadError.downloadInProgress
        }

        pendingDestination = destination
        pendingChecksum = expectedSHA256

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            self.downloadContinuation = continuation

            if let resumeData = self.resumeData {
                self.downloadTask = self.backgroundSession?.downloadTask(withResumeData: resumeData)
                self.resumeData = nil
            } else {
                self.downloadTask = self.backgroundSession?.downloadTask(with: url)
            }

            self.downloadTask?.resume()
        }
    }

    /// Cancels the current download. The download cannot be resumed after cancellation.
    func cancelDownload() {
        guard isDownloading, let task = downloadTask else {
            return
        }

        task.cancel()
        cleanupDownload(with: CancellationError())
    }

    /// Pauses the current download. Call `resumeDownload()` to continue.
    func pauseDownload() {
        guard isDownloading, let task = downloadTask else {
            return
        }

        task.cancel { [weak self] resumeDataOrNil in
            self?.resumeData = resumeDataOrNil
            Task { @MainActor in
                self?.isDownloading = false
            }
        }
    }

    /// Resumes a previously paused download.
    /// - Throws: ModelDownloadError.noResumeData if there's no paused download
    func resumeDownload() async throws {
        guard let resumeData = resumeData else {
            throw ModelDownloadError.noResumeData
        }

        guard pendingDestination != nil, pendingChecksum != nil else {
            throw ModelDownloadError.noResumeData
        }

        await MainActor.run {
            self.isDownloading = true
            self.error = nil
        }

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            self.downloadContinuation = continuation
            self.downloadTask = self.backgroundSession?.downloadTask(withResumeData: resumeData)
            self.resumeData = nil
            self.downloadTask?.resume()
        }
    }

    /// Checks if resume data is available from a paused download.
    var canResume: Bool {
        resumeData != nil
    }

    /// Detects current network type. Use to warn users before large cellular downloads.
    func detectNetworkType() -> NetworkType {
        // Simple heuristic using URLSession configuration
        // For production, consider using NWPathMonitor from Network framework
        guard let session = backgroundSession else { return .unknown }
        return session.configuration.allowsCellularAccess ? .cellular : .wifi
    }

    // MARK: - Private Helpers

    private func cleanupDownload(with error: Error?) {
        Task { @MainActor in
            self.isDownloading = false
            self.error = error
        }

        if let continuation = downloadContinuation {
            downloadContinuation = nil
            if let error = error {
                continuation.resume(throwing: error)
            } else {
                continuation.resume()
            }
        }

        downloadTask = nil
    }

    /// Moves the temp file to the final destination synchronously.
    /// Must be called synchronously from the delegate before it returns.
    private func moveToSafeLocation(from tempURL: URL) throws -> URL {
        guard let destination = pendingDestination else {
            throw ModelDownloadError.fileMoveFailed(underlying: NSError(
                domain: "ModelDownloader",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "No destination configured"]
            ))
        }

        let fileManager = FileManager.default

        // Remove existing file if present
        if fileManager.fileExists(atPath: destination.path) {
            try fileManager.removeItem(at: destination)
        }

        // Create parent directory if needed
        let parentDir = destination.deletingLastPathComponent()
        if !fileManager.fileExists(atPath: parentDir.path) {
            try fileManager.createDirectory(at: parentDir, withIntermediateDirectories: true)
        }

        // Move file from temp location - this must complete before delegate returns
        do {
            try fileManager.moveItem(at: tempURL, to: destination)
        } catch {
            throw ModelDownloadError.fileMoveFailed(underlying: error)
        }

        return destination
    }

    /// Validates checksum and cleans up if invalid. Called async after file is safely moved.
    private func validateAndFinalize(at fileURL: URL) async throws {
        guard let expectedChecksum = pendingChecksum else {
            throw ModelDownloadError.fileMoveFailed(underlying: NSError(
                domain: "ModelDownloader",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "No checksum configured"]
            ))
        }

        let actualChecksum = try await computeSHA256(at: fileURL)
        let isValid = actualChecksum.lowercased() == expectedChecksum.lowercased()

        if !isValid {
            // Delete invalid file
            try? FileManager.default.removeItem(at: fileURL)
            throw ModelDownloadError.checksumMismatch(expected: expectedChecksum, actual: actualChecksum)
        }
    }

    private func computeSHA256(at url: URL) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    let handle = try FileHandle(forReadingFrom: url)
                    defer { try? handle.close() }

                    var hasher = SHA256()
                    let bufferSize = 1024 * 1024 // 1MB chunks

                    while autoreleasepool(invoking: {
                        let data = handle.readData(ofLength: bufferSize)
                        if data.isEmpty { return false }
                        hasher.update(data: data)
                        return true
                    }) {}

                    let digest = hasher.finalize()
                    let hashString = digest.map { String(format: "%02x", $0) }.joined()
                    continuation.resume(returning: hashString)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}

// MARK: - URLSessionDownloadDelegate

extension ModelDownloader: URLSessionDownloadDelegate {

    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didFinishDownloadingTo location: URL
    ) {
        // URLSession deletes the temp file when this delegate returns, so we must
        // move the file synchronously BEFORE returning from this method.
        do {
            let movedURL = try moveToSafeLocation(from: location)

            // Now we can do async validation since we own the file
            Task {
                do {
                    try await validateAndFinalize(at: movedURL)
                    Analytics.signal("modelDownloadCompleted")
                    cleanupDownload(with: nil)
                } catch {
                    Analytics.signal("modelDownloadFailed")
                    cleanupDownload(with: error)
                }
            }
        } catch {
            Analytics.signal("modelDownloadFailed")
            cleanupDownload(with: error)
        }
    }

    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didWriteData bytesWritten: Int64,
        totalBytesWritten: Int64,
        totalBytesExpectedToWrite: Int64
    ) {
        Task { @MainActor in
            self.bytesDownloaded = totalBytesWritten
            self.totalBytes = totalBytesExpectedToWrite

            if totalBytesExpectedToWrite > 0 {
                self.downloadProgress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
            }
        }
    }

    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didCompleteWithError error: Error?
    ) {
        if let error = error {
            // Check if this is a cancellation with resume data
            let nsError = error as NSError
            if nsError.code == NSURLErrorCancelled,
               let resumeData = nsError.userInfo[NSURLSessionDownloadTaskResumeData] as? Data {
                self.resumeData = resumeData
                Task { @MainActor in
                    self.isDownloading = false
                }
                return
            }

            cleanupDownload(with: error)
        }
    }

    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        guard let identifier = session.configuration.identifier,
              let completionHandler = AppDelegate.backgroundCompletionHandlers.removeValue(forKey: identifier) else {
            return
        }

        DispatchQueue.main.async {
            completionHandler()
        }
    }
}

// MARK: - URLSessionDelegate

extension ModelDownloader: URLSessionDelegate {

    func urlSession(
        _ session: URLSession,
        didBecomeInvalidWithError error: Error?
    ) {
        if let error = error {
            cleanupDownload(with: error)
        }
        setupBackgroundSession()
    }
}
