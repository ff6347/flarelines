# Plan: In-App Model Download Infrastructure

## Summary

Enable the iOS app to download the GGUF model on-demand from Cloudflare R2, rather than bundling it in the app. The scoring feature remains optional - app works without the model but scoring is disabled.

## Hosting: Cloudflare R2 (Recommended)

**Why R2:**
- Zero egress fees (critical for 1.5-2GB model files)
- S3-compatible API
- Free tier covers <100 downloads/month easily
- Supports signed URLs for future auth-gating

**Cost at your scale:** $0/month (free tier)

**Alternative:** HuggingFace Hub if you want simplicity and community discovery (but no signed URLs for auth).

## Architecture

```
Cloudflare R2 Bucket
├── models.json              # Manifest with available models
└── models/
    └── lupus-diary-v1.0.0-q4_k_m.gguf

iOS App
├── ModelStorage.swift       # File system operations, checksum validation
├── ModelManifest.swift      # Manifest fetching and parsing
├── ModelDownloader.swift    # URLSession background downloads
├── DownloadProgressView.swift # Download UI
└── ContentView.swift        # Modified to support both bundled & downloaded
```

## Model Versioning

**Filename format:** `{name}-v{major}.{minor}.{patch}-{quantization}.gguf`

**Manifest (models.json):**
```json
{
  "schemaVersion": 1,
  "models": [{
    "id": "lupus-diary-v1.0.0-q4_k_m",
    "version": "1.0.0",
    "filename": "lupus-diary-v1.0.0-q4_k_m.gguf",
    "sizeBytes": 1800000000,
    "sha256": "abc123...",
    "minAppVersion": "1.0.0",
    "downloadUrl": "https://your-bucket.r2.dev/models/lupus-diary-v1.0.0-q4_k_m.gguf"
  }],
  "currentVersion": "1.0.0"
}
```

## iOS Implementation

### New Files

| File | Purpose |
|------|---------|
| `ModelStorage.swift` | App Support directory management, SHA256 validation |
| `ModelManifest.swift` | Fetch/parse remote manifest, cache for 1 hour |
| `ModelDownloader.swift` | Background URLSession, progress tracking, resume support |
| `DownloadProgressView.swift` | SwiftUI sheet for download UI |

### Key Features

1. **Background downloads** - User can close app, download continues
2. **Resume capability** - Network interruption doesn't restart from zero
3. **Checksum validation** - SHA256 verification after download
4. **Progress UI** - Bytes downloaded, percentage, cancel button
5. **Graceful degradation** - App works without model, scoring disabled

### Changes to Existing Files

**ContentView.swift:**
- Add `ModelSource` enum (none/bundled/downloaded)
- Modify `loadModel()` to try bundled first, then downloaded
- Show "Download Model" button when no model available
- Disable scoring button when model unavailable

**LupusDiaryApp.swift:**
- Add `UIApplicationDelegateAdaptor` for background session events

**LlamaContext.swift:**
- No changes needed (already accepts file path)

## Auth Pattern (Future)

When ready to add authentication:

1. Create Cloudflare Worker that validates API key and returns signed URLs
2. Add `AuthenticatedDownloader` to iOS that:
   - Sends API key header to worker
   - Receives time-limited signed URL
   - Downloads from signed URL

## Implementation Steps

### Phase 1: iOS Download Infrastructure
1. Create `ModelStorage.swift` - file operations, checksum
2. Create `ModelManifest.swift` - manifest types and fetcher
3. Create `ModelDownloader.swift` - background URLSession
4. Create `DownloadProgressView.swift` - download UI

### Phase 2: Integration
1. Modify `ContentView.swift` for model source switching
2. Add background session handling to `LupusDiaryApp.swift`
3. Test with bundled model removed

### Phase 3: Backend [COMPLETE]
1. ~~Create Cloudflare R2 bucket~~ - `wolfsbit-models`
2. ~~Upload model and manifest~~ - via `scripts/upload-model.sh`
3. ~~Configure public access~~ - Public Development URL enabled
4. ~~Test end-to-end~~ - Verified public URLs work

**Implemented:**
- Upload script: `scripts/upload-model.sh`
- Mise task: `mise run upload-model --model <path> [--version <ver>]`
- Uses rclone with S3-compatible API
- Auto-generates manifest with SHA256 checksum

## Critical Files

- `ios-app/ContentView.swift` - needs model source logic
- `ios-app/LlamaContext.swift` - reference for actor pattern
- `ios-app/LupusDiaryApp.swift` - needs background session delegate
- `ios-app/README.md` - update with download instructions

## Considerations

- **Cellular warning**: Prompt user before 2GB download on cellular
- **Storage check**: Verify ~3GB available before download
- **Checksum time**: SHA256 of 2GB takes ~10-15s, show spinner
- **Version migration**: UI for updating model when new version available
