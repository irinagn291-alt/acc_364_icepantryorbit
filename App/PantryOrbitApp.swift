import SwiftUI

@main
struct PantryOrbitApp: App {
    @StateObject private var library = PantryLibrary()
    var body: some Scene {
        WindowGroup {
            PantryHome().environmentObject(library).preferredColorScheme(.light).tint(Paper.grove)
                .environment(\.locale, Locale(identifier: "en_US"))
        }
    }
}

#if DEBUG && targetEnvironment(simulator)
enum ScreenshotLaunch {
    // The factory indices follow the selected screen order; the older scanner
    // review route remains available by name for existing retakes.
    static let keys = ["shelves", "new-batch", "food-catalog", "manual-product", "batch-details", "market", "ledger"]
    static let key: String? = {
        let args = ProcessInfo.processInfo.arguments
        let env = ProcessInfo.processInfo.environment
        func argument(_ name: String) -> String? {
            guard let index = args.firstIndex(of: name), args.indices.contains(index + 1) else { return nil }
            return args[index + 1]
        }
        if let review = argument("-ReviewScreen"), keys.contains(review) || review == "barcode-scanner" { return review }
        let enabled = args.contains("-AppStoreScreenshots") ||
            (env["APPSTORE_SCREENSHOTS"].map { !["", "0", "false", "no"].contains($0.lowercased()) } ?? false)
        guard enabled else { return nil }
        let raw = argument("-AppStoreScreenshotScreen") ?? env["APPSTORE_SCREENSHOT_SCREEN"] ?? "0"
        guard let index = Int(raw), keys.indices.contains(index) else { return nil }
        return keys[index]
    }()
    static var active: Bool { key != nil }
    static let batchID = UUID(uuidString: "8E73144B-791E-4440-A822-48FD9D0C0001")!
    static func day(_ offset: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: offset, to: Calendar.current.startOfDay(for: Date()))!
    }
    static func seed() -> PantryState {
        var state = PantryState()
        func batch(_ name: String, _ amount: Int, _ place: PantryPlace, _ days: Int, id: UUID = UUID()) -> PantryBatch {
            PantryBatch(id: id, name: name, brand: "", barcode: nil, amount: amount, unit: .pieces, place: place, expiry: day(days))
        }
        if key == "batch-details" || key == "ledger" {
            state.save(batch("Cannellini beans", 3, .cupboard, 14, id: batchID))
            if key == "ledger" {
                let tomatoes = batch("Tomatoes", 2, .fridge, 3)
                state.save(tomatoes)
                state.move(batchID, amount: 1, kind: .used, restock: false)
                state.move(tomatoes.id, amount: 1, kind: .discarded, restock: false)
            }
        } else {
            state.save(batch("Quaker Oats", 2, .cupboard, 1))
            state.save(batch("Tomatoes", 2, .fridge, 3))
            state.save(batch("Penne Rigate", 1, .cupboard, 21))
        }
        if key == "market" {
            for name in ["Tomatoes", "Cannellini beans", "Milk", "Pasta"] { state.addToMarket(name) }
            if let index = state.market.firstIndex(where: { $0.name == "Pasta" }) { state.market[index].bought = true }
        }
        return state
    }
}
#endif

enum PantryRoute: Identifiable {
    case add, batch(UUID)
    var id: String {
        switch self { case .add: return "add"; case .batch(let id): return id.uuidString }
    }
}

struct PantryHome: View {
    @EnvironmentObject var library: PantryLibrary
    @State private var tab = 0
    @State private var route: PantryRoute?
    @State private var place: PantryPlace?
    @State private var urgentOnly = false
    @State private var search = ""
    #if DEBUG && targetEnvironment(simulator)
    init() {
        switch ScreenshotLaunch.key {
        case "market": _tab = State(initialValue: 1)
        case "ledger": _tab = State(initialValue: 2)
        case "new-batch", "food-catalog", "barcode-scanner", "manual-product": _route = State(initialValue: .add)
        case "batch-details": _route = State(initialValue: .batch(ScreenshotLaunch.batchID))
        default: break
        }
    }
    #endif
    @Environment(\.dynamicTypeSize) private var typeSize
    @ScaledMetric(relativeTo: .title) private var heroSize: CGFloat = 31
    var body: some View {
        TabView(selection: $tab) {
            shelf.tabItem { Label("Shelves", systemImage: "cabinet") }.tag(0)
            MarketPage().tabItem { Label("Market", systemImage: "basket") }.tag(1)
            JournalPage().tabItem { Label("Ledger", systemImage: "book.pages") }.tag(2)
        }.foregroundStyle(Paper.ink)
        .sheet(item: $route) { selected in
            switch selected {
            case .add: BatchForm(existing: nil)
            case .batch(let id): BatchDetail(id: id)
            }
        }
        .onOpenURL { url in
            guard url.scheme == "pantryorbit" else { return }
            tab = url.host == "market" ? 1 : 0
            if url.host == "batch", let id = UUID(uuidString: url.lastPathComponent), library.state.batches.contains(where: { $0.id == id }) { route = .batch(id) }
        }
        #if DEBUG && targetEnvironment(simulator)
        .transaction { if ScreenshotLaunch.active { $0.disablesAnimations = true; $0.animation = nil } }
        #endif
    }
    private var shelf: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 19) {
                LedgerHeader(title: "The pantry", index: "01")
                HStack(spacing: 0) {
                    heroText.frame(maxWidth: .infinity, alignment: .leading)
                    if !typeSize.isAccessibilitySize { PantryPrint().frame(width: 112, height: 134) }
                }.padding(.horizontal,18).padding(.vertical,12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Paper.grove, in: RoundedRectangle(cornerRadius: 16))
                Button { route = .add } label: { Label("Add a batch", systemImage: "plus") }.buttonStyle(JournalButton())
                SectionTitle(title: "On the shelves", detail: library.state.batches.count == 1 ? "1 batch" : "\(library.state.batches.count) batches")
                if library.state.batches.isEmpty {
                    PaperEmpty(symbol: "shippingbox", title: "Start your first shelf", detail: "Choose a product, enter the quantity, and record the date on the pack.")
                } else {
                    ScrollView(.horizontal) {
                        HStack(spacing: 7) {
                            placePill("All", selected: place == nil) { place = nil }
                            ForEach(PantryPlace.allCases) { p in placePill(p.rawValue, selected: place == p) { place = p } }
                        }
                    }.scrollIndicators(.hidden)
                    HStack {
                        Image(systemName: "magnifyingglass").foregroundStyle(Paper.moss)
                        TextField("Search your shelves", text: $search)
                        Button { urgentOnly.toggle() } label: { Image(systemName: urgentOnly ? "clock.badge.checkmark.fill" : "clock") }
                            .accessibilityLabel(urgentOnly ? "Show all dates" : "Only show batches due within three days").accessibilityAddTraits(urgentOnly ? .isSelected : [])
                    }.padding(11).background(Paper.sheet, in: RoundedRectangle(cornerRadius: 10))
                    if urgentOnly { Kicker("Overdue or due in three days").foregroundStyle(Paper.berry) }
                    let filtered = library.state.byDeadline.filter { (place == nil || $0.place == place) && (!urgentOnly || $0.days() <= 3) && (search.isEmpty || $0.name.localizedCaseInsensitiveContains(search)) }
                    if filtered.isEmpty { PaperEmpty(symbol: "line.3.horizontal.decrease", title: "No matching batches", detail: "Try another storage location or change your search.") }
                    ForEach(filtered) { batch in
                        Button { route = .batch(batch.id) } label: {
                            HStack(spacing: 12) {
                                Image(systemName: batch.place.symbol).font(.title3).frame(width: 43,height: 48)
                                    .background(Paper.sheet, in: RoundedRectangle(cornerRadius: 8))
                                VStack(alignment:.leading,spacing:4) {
                                    Text(batch.name).font(.headline).multilineTextAlignment(.leading)
                                    Text(batch.place.rawValue + " · " + batch.quantity).font(.caption).foregroundStyle(Paper.moss)
                                }
                                Spacer()
                                Text(batch.deadline()).font(.caption.weight(.semibold)).foregroundStyle(batch.days() <= 1 ? Paper.berry : Paper.moss)
                                Image(systemName:"chevron.right").font(.caption2)
                            }.contentShape(Rectangle())
                        }.buttonStyle(.plain).accessibilityIdentifier("batch.row." + batch.name)
                        Divider()
                    }
                }
            }.padding(20).frame(maxWidth: 760).frame(maxWidth: .infinity)
        }.background(Paper.page).toolbarBackground(Paper.page, for:.tabBar).toolbarBackground(.visible, for:.tabBar)
    }
    private var heroText: some View {
        VStack(alignment: .leading, spacing: 8) {
            Kicker("The pantry press").foregroundStyle(Paper.apricot)
            if let batch = library.state.byDeadline.first {
                Text(batch.name).font(.system(size: heroSize, weight: .medium, design: .serif)).lineLimit(2)
                Button { route = .batch(batch.id) } label: { Label(batch.deadline(),systemImage:"calendar").font(.subheadline.weight(.medium)).underline() }
            } else {
                Text("Shelf\nalmanac").font(.system(size: heroSize, weight: .medium, design: .serif)).lineSpacing(-2)
                Text("From market to meal").font(.caption)
            }
        }.foregroundStyle(Paper.page)
    }
    private func placePill(_ title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(title, action: action).font(.subheadline.weight(.medium)).buttonStyle(.plain).padding(.horizontal,12).padding(.vertical,8)
            .foregroundStyle(selected ? Paper.page : Paper.ink).background(selected ? Paper.grove : Paper.sheet, in: Capsule())
    }
}
