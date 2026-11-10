import SwiftUI
import WatchConnectivity
import WidgetKit

final class PantryLibrary: NSObject, ObservableObject, WCSessionDelegate {
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
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
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
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        guard session.activationState == .activated, session.isPaired, session.isWatchAppInstalled else { return }
        try? session.updateApplicationContext([PocketSnapshot.key: payload])
    }

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async { self.distribute() }
    }
    func sessionWatchStateDidChange(_ session: WCSession) { DispatchQueue.main.async { self.distribute() } }
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) { session.activate() }
    private func receivePurchase(_ message: [String: Any]) {
        guard let raw = message["purchased"] as? String, let id = UUID(uuidString: raw),
              let index = state.market.firstIndex(where: { $0.id == id }) else { return }
        let requestID = (message["requestID"] as? String).flatMap(UUID.init(uuidString:)) ?? id
        let applied = state.market[index].watchPurchaseIDs ?? []
        guard !applied.contains(requestID) else { return }
        change { state in
            state.market[index].bought = true
            state.market[index].watchPurchaseIDs = Array((applied + [requestID]).suffix(32))
        }
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
        DispatchQueue.main.async {
            self.receivePurchase(message)
            guard let data = try? JSONEncoder().encode(PocketSnapshot(self.state)) else { replyHandler([:]); return }
            replyHandler([PocketSnapshot.key: data])
        }
    }
    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any]) {
        DispatchQueue.main.async { self.receivePurchase(userInfo) }
    }
}
