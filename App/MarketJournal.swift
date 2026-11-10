import SwiftUI

struct MarketPage: View {
    @EnvironmentObject var library: PantryLibrary
    @State private var input = ""
    @FocusState private var focused: Bool
    @State private var pick = false
    private var canAdd: Bool {
        let name = input.trimmingCharacters(in: .whitespacesAndNewlines)
        return !name.isEmpty && !library.state.market.contains { !$0.bought && $0.name.caseInsensitiveCompare(name) == .orderedSame }
    }
    private func add() {
        guard canAdd else { return }
        library.change { $0.addToMarket(input) }
        input = ""; focused = false
    }
    var body: some View {
        ScrollView {
            VStack(alignment:.leading,spacing:20) {
                LedgerHeader(title:"Market list",index:"02")
                Text("Plan your trip here. Check items off in the aisle using your phone.").font(.system(.body,design:.serif)).foregroundStyle(Paper.moss)
                HStack {
                    TextField("What do you need?",text:$input).focused($focused).onSubmit(add)
                    Button { add() } label: { Image(systemName:"plus.circle.fill").font(.title) }.disabled(!canAdd).accessibilityLabel("Add to shopping list")
                }.padding(14).background(Paper.sheet, in: RoundedRectangle(cornerRadius: 12))
                Button { pick = true } label: { Label("Find a packaged product",systemImage:"barcode.viewfinder") }.font(.subheadline.weight(.semibold))
                let pending = library.state.market.filter { !$0.bought }
                let bought = library.state.market.filter(\.bought)
                SectionTitle(title:"To pick up",detail:pending.count == 1 ? "1 item" : "\(pending.count) items")
                if pending.isEmpty { PaperEmpty(symbol:"basket",title:"Nothing to pick up",detail:"Type an item above, or add one here when you use up a batch.") }
                ForEach(pending) { item in row(item) }
                if !bought.isEmpty {
                    SectionTitle(title:"Purchased",detail:bought.count == 1 ? "1 item" : "\(bought.count) items")
                    ForEach(bought) { item in row(item) }
                    Button("Clear purchased items") { library.change { $0.market.removeAll(where: \.bought) } }
                        .font(.subheadline.weight(.medium)).foregroundStyle(Paper.berry)
                }
            }.padding(20).frame(maxWidth:760).frame(maxWidth:.infinity)
        }.background(Paper.page).scrollDismissesKeyboard(.interactively)
        .sheet(isPresented:$pick) { FoodCatalogPicker { product in library.change { $0.addToMarket(product.name) } } }
    }
    private func row(_ item: MarketItem) -> some View {
        HStack {
            Button {
                library.change { s in if let i = s.market.firstIndex(where: { $0.id == item.id }) { s.market[i].bought.toggle() } }
            } label: {
                HStack {
                    Image(systemName:item.bought ? "checkmark.circle.fill" : "circle").font(.title2)
                    Text(item.name).strikethrough(item.bought)
                    Spacer()
                }.contentShape(Rectangle())
            }.buttonStyle(.plain).accessibilityValue(item.bought ? "Purchased" : "Still to buy")
            Button { library.change { $0.market.removeAll { $0.id == item.id } } } label: { Image(systemName:"xmark").font(.footnote).frame(width:36,height:44) }.accessibilityLabel("Remove " + item.name)
        }.foregroundStyle(item.bought ? Paper.moss : Paper.ink)
    }
}

struct JournalPage: View {
    @EnvironmentObject var library: PantryLibrary
    @State private var kind: PantryMovement.Kind?
    private var week: [PantryMovement] {
        guard let start = Calendar.current.date(byAdding:.day,value:-6,to:Calendar.current.startOfDay(for:Date())) else { return [] }
        return library.state.journal.filter { $0.date >= start }
    }
    var body: some View {
        ScrollView {
            VStack(alignment:.leading,spacing:20) {
                LedgerHeader(title:"Ledger", index:"03")
                Kicker("The past seven days").foregroundStyle(Paper.moss)
                HStack(spacing:12) {
                    stat(.used, "fork.knife", Paper.grove)
                    stat(.discarded, "arrow.down.bin", Paper.berry)
                }
                SectionTitle(title:"Shelf history",detail:"Archive")
                Picker("Movements", selection:$kind) {
                    Text("All").tag(nil as PantryMovement.Kind?)
                    Text("Used").tag(PantryMovement.Kind.used as PantryMovement.Kind?)
                    Text("Waste").tag(PantryMovement.Kind.discarded as PantryMovement.Kind?)
                }.pickerStyle(.segmented)
                let entries = library.state.journal.filter { kind == nil || kind == $0.kind }
                if entries.isEmpty { PaperEmpty(symbol:"book.closed",title:"No movements yet",detail:"Open a batch on your shelf to record how much you used or discarded.") }
                ForEach(entries) { entry in
                    VStack(alignment:.leading,spacing:7) {
                        HStack(alignment:.firstTextBaseline) { Text(entry.name).font(.headline); Spacer(); Text("−\(entry.amount) \(entry.unit.rawValue)").font(.headline.monospacedDigit()) }
                        HStack { Text(entry.kind.rawValue); Spacer(); Text(entry.date,format:.dateTime.day().month(.abbreviated).hour().minute()) }.font(.caption).foregroundStyle(Paper.moss)
                        Divider()
                    }
                }
            }.padding(20).frame(maxWidth:760).frame(maxWidth:.infinity)
        }.background(Paper.page)
    }
    private func stat(_ kind: PantryMovement.Kind, _ symbol: String, _ color: Color) -> some View {
        let total = week.filter { $0.kind == kind }.count
        return VStack(alignment:.leading,spacing:7) {
            Image(systemName:symbol)
            Text("\(total)").font(.system(.largeTitle,design:.serif).weight(.semibold))
            Text(kind.rawValue).font(.subheadline.bold())
            Text(total == 1 ? "entry" : "entries").font(.caption)
        }.frame(maxWidth:.infinity,alignment:.leading).padding(16).foregroundStyle(Paper.page).background(color,in:RoundedRectangle(cornerRadius:14))
    }
}
