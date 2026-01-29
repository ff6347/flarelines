# Fix Core Data Test Suite

## Problem

Core Data tests crash with "Multiple NSEntityDescriptions claim the NSManagedObject subclass 'JournalEntry'" error.

### Root Cause

When running unit tests, the Core Data model gets registered twice:

1. **First registration**: The test host app (Flarelines.app) initializes `PersistenceController.shared` on launch, which loads the managed object model
2. **Second registration**: Tests create their own `PersistenceController(inMemory: true)` instances, loading the model again

Core Data cannot disambiguate which `NSEntityDescription` to use for `JournalEntry`, causing crashes when tests try to create managed objects.

### Affected Tests

- `CoreDataTests.swift` - All tests disabled
- `SampleDataGeneratorTests.swift` - All tests disabled

## Solution Options

### Option A: Lazy App Initialization (Recommended)

Prevent the app from initializing Core Data when running as a test host.

**Implementation:**

1. Add a launch argument check in `flarelinesApp.swift`:

```swift
@main
struct FlarelinesApp: App {
    // Only initialize persistence when NOT running as test host
    private static let isRunningTests = ProcessInfo.processInfo.arguments.contains("-XCTestConfigurationFilePath") ||
                                        ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil

    @StateObject private var persistence = PersistenceController.shared

    init() {
        // Skip Core Data init during tests - tests manage their own stack
        if Self.isRunningTests {
            return
        }
    }

    var body: some Scene {
        WindowGroup {
            if Self.isRunningTests {
                EmptyView() // Minimal UI for test host
            } else {
                ContentView()
                    .environment(\.managedObjectContext, persistence.container.viewContext)
            }
        }
    }
}
```

2. Update `PersistenceController` to support test mode:

```swift
struct PersistenceController {
    static let shared = PersistenceController()

    // Dedicated test controller - use this in ALL tests
    static let test: PersistenceController = {
        PersistenceController(inMemory: true)
    }()

    // ... rest unchanged
}
```

3. Update test helpers to use `PersistenceController.test`:

```swift
enum TestCoreData {
    static func makeInMemoryContext() -> NSManagedObjectContext {
        PersistenceController.test.container.viewContext
    }
}
```

**Pros:**
- Clean separation between app and test Core Data stacks
- Tests run in true isolation
- No changes to Core Data model configuration

**Cons:**
- Requires changes to app entry point
- Need to ensure all code paths handle test mode

### Option B: Shared Model Instance

Use a single `NSManagedObjectModel` instance across app and tests.

**Implementation:**

1. Create a model singleton in `Persistence.swift`:

```swift
struct PersistenceController {
    // Single model instance shared by all containers
    private static let model: NSManagedObjectModel = {
        guard let modelURL = Bundle.main.url(forResource: "flarelines", withExtension: "momd"),
              let model = NSManagedObjectModel(contentsOf: modelURL) else {
            fatalError("Failed to load Core Data model")
        }
        return model
    }()

    init(inMemory: Bool = false) {
        // Use shared model instead of loading from name
        container = NSPersistentContainer(name: "flarelines", managedObjectModel: Self.model)
        // ... rest unchanged
    }
}
```

**Pros:**
- Minimal code changes
- Works with existing test structure

**Cons:**
- May not fully solve the issue if app initializes before tests can access shared model
- Tighter coupling between app and test code

### Option C: Separate Test Target Without Host App

Create a new test target that doesn't use the app as test host.

**Implementation:**

1. In Xcode, create new Unit Test target "FlarelinesUnitTests"
2. Set "Host Application" to "None" in target settings
3. Move non-UI tests to this target
4. Keep `FlarelinesTests` for integration tests that need the app

**Pros:**
- Complete isolation - no app code runs during unit tests
- Faster test execution
- Industry standard practice

**Cons:**
- More complex project structure
- Need to ensure test target has access to all needed source files
- May require `@testable import` adjustments

## Recommended Approach

**Use Option A (Lazy App Initialization)** because:

1. Minimal project restructuring
2. Clear intent - app knows when it's being tested
3. Tests continue using existing patterns
4. Can be implemented incrementally

## Implementation Steps

1. [ ] Add test detection to `flarelinesApp.swift`
2. [ ] Create `PersistenceController.test` singleton
3. [ ] Update `TestCoreData.makeInMemoryContext()` to use test singleton
4. [ ] Verify app still works normally when launched
5. [ ] Re-enable `CoreDataTests.swift`
6. [ ] Re-enable `SampleDataGeneratorTests.swift`
7. [ ] Run full test suite locally
8. [ ] Verify CI passes

## Testing the Fix

After implementation, verify:

```bash
# All tests should pass
xcodebuild test \
  -project flarelines.xcodeproj \
  -scheme Flarelines \
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.1' \
  -parallel-testing-enabled NO

# App should launch normally
# (manual verification in Simulator)
```

## References

- [Apple: Setting Up a Core Data Stack](https://developer.apple.com/documentation/coredata/setting_up_a_core_data_stack)
- [Core Data and Unit Testing](https://www.donnywals.com/setting-up-a-core-data-store-for-unit-tests/)
- [NSManagedObjectModel documentation](https://developer.apple.com/documentation/coredata/nsmanagedobjectmodel)
