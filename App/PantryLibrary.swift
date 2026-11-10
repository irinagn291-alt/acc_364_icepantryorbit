import SwiftUI
import WidgetKit

final class PantryLibrary: NSObject, ObservableObject {
    @Published private(set) var state: PantryState
    private let storage: UserDefaults
    private static let key = "pantry-library.v1"

    override init() {
        #if DEBUG && targetEnvironment(simulator)
        if ScreenshotLaunch.active {
            storage = UserDefaults(suiteName: "pantry-screenshots.demo.v1")!
        } else if let suite = ProcessInfo.processInfo.environment["PANTRY_UI_TEST_SUITE"], suite.hasPrefix("pantry-tests.") {
            storage = UserDefaults(suiteName: suite) ?? .standard
        } else {
            storage = .standard
        }
        #elseif DEBUG
        if let suite = ProcessInfo.processInfo.environment["PANTRY_UI_TEST_SUITE"], suite.hasPrefix("pantry-tests.") {
            storage = UserDefaults(suiteName: suite) ?? .standard
        } else {
            storage = .standard
        }
        #else
        storage = .standard
        #endif
        #if DEBUG && targetEnvironment(simulator)
        if ScreenshotLaunch.active {
            let seeded = ScreenshotLaunch.seed()
            state = seeded
            if let data = try? JSONEncoder().encode(seeded) { storage.set(data, forKey: Self.key) }
        } else if let data = storage.data(forKey: Self.key), let saved = try? JSONDecoder().decode(PantryState.self, from: data) { state = saved }
        else { state = PantryState() }
        #else
        if let data = storage.data(forKey: Self.key), let saved = try? JSONDecoder().decode(PantryState.self, from: data) { state = saved }
        else { state = PantryState() }
        #endif
        super.init()
        #if DEBUG && targetEnvironment(simulator)
        if ScreenshotLaunch.active { return }
        #endif
        distribute()
    }

    func change(_ mutation: (inout PantryState) -> Void) {
        var next = state
        mutation(&next)
        guard let data = try? JSONEncoder().encode(next) else { return }
        storage.set(data, forKey: Self.key)
        state = next
        distribute()
    }

    private func distribute() {
        #if DEBUG && targetEnvironment(simulator)
        if ScreenshotLaunch.active { return }
        #endif
        guard let payload = try? JSONEncoder().encode(PocketSnapshot(state)) else { return }
        UserDefaults(suiteName: PocketSnapshot.group)?.set(payload, forKey: PocketSnapshot.key)
        WidgetCenter.shared.reloadTimelines(ofKind: "PantryOrbitQueue")
    }
}
