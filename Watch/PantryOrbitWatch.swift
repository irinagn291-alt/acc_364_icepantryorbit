import SwiftUI
import WatchConnectivity

final class PocketLibrary: NSObject, ObservableObject, WCSessionDelegate {
    @Published private(set) var snapshot = PocketSnapshot.load(.standard)
    @Published private(set) var hasSnapshot = UserDefaults.standard.data(forKey: PocketSnapshot.key) != nil
    @Published private(set) var pending: Set<String> = Set(UserDefaults.standard.stringArray(forKey:"pocket-pending") ?? [])
    @Published private(set) var active = false
    override init() {
        super.init()
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }
    func buy(_ item: MarketItem) {
        guard active, !pending.contains(item.id.uuidString) else { return }
        pending.insert(item.id.uuidString)
        UserDefaults.standard.set(Array(pending),forKey:"pocket-pending")
        let session = WCSession.default
        let purchase = ["purchased": item.id.uuidString, "requestID": UUID().uuidString]
        if session.isReachable {
            session.sendMessage(purchase) { reply in
                self.accept(reply)
            } errorHandler: { _ in
                session.transferUserInfo(purchase)
            }
        } else {
            session.transferUserInfo(purchase)
        }
    }
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async { self.active = activationState == .activated }
        accept(session.receivedApplicationContext)
        requestSnapshot(from: session)
    }
    func sessionReachabilityDidChange(_ session: WCSession) { requestSnapshot(from: session) }
    func requestSnapshot(from session: WCSession = .default) {
        guard session.activationState == .activated, session.isReachable else { return }
        session.sendMessage(["snapshot": true], replyHandler: { self.accept($0) }, errorHandler: { _ in })
    }
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) { accept(applicationContext) }
    private func accept(_ context: [String: Any]) {
        guard let data = context[PocketSnapshot.key] as? Data, let next = try? JSONDecoder().decode(PocketSnapshot.self,from:data) else { return }
        DispatchQueue.main.async {
            if self.hasSnapshot, let latest = self.snapshot.generatedAt,
               let incoming = next.generatedAt, incoming < latest { return }
            UserDefaults.standard.set(data,forKey:PocketSnapshot.key)
            self.snapshot = next
            self.hasSnapshot = true
            self.pending.formIntersection(Set(next.market.map { $0.id.uuidString }))
            UserDefaults.standard.set(Array(self.pending),forKey:"pocket-pending")
        }
    }
}

@main
struct PantryOrbitWatchApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var pocket = PocketLibrary()
    var body: some Scene {
        WindowGroup {
            TabView {
                NavigationStack {
                    List {
                        Section("Use first") {
                            if pocket.snapshot.upcoming.isEmpty {
                                Text(pocket.hasSnapshot ? "Your shelves are empty. Add a batch on iPhone." : "Open IcePantryOrbit on your iPhone to sync.").font(.footnote)
                                Button("Refresh from iPhone") { pocket.requestSnapshot() }
                            }
                            ForEach(pocket.snapshot.upcoming) { batch in
                                VStack(alignment:.leading,spacing:4) {
                                    Text(batch.name).bold()
                                    Text(batch.deadline()).foregroundStyle(.orange)
                                    Text(batch.place.rawValue + " · " + batch.quantity).font(.caption2)
                                }
                            }
                        }
                    }.navigationTitle("IcePantryOrbit")
                }
                NavigationStack {
                    List {
                        Section("Check off purchases") {
                            let open = pocket.snapshot.market.filter { !pocket.pending.contains($0.id.uuidString) }
                            if open.isEmpty { Text("Your shopping list is empty.").font(.footnote) }
                            ForEach(open) { item in
                                Button { pocket.buy(item) } label: { Label(item.name,systemImage:"circle") }.disabled(!pocket.active)
                            }
                            if !pocket.pending.isEmpty { Text("Awaiting sync · \(pocket.pending.count)").font(.caption2).foregroundStyle(.orange) }
                        }
                    }.navigationTitle("Market")
                }
            }.tabViewStyle(.verticalPage).environment(\.locale, Locale(identifier:"en_US"))
            .task(id: scenePhase) {
                guard scenePhase == .active else { return }
                pocket.requestSnapshot()
                do { try await Task.sleep(for: .seconds(3)) } catch { return }
                pocket.requestSnapshot()
            }
        }
    }
}
