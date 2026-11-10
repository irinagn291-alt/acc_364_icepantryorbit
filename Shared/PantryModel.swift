import Foundation

enum PantryPlace: String, Codable, CaseIterable, Identifiable {
    case cupboard = "Cupboard", fridge = "Fridge", freezer = "Freezer"
    var id: Self { self }
    var symbol: String {
        switch self { case .cupboard: return "cabinet"; case .fridge: return "refrigerator"; case .freezer: return "snowflake" }
    }
}

enum PantryUnit: String, Codable, CaseIterable, Identifiable {
    case pieces = "pcs", grams = "g", milliliters = "ml"
    var id: Self { self }
}

struct PantryBatch: Codable, Identifiable, Hashable {
    var id = UUID()
    var name: String
    var brand: String
    var barcode: String?
    var amount: Int
    var unit: PantryUnit
    var place: PantryPlace
    var expiry: Date
    var quantity: String { "\(amount) \(unit.rawValue)" }
    func days(on now: Date = Date()) -> Int {
        let calendar = Calendar.current
        return calendar.dateComponents([.day], from: calendar.startOfDay(for: now), to: calendar.startOfDay(for: expiry)).day ?? 0
    }
    func deadline(on now: Date = Date()) -> String {
        let d = days(on: now)
        switch d {
        case ..<0: return "\(-d)d overdue"
        case 0: return "Today"
        case 1: return "Tomorrow"
        default: return "In \(d) days"
        }
    }
}

struct MarketItem: Codable, Identifiable, Hashable {
    var id = UUID()
    var name: String
    var bought = false
    var watchPurchaseIDs: [UUID]?
}

struct PantryMovement: Codable, Identifiable {
    enum Kind: String, Codable { case used = "Used", discarded = "Discarded" }
    var id = UUID()
    var date = Date()
    var name: String
    var amount: Int
    var unit: PantryUnit
    var kind: Kind
}

struct PantryState: Codable {
    var batches: [PantryBatch] = []
    var market: [MarketItem] = []
    var journal: [PantryMovement] = []
    var byDeadline: [PantryBatch] {
        batches.sorted {
            if $0.expiry != $1.expiry { return $0.expiry < $1.expiry }
            return $0.name.localizedStandardCompare($1.name) == .orderedAscending
        }
    }
    mutating func save(_ batch: PantryBatch) {
        if let i = batches.firstIndex(where: { $0.id == batch.id }) { batches[i] = batch }
        else { batches.append(batch) }
    }
    mutating func addToMarket(_ value: String) {
        let name = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty, !market.contains(where: { !$0.bought && $0.name.caseInsensitiveCompare(name) == .orderedSame }) else { return }
        market.insert(MarketItem(name: name), at: 0)
    }
    mutating func move(_ id: UUID, amount: Int, kind: PantryMovement.Kind, restock: Bool) {
        guard let i = batches.firstIndex(where: { $0.id == id }), (1...batches[i].amount).contains(amount) else { return }
        let batch = batches[i]
        journal.insert(.init(name: batch.name, amount: amount, unit: batch.unit, kind: kind), at: 0)
        batches[i].amount -= amount
        if batches[i].amount == 0 { batches.remove(at: i) }
        if restock { addToMarket(batch.name) }
    }
}

struct PocketSnapshot: Codable {
    var generatedAt: Date?
    var upcoming: [PantryBatch]
    var market: [MarketItem]
    init(_ state: PantryState = .init()) {
        generatedAt = Date()
        upcoming = Array(state.byDeadline.prefix(5))
        market = state.market.filter { !$0.bought }
    }
    static let group = "group.app.pantryorbit.store"
    static let key = "pantry-pocket.v1"
    static func load(_ defaults: UserDefaults) -> Self {
        guard let data = defaults.data(forKey: key), let result = try? JSONDecoder().decode(Self.self, from: data) else { return Self() }
        return result
    }
}
