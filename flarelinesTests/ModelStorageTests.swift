// ABOUTME: Tests for ModelStorage error types and helper logic.
// ABOUTME: Validates error descriptions and space calculation logic.

import Foundation
import Testing
@testable import Flarelines

// MARK: - Space Calculation Helper

/// Replicates the hasSpaceFor logic for testing
enum SpaceCalculator {
    /// Checks if there's enough space, requiring 10% buffer
    static func hasSpaceFor(bytes: Int64, available: Int64) -> Bool {
        guard available > 0 else {
            // If we can't determine space, assume it's available
            return true
        }
        // Require 10% extra space as buffer
        let requiredWithBuffer = Int64(Double(bytes) * 1.1)
        return available >= requiredWithBuffer
    }
}

struct ModelStorageTests {

    // MARK: - Space Calculation Tests

    @Test func hasSpaceForWithEnoughSpace() {
        // Need 100 bytes, have 200 available
        #expect(SpaceCalculator.hasSpaceFor(bytes: 100, available: 200) == true)
    }

    @Test func hasSpaceForWithExactBufferSpace() {
        // Need 100 bytes + 10% = 110, have exactly 110
        #expect(SpaceCalculator.hasSpaceFor(bytes: 100, available: 110) == true)
    }

    @Test func hasSpaceForWithInsufficientSpace() {
        // Need 100 bytes + 10% = 110, have only 100
        #expect(SpaceCalculator.hasSpaceFor(bytes: 100, available: 100) == false)
    }

    @Test func hasSpaceForWithZeroAvailable() {
        // Zero available should return true (assume available per implementation)
        #expect(SpaceCalculator.hasSpaceFor(bytes: 100, available: 0) == true)
    }

    @Test func hasSpaceForWithNegativeAvailable() {
        // Negative means we couldn't determine, return true
        #expect(SpaceCalculator.hasSpaceFor(bytes: 100, available: -1) == true)
    }

    @Test func hasSpaceForLargeFiles() {
        let oneGB: Int64 = 1024 * 1024 * 1024
        let twoGB: Int64 = 2 * oneGB

        // Need 1GB + 10% buffer
        #expect(SpaceCalculator.hasSpaceFor(bytes: oneGB, available: twoGB) == true)
        #expect(SpaceCalculator.hasSpaceFor(bytes: oneGB, available: oneGB) == false)
    }

    // MARK: - ModelStorageError Tests

    @Test func directoryCreationFailedErrorDescription() {
        let underlying = NSError(domain: "test", code: -1, userInfo: [NSLocalizedDescriptionKey: "Permission denied"])
        let error = ModelStorageError.directoryCreationFailed(underlying: underlying)

        #expect(error.errorDescription?.contains("Permission denied") == true)
    }

    @Test func modelNotFoundErrorContainsFilename() {
        let error = ModelStorageError.modelNotFound(filename: "missing-model.gguf")
        #expect(error.errorDescription?.contains("missing-model.gguf") == true)
    }

    @Test func checksumMismatchContainsBothHashes() {
        let error = ModelStorageError.checksumMismatch(
            expected: "abc123",
            actual: "def456"
        )

        #expect(error.errorDescription?.contains("abc123") == true)
        #expect(error.errorDescription?.contains("def456") == true)
    }

    @Test func insufficientSpaceContainsSizes() {
        let error = ModelStorageError.insufficientSpace(
            required: 1000000,
            available: 500000
        )

        #expect(error.errorDescription?.contains("1000000") == true)
        #expect(error.errorDescription?.contains("500000") == true)
    }

    @Test func deletionFailedContainsUnderlyingError() {
        let underlying = NSError(domain: "test", code: -1, userInfo: [NSLocalizedDescriptionKey: "File in use"])
        let error = ModelStorageError.deletionFailed(underlying: underlying)

        #expect(error.errorDescription?.contains("File in use") == true)
    }
}
