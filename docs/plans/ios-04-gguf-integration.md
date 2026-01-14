# Plan: iOS GGUF Model Integration

## Summary

Integrate the fine-tuned Qwen2.5-3B GGUF model for on-device lupus diary scoring using llama.cpp.

## Key Decisions

- **Model**: qwen2.5-3b-diary-q4_k_m.gguf (~1.8GB)
- **Delivery**: Download from Cloudflare on first launch
- **Scoring**: Automatic on save, stored alongside user's reference score

## Changes

### 1. Add llama.xcframework
- Copy from `/Users/tomato/Documents/apps/WolfsbitGGUFTest/WolfsbitGGUFTest/llama.xcframework`
- To `wolfsbit/Frameworks/llama.xcframework`
- Add to Xcode: Embed & Sign
- Link: Metal.framework, Accelerate.framework

### 2. Add LlamaContext.swift
File: `wolfsbit/utilities/UtilitiesLlamaContext.swift`

Copy from prototype, update ABOUTME header:
```swift
// ABOUTME: Swift actor wrapping llama.cpp C API for GGUF model inference.
// ABOUTME: Handles model loading, tokenization, and text generation.
```

Already handles:
- Actor-based thread safety
- Metal GPU on device, disabled on simulator
- ChatML prompt format for Qwen
- Score extraction (first digit 0-3)

### 3. Create ModelDownloader Service
File: `wolfsbit/services/ServicesModelDownloader.swift`

```swift
// ABOUTME: Downloads GGUF model from Cloudflare with progress reporting.
// ABOUTME: Stores model in app's Documents directory.

actor ModelDownloader: ObservableObject {
    enum State {
        case idle
        case downloading(progress: Double)
        case completed
        case failed(Error)
    }

    @Published var state: State = .idle

    var modelURL: URL {
        // Documents/qwen2.5-3b-diary-q4_k_m.gguf
    }

    var isModelAvailable: Bool {
        FileManager.default.fileExists(atPath: modelURL.path)
    }

    func downloadModel() async throws {
        // URLSession with progress delegate
        // Placeholder URL until Cloudflare is set up
    }

    func deleteModel() throws {
        try FileManager.default.removeItem(at: modelURL)
    }

    func cancelDownload() { }
}
```

### 4. Create ModelManager Service
File: `wolfsbit/services/ServicesModelManager.swift`

```swift
// ABOUTME: Singleton managing LlamaContext lifecycle and scoring.
// ABOUTME: Loads model from Documents, provides scoring API.

actor ModelManager {
    static let shared = ModelManager()

    private var llamaContext: LlamaContext?

    var isLoaded: Bool { llamaContext != nil }

    func loadModel() async throws {
        let url = ModelDownloader().modelURL
        llamaContext = try await LlamaContext.load(from: url)
    }

    func score(journalText: String) async throws -> Int {
        guard let context = llamaContext else {
            throw ModelError.notLoaded
        }
        // Format prompt, run inference, extract score
        return score
    }

    func unload() {
        llamaContext = nil
    }
}
```

### 5. Update OnboardingView (Page 4)
File: `wolfsbit/views/ViewsOnboardingView.swift`

Current: TODO placeholder, shows "~50-100 MB"

New:
- Update text to "~1.8 GB"
- Implement download with progress bar
- States: idle → downloading → completed → failed
- "Download Later" option still works

```swift
@StateObject private var downloader = ModelDownloader()

var mlModelPage: some View {
    VStack {
        // ...
        switch downloader.state {
        case .idle:
            Button("Download Now") { Task { try await downloader.downloadModel() } }
        case .downloading(let progress):
            ProgressView(value: progress)
            Text("\(Int(progress * 100))%")
        case .completed:
            Label("Downloaded", systemImage: "checkmark.circle.fill")
        case .failed(let error):
            Text("Failed: \(error.localizedDescription)")
            Button("Retry") { Task { try await downloader.downloadModel() } }
        }
    }
}
```

### 6. Update SettingsView
File: `wolfsbit/views/ViewsSettingsView.swift`

Add ML Model section:
- Status: Downloaded (1.8 GB) / Not Downloaded
- Delete Model button
- Download Model button

### 7. Integrate Scoring in JournalEditorView

On save:
1. Save entry with `journalText` + `userScore`
2. Set `mlScore = -1`
3. If model loaded, run inference async
4. Update `mlScore` when complete

```swift
func saveEntry() {
    // Save to CoreData
    let entry = JournalEntry(context: context)
    entry.journalText = journalText
    entry.userScore = Int16(userScore)
    entry.mlScore = -1
    try? context.save()

    // Score async if model available
    if ModelManager.shared.isLoaded {
        Task {
            if let score = try? await ModelManager.shared.score(journalText: journalText) {
                entry.mlScore = Int16(score)
                try? context.save()
            }
        }
    }
}
```

## Files

**Add:**
- `wolfsbit/Frameworks/llama.xcframework/`
- `wolfsbit/utilities/UtilitiesLlamaContext.swift`
- `wolfsbit/services/ServicesModelDownloader.swift`
- `wolfsbit/services/ServicesModelManager.swift`

**Modify:**
- `wolfsbit/views/ViewsOnboardingView.swift`
- `wolfsbit/views/ViewsSettingsView.swift`
- `wolfsbit/views/ViewsLogView.swift` (scoring on save)

## Open Items

- [ ] Cloudflare URL for model download (use placeholder for now)
- [ ] Model checksum verification (optional)

## Dependencies

- Requires CoreData migration (needs `mlScore` field)
- Requires UI redesign (JournalEditorView with save flow)
