// ABOUTME: Swift wrapper around llama.cpp C API for GGUF model inference
// ABOUTME: Uses actor for thread-safe inference on iOS

import Foundation
import llama

/// Thread-safe wrapper for llama.cpp inference
actor LlamaContext {
    private var model: OpaquePointer?
    private var context: OpaquePointer?
    private var sampler: UnsafeMutablePointer<llama_sampler>?
    private var batch: llama_batch
    private var tokens: [llama_token] = []
    private var generatedText: String = ""

    private init(model: OpaquePointer, context: OpaquePointer) {
        self.model = model
        self.context = context
        self.batch = llama_batch_init(512, 0, 1)
        self.sampler = nil
    }

    deinit {
        llama_batch_free(batch)
        if let sampler = sampler {
            llama_sampler_free(sampler)
        }
        if let context = context {
            llama_free(context)
        }
        if let model = model {
            llama_model_free(model)
        }
    }

    /// Load a GGUF model from a file path
    static func load(from path: String) throws -> LlamaContext {
        // Initialize backend (call once per app)
        llama_backend_init()

        // Model parameters
        var modelParams = llama_model_default_params()

        // Disable GPU on simulator (no Metal support)
        #if targetEnvironment(simulator)
        modelParams.n_gpu_layers = 0
        #endif

        // Load model
        guard let model = llama_model_load_from_file(path, modelParams) else {
            throw LlamaError.modelLoadFailed
        }

        // Context parameters
        var ctxParams = llama_context_default_params()
        ctxParams.n_ctx = 2048  // Context window size
        ctxParams.n_batch = 512

        // Use reasonable thread count
        let threadCount = max(1, min(8, ProcessInfo.processInfo.processorCount - 2))
        ctxParams.n_threads = Int32(threadCount)
        ctxParams.n_threads_batch = Int32(threadCount)

        // Create context
        guard let context = llama_init_from_model(model, ctxParams) else {
            llama_model_free(model)
            throw LlamaError.contextCreationFailed
        }

        return LlamaContext(model: model, context: context)
    }

    // MARK: - Batch Helper Methods
    // These replace the C macros llama_batch_clear and llama_batch_add which don't bridge to Swift

    /// Clear the batch (replacement for llama_batch_clear macro)
    private func batchClear() {
        batch.n_tokens = 0
    }

    /// Add a token to the batch (replacement for llama_batch_add macro)
    private func batchAdd(token: llama_token, pos: llama_pos, seqIds: [llama_seq_id], logits: Bool) {
        let i = Int(batch.n_tokens)

        batch.token[i] = token
        batch.pos[i] = pos
        batch.n_seq_id[i] = Int32(seqIds.count)

        for (j, seqId) in seqIds.enumerated() {
            batch.seq_id[i]![j] = seqId
        }

        batch.logits[i] = logits ? 1 : 0
        batch.n_tokens += 1
    }

    /// Prepare for generation with the given prompt
    func prepare(prompt: String) throws {
        guard let model = model, let context = context else {
            throw LlamaError.notInitialized
        }

        let vocab = llama_model_get_vocab(model)

        // Tokenize the prompt
        let promptCString = prompt.cString(using: .utf8)!
        let maxTokens = prompt.utf8.count + 32
        tokens = [llama_token](repeating: 0, count: maxTokens)

        let nTokens = llama_tokenize(
            vocab,
            promptCString,
            Int32(promptCString.count - 1), // Exclude null terminator
            &tokens,
            Int32(maxTokens),
            true,  // Add BOS token
            false  // Don't add special tokens at end
        )

        guard nTokens > 0 else {
            throw LlamaError.tokenizationFailed
        }

        tokens = Array(tokens.prefix(Int(nTokens)))

        // Clear any previous state
        if let memory = llama_get_memory(context) {
            llama_memory_clear(memory, false)
        }

        // Add tokens to batch
        batchClear()
        for (i, token) in tokens.enumerated() {
            let isLast = (i == tokens.count - 1)
            batchAdd(token: token, pos: Int32(i), seqIds: [0], logits: isLast)
        }

        // Process the prompt
        let decodeResult = llama_decode(context, batch)
        guard decodeResult == 0 else {
            throw LlamaError.decodeFailed
        }

        // Setup sampler for generation
        if let existingSampler = sampler {
            llama_sampler_free(existingSampler)
        }
        sampler = llama_sampler_chain_init(llama_sampler_chain_default_params())
        llama_sampler_chain_add(sampler, llama_sampler_init_temp(0.7))
        llama_sampler_chain_add(sampler, llama_sampler_init_dist(UInt32.random(in: 0...UInt32.max)))

        generatedText = ""
    }

    /// Generate the next token. Returns nil when generation should stop.
    func nextToken() throws -> String? {
        guard let model = model, let context = context, let sampler = sampler else {
            throw LlamaError.notInitialized
        }

        let vocab = llama_model_get_vocab(model)

        // Sample next token
        let newToken = llama_sampler_sample(sampler, context, batch.n_tokens - 1)

        // Check for end of generation
        if llama_vocab_is_eog(vocab, newToken) {
            return nil
        }

        // Convert token to text
        var buffer = [CChar](repeating: 0, count: 64)
        let length = llama_token_to_piece(vocab, newToken, &buffer, Int32(buffer.count), 0, false)

        guard length > 0 else {
            return nil
        }

        let piece = String(cString: buffer)
        generatedText += piece

        // Prepare for next token
        batchClear()
        batchAdd(token: newToken, pos: Int32(tokens.count), seqIds: [0], logits: true)
        tokens.append(newToken)

        let decodeResult = llama_decode(context, batch)
        guard decodeResult == 0 else {
            throw LlamaError.decodeFailed
        }

        return piece
    }

    /// Get all generated text so far
    func getGeneratedText() -> String {
        return generatedText
    }
}

enum LlamaError: Error, LocalizedError {
    case modelLoadFailed
    case contextCreationFailed
    case notInitialized
    case tokenizationFailed
    case decodeFailed

    var errorDescription: String? {
        switch self {
        case .modelLoadFailed: return "Failed to load GGUF model"
        case .contextCreationFailed: return "Failed to create inference context"
        case .notInitialized: return "Model not initialized"
        case .tokenizationFailed: return "Failed to tokenize input"
        case .decodeFailed: return "Inference decode failed"
        }
    }
}
