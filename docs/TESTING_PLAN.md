# Flarelines Testing Plan

This document outlines the testing strategy for Flarelines, a chronic illness journaling iOS app.

## Current State

### Existing Test Infrastructure
- **Unit Tests**: `flarelinesTests/` using Swift Testing framework
- **UI Tests**: `flarelinesUITests/` using XCTest
- **Test Coverage**: ~120+ unit tests across 11 test files (~1,900 lines of test code)

### Implemented Tests
| File | Tests | Coverage |
|------|-------|----------|
| `CSVExporterTests.swift` | 15 | CSV export, escaping, sorting, edge cases |
| `LanguagePreferenceTests.swift` | 11 | AppLanguage enum, locale detection |
| `ScoringServiceTests.swift` | 17 | Score extraction, prompt formatting, errors |
| `ModelManifestTests.swift` | 12 | Version comparison (parameterized), JSON decoding |
| `ModelStorageTests.swift` | 10 | Space calculation, error types |
| `wolfsbitTests.swift` | 9 | Flare score validation, date utilities |
| `DesignTokensTests.swift` | 18 | Spacing, dimensions, corner radius, colors |
| `CoreDataTests.swift` | 12 | CRUD operations, predicates, date filtering |
| `ReminderSchedulerTests.swift` | 12 | Date component extraction, trigger creation |
| `SampleDataGeneratorTests.swift` | 12 | Data generation, clearing, score distribution |
| `TestHelpers.swift` | - | Shared test utilities, factories, mocks |

## Testing Framework Choice: Swift Testing

We use Apple's **Swift Testing** framework (introduced WWDC 2024) for unit tests because:

1. **Modern Swift-native syntax** - `@Test` instead of `test` prefix, `#expect` instead of `XCTAssert`
2. **Better async/await support** - Native integration with Swift concurrency
3. **Parallel execution by default** - Faster test runs
4. **Parameterized tests** - Built-in support for testing multiple inputs
5. **Cleaner failure messages** - Expression macros provide detailed diagnostics

### When to Use XCTest
- UI tests (Swift Testing doesn't support UI testing yet)
- Performance tests
- Integration with Objective-C code

## Testing Layers

```
┌─────────────────────────────────────────────┐
│              UI Tests (XCTest)              │  ← User flows, accessibility
├─────────────────────────────────────────────┤
│         Integration Tests (Swift Testing)    │  ← Core Data, ML pipeline
├─────────────────────────────────────────────┤
│           Unit Tests (Swift Testing)         │  ← Pure functions, models
└─────────────────────────────────────────────┘
```

## Phase 1: Unit Tests ✅ COMPLETE

### Completed ✓
- [x] CSV export formatting and escaping (with edge cases)
- [x] Language preference enum and detection
- [x] Score extraction from ML responses
- [x] Prompt formatting for ML model
- [x] Semantic version comparison (parameterized with 18 test cases)
- [x] Model manifest JSON decoding
- [x] Storage space calculations
- [x] Error type descriptions
- [x] Flare score validation
- [x] Design tokens (spacing, dimensions, corner radius)
- [x] Core Data CRUD operations
- [x] Reminder scheduler date components
- [x] Sample data generator

### Parameterized Tests Implemented

Version comparison now uses parameterized tests:

```swift
@Test(arguments: [
    ("1.0.0", "1.0.0", 0),
    ("2.0.0", "1.0.0", 1),
    ("1.0.0", "2.0.0", -1),
    ("1.10.0", "1.9.0", 1),  // Tests numeric comparison, not string
    // ... 18 test cases total
])
func versionComparison(a: String, b: String, expected: Int) { ... }
```

Reminder time extraction also uses parameterized tests:

```swift
@Test(arguments: [
    (0, 0),    // Midnight
    (6, 30),   // Early morning
    (12, 0),   // Noon
    (18, 45),  // Evening
    (23, 59),  // End of day
])
func commonReminderTimes(hour: Int, minute: Int) { ... }
```

## Phase 2: Integration Tests ✅ PARTIALLY COMPLETE

### Core Data Tests ✅ IMPLEMENTED
Tests for persistence layer with in-memory stores are complete in `CoreDataTests.swift`:

- Create, update, delete journal entries
- Fetch with sort descriptors
- Fetch with predicates (by score)
- Fetch entries in date range
- Score validation (0-3 for user, -1 to 3 for ML)
- Nil journal text handling
- UUID uniqueness

### ML Pipeline Tests (Future)
Test the scoring service with mocked dependencies:

```swift
protocol ModelContextProtocol {
    func prepare(prompt: String) async throws
    func nextToken() async throws -> String?
}

// Mock for testing
class MockModelContext: ModelContextProtocol {
    var tokensToReturn: [String] = ["2"]

    func prepare(prompt: String) async throws {}
    func nextToken() async throws -> String? {
        tokensToReturn.isEmpty ? nil : tokensToReturn.removeFirst()
    }
}
```

### Network Tests (Future)
Test manifest fetching with URLProtocol mocking:

```swift
class MockURLProtocol: URLProtocol {
    static var mockData: Data?
    static var mockResponse: URLResponse?
    static var mockError: Error?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        if let error = Self.mockError {
            client?.urlProtocol(self, didFailWithError: error)
        } else {
            if let response = Self.mockResponse {
                client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            }
            if let data = Self.mockData {
                client?.urlProtocol(self, didLoad: data)
            }
        }
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}
```

## Phase 3: View Layer Tests

### View Model Tests
Extract testable logic from views:

```swift
// Current: Logic embedded in ViewsDataView.swift
// Target: Extract to testable view model

@Observable
class DataViewModel {
    var entries: [JournalEntry] = []
    var selectedRange: TimeRange = .thirtyDays

    var filteredEntries: [JournalEntry] {
        let cutoff = selectedRange.cutoffDate
        return entries.filter { $0.timestamp >= cutoff }
    }

    var averageScore: Double {
        guard !filteredEntries.isEmpty else { return 0 }
        let sum = filteredEntries.reduce(0) { $0 + Int($1.userScore) }
        return Double(sum) / Double(filteredEntries.count)
    }
}

// Then test:
@Test func filteredEntriesWithinRange() {
    let vm = DataViewModel()
    // ... add entries with various dates
    #expect(vm.filteredEntries.count == expectedCount)
}
```

### Snapshot Tests (Future)
Consider adding [swift-snapshot-testing](https://github.com/pointfreeco/swift-snapshot-testing) for UI regression tests:

```swift
import SnapshotTesting

@Test func logViewSnapshot() {
    let view = ViewsLogView()
    assertSnapshot(of: view, as: .image)
}
```

## Phase 4: UI Tests

### Critical User Flows
```swift
class JournalEntryUITests: XCTestCase {
    func testCreateNewEntry() {
        let app = XCUIApplication()
        app.launch()

        // Navigate to log view
        app.tabBars.buttons["Log"].tap()

        // Enter diary text
        app.textViews["journalTextEditor"].tap()
        app.textViews["journalTextEditor"].typeText("Feeling better today")

        // Navigate to rating
        app.buttons["Next"].tap()

        // Adjust slider and save
        app.sliders["flareSlider"].adjust(toNormalizedSliderPosition: 0.33)
        app.buttons["Save"].tap()

        // Verify entry appears
        app.tabBars.buttons["Data"].tap()
        XCTAssert(app.staticTexts["Feeling better today"].exists)
    }
}
```

### Accessibility Tests
```swift
func testAccessibilityLabels() {
    let app = XCUIApplication()
    app.launch()

    // Verify all interactive elements have accessibility labels
    XCTAssert(app.buttons["Log"].isAccessibilityElement)
    XCTAssert(app.buttons["Data"].isAccessibilityElement)
}
```

## Test Organization Best Practices

### File Naming
```
flarelinesTests/
├── Unit/
│   ├── CSVExporterTests.swift
│   ├── LanguagePreferenceTests.swift
│   ├── ModelManifestTests.swift
│   ├── ModelStorageTests.swift
│   ├── ScoringServiceTests.swift
│   └── FlareScoreTests.swift
├── Integration/
│   ├── CoreDataTests.swift
│   ├── MLPipelineTests.swift
│   └── NetworkTests.swift
└── Mocks/
    ├── MockModelContext.swift
    ├── MockURLProtocol.swift
    └── TestHelpers.swift
```

### Test Structure (AAA Pattern)
```swift
@Test func descriptiveTestName() {
    // Arrange - Set up test data
    let input = "test data"

    // Act - Execute the code under test
    let result = functionUnderTest(input)

    // Assert - Verify the result
    #expect(result == expectedValue)
}
```

### Avoiding Test Flakiness
1. **Don't depend on real time** - Use injected dates
2. **Don't depend on network** - Mock URLSession
3. **Don't depend on file system** - Use in-memory stores
4. **Don't depend on order** - Each test should be independent

## Test Doubles Strategy

### When to Use Each Type

| Type | Use Case | Example |
|------|----------|---------|
| **Stub** | Return canned data | `MockManifestFetcher` returns fixed JSON |
| **Mock** | Verify interactions | Assert `save()` was called |
| **Fake** | Working implementation | In-memory Core Data store |
| **Spy** | Record calls for verification | Track analytics events |

### Protocol-Based Testing
Make dependencies injectable:

```swift
// Before: Hard dependency
class ScoringService {
    func score(_ text: String) async throws -> Int {
        let context = try LlamaContext.load(from: path)  // ← Can't test
        // ...
    }
}

// After: Injectable dependency
protocol ModelLoading {
    func load(from path: String) throws -> ModelContextProtocol
}

class ScoringService {
    let modelLoader: ModelLoading

    init(modelLoader: ModelLoading = DefaultModelLoader()) {
        self.modelLoader = modelLoader
    }
}
```

## CI/CD Integration

### Recommended GitHub Actions Workflow
```yaml
name: Tests
on: [push, pull_request]

jobs:
  test:
    runs-on: macos-14
    steps:
      - uses: actions/checkout@v4

      - name: Select Xcode
        run: sudo xcode-select -s /Applications/Xcode_15.2.app

      - name: Run Tests
        run: |
          xcodebuild test \
            -scheme flarelines \
            -destination 'platform=iOS Simulator,name=iPhone 15' \
            -resultBundlePath TestResults.xcresult

      - name: Upload Results
        uses: actions/upload-artifact@v4
        with:
          name: test-results
          path: TestResults.xcresult
```

## Code Coverage Goals

| Module | Estimated | Target |
|--------|-----------|--------|
| Models | ~60% | 80% |
| Utilities | ~50% | 70% |
| Views | ~5% | 30% |
| Overall | ~35% | 50% |

Enable coverage in Xcode: Edit Scheme → Test → Options → Code Coverage

### Current Test Metrics
- **Test Files**: 11
- **Total Tests**: ~120+
- **Lines of Test Code**: ~1,900
- **Test Frameworks**: Swift Testing (unit), XCTest (UI)

## Resources

### Swift Testing
- [Swift Testing Documentation](https://developer.apple.com/documentation/testing)
- [WWDC24: Meet Swift Testing](https://developer.apple.com/videos/play/wwdc2024/10179/)
- [Migrating from XCTest](https://developer.apple.com/documentation/testing/migratingfromxctest)

### Testing Best Practices
- [Point-Free Testing](https://www.pointfree.co/collections/dependencies)
- [iOS Testing Manifesto](https://www.swiftbysundell.com/articles/writing-testable-code-when-using-swiftui/)

### Mocking & Dependencies
- [swift-dependencies](https://github.com/pointfreeco/swift-dependencies) - Dependency injection
- [swift-snapshot-testing](https://github.com/pointfreeco/swift-snapshot-testing) - Snapshot tests

---

*Last updated: January 2026*
