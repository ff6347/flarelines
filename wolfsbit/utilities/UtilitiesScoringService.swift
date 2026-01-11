// ABOUTME: Orchestrates ML scoring of diary entries using the GGUF model.
// ABOUTME: Manages model lifecycle and provides async scoring interface.

import Foundation

/// Errors that can occur during scoring operations
enum ScoringError: Error, LocalizedError {
    case modelNotAvailable
    case modelLoadFailed(underlying: Error)
    case scoringFailed(underlying: Error)
    case invalidScore(response: String)

    var errorDescription: String? {
        switch self {
        case .modelNotAvailable:
            return "Scoring model is not downloaded"
        case .modelLoadFailed(let error):
            return "Failed to load model: \(error.localizedDescription)"
        case .scoringFailed(let error):
            return "Scoring failed: \(error.localizedDescription)"
        case .invalidScore(let response):
            return "Could not extract valid score from response: \(response)"
        }
    }
}

/// Service for scoring diary entries using the local GGUF model
actor ScoringService {
    static let shared = ScoringService()

    private var llamaContext: LlamaContext?
    private var isLoading = false

    private init() {}

    // MARK: - Model Management

    /// Checks if the model is available locally
    func isModelAvailable() async -> Bool {
        do {
            guard let modelInfo = try await ManifestFetcher.shared.currentModel() else {
                return false
            }
            return await ModelStorage.shared.modelExists(filename: modelInfo.filename)
        } catch {
            return false
        }
    }

    /// Loads the model if not already loaded
    func loadModelIfNeeded() async throws {
        guard llamaContext == nil, !isLoading else { return }

        isLoading = true
        defer { isLoading = false }

        // Get model info from manifest
        guard let modelInfo = try await ManifestFetcher.shared.currentModel() else {
            throw ScoringError.modelNotAvailable
        }

        // Check if model exists locally
        guard await ModelStorage.shared.modelExists(filename: modelInfo.filename) else {
            throw ScoringError.modelNotAvailable
        }

        // Get model path
        let modelPath = try await ModelStorage.shared.modelPath(for: modelInfo.filename)

        // Load the model
        do {
            llamaContext = try LlamaContext.load(from: modelPath.path)
        } catch {
            throw ScoringError.modelLoadFailed(underlying: error)
        }
    }

    /// Unloads the model to free memory
    func unloadModel() {
        llamaContext = nil
    }

    // MARK: - Scoring

    /// Scores a diary entry and returns the activity score (0-3)
    /// - Parameter diaryText: German diary entry text
    /// - Returns: Activity score 0-3, or nil if scoring fails
    func scoreDiaryEntry(_ diaryText: String) async throws -> Int {
        // Ensure model is loaded
        try await loadModelIfNeeded()

        guard let context = llamaContext else {
            throw ScoringError.modelNotAvailable
        }

        // Format prompt in ChatML format for Qwen
        let prompt = formatPrompt(diaryText: diaryText)

        do {
            // Prepare context with prompt
            try await context.prepare(prompt: prompt)

            // Generate tokens (expecting a single digit 0-3)
            var fullResponse = ""
            while let token = try await context.nextToken() {
                fullResponse += token
                // Stop after getting reasonable response
                if fullResponse.count > 10 {
                    break
                }
            }

            // Extract score from response
            guard let score = extractScore(from: fullResponse) else {
                throw ScoringError.invalidScore(response: fullResponse)
            }

            return score
        } catch let error as ScoringError {
            throw error
        } catch {
            throw ScoringError.scoringFailed(underlying: error)
        }
    }

    // MARK: - Private Helpers

    /// Formats prompt in ChatML format for Qwen models
    private func formatPrompt(diaryText: String) -> String {
        """
        <|im_start|>system
        Du bist ein Assistent, der Lupus-Krankheitsaktivität bewertet.<|im_end|>
        <|im_start|>user
        Tagebuch: \(diaryText). Was ist der Krankheitsaktivitätswert für heute?<|im_end|>
        <|im_start|>assistant
        """
    }

    /// Extracts score (0-3) from model response
    private func extractScore(from text: String) -> Int? {
        // Find first digit 0-3 in response
        for char in text {
            if let digit = char.wholeNumberValue, digit >= 0 && digit <= 3 {
                return digit
            }
        }
        return nil
    }
}

// MARK: - Convenience Extension for JournalEntry

extension ScoringService {
    /// Scores a journal entry and updates its mlScore field
    /// - Parameters:
    ///   - entry: The journal entry to score
    ///   - context: Core Data context for saving
    /// - Returns: The computed score, or nil if scoring fails
    @discardableResult
    func scoreEntry(_ entry: JournalEntry, in context: NSManagedObjectContext) async -> Int? {
        guard let text = entry.journalText, !text.isEmpty else {
            return nil
        }

        do {
            let score = try await scoreDiaryEntry(text)

            // Update entry on main actor
            await MainActor.run {
                entry.mlScore = Int16(score)
                try? context.save()
            }

            return score
        } catch {
            print("Scoring failed: \(error.localizedDescription)")
            return nil
        }
    }
}

import CoreData
