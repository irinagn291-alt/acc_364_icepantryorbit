import SwiftUI

struct BatchForm: View {
    @EnvironmentObject var library: PantryLibrary
    @Environment(\.dismiss) private var dismiss
    var existing: PantryBatch?
    @State private var name: String
    @State private var brand: String
    @State private var barcode: String?
    @State private var amount: String
    @State private var unit: PantryUnit
    @State private var place: PantryPlace
    @State private var expiry: Date
    @State private var picker = false
    init(existing: PantryBatch?) {
        self.existing = existing
        _name = State(initialValue: existing?.name ?? "")
        _brand = State(initialValue: existing?.brand ?? "")
        _barcode = State(initialValue: existing?.barcode)
        _amount = State(initialValue: String(existing?.amount ?? 1))
        _unit = State(initialValue: existing?.unit ?? .pieces)
        _place = State(initialValue: existing?.place ?? .cupboard)
        _expiry = State(initialValue: existing?.expiry ?? Date())
        #if DEBUG && targetEnvironment(simulator)
        if existing == nil && ScreenshotLaunch.key == "new-batch" {
            _name = State(initialValue: "Cannellini beans")
            _amount = State(initialValue: "3")
            _expiry = State(initialValue: ScreenshotLaunch.day(14))
        }
        if existing == nil && ["food-catalog", "barcode-scanner", "manual-product"].contains(ScreenshotLaunch.key ?? "") {
            _picker = State(initialValue: true)
        }
        #endif
    }
    private var trimmed: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var number: Int? { Int(amount).flatMap { (1...9999999).contains($0) ? $0 : nil } }
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Button { picker = true } label: { Label("Search or scan a barcode",systemImage:"barcode.viewfinder") }
                    TextField("Product name",text:$name).accessibilityIdentifier("batch.name")
                    if !brand.isEmpty { LabeledContent("Brand",value:brand) }
                } header: { Text("01   Product") } footer: { Text("Look up the package in Open Food Facts or type a name below.") }
                Section("02   Batch") {
                    HStack {
                        Text("Quantity")
                        Spacer()
                        Button { amount = String(max(1, (number ?? 1) - 1)) } label: { Image(systemName:"minus.circle") }
                            .buttonStyle(.borderless).accessibilityLabel("Decrease quantity")
                        TextField("1",text:$amount).accessibilityIdentifier("batch.amount").keyboardType(.numberPad)
                            .multilineTextAlignment(.center).frame(maxWidth: 70)
                        Button { amount = String(min(9999999, (number ?? 0) + 1)) } label: { Image(systemName:"plus.circle") }
                            .buttonStyle(.borderless).accessibilityLabel("Increase quantity")
                    }
                    Picker("Unit", selection:$unit) { ForEach(PantryUnit.allCases) { u in Text(u.rawValue).tag(u) } }
                    Picker("Storage", selection:$place) { ForEach(PantryPlace.allCases) { p in Label(p.rawValue, systemImage:p.symbol).tag(p) } }
                }
                Section {
                    DatePicker("Label date",selection:$expiry,displayedComponents:.date)
                } header: { Text("03   Printed date") } footer: { Text("Use the date printed on this particular package.") }
                Section { Button(existing == nil ? "Add to shelf" : "Save changes") { save() }
                        .frame(maxWidth:.infinity).font(.headline).disabled(trimmed.isEmpty || number == nil).accessibilityIdentifier("batch.save")
                }
            }.scrollContentBackground(.hidden).background(Paper.page)
            .navigationTitle(existing == nil ? "New batch" : "Edit batch")
            .toolbar { ToolbarItem(placement:.cancellationAction) { Button("Close") { dismiss() } } }
            .sheet(isPresented:$picker) {
                FoodCatalogPicker { product in
                    name = product.name; brand = product.brand; barcode = product.id
                }
            }
        }
        #if DEBUG && targetEnvironment(simulator)
        .transaction { if ScreenshotLaunch.active { $0.disablesAnimations = true; $0.animation = nil } }
        #endif
    }
    private func save() {
        guard !trimmed.isEmpty, let number else { return }
        let batch = PantryBatch(id: existing?.id ?? UUID(),name:trimmed,brand:brand,barcode:barcode,amount:number,unit:unit,place:place,expiry:Calendar.current.startOfDay(for:expiry))
        library.change { $0.save(batch) }; dismiss()
    }
}

struct BatchDetail: View {
    var id: UUID
    @EnvironmentObject var library: PantryLibrary
    @Environment(\.dismiss) private var dismiss
    @State private var amount = "1"
    @State private var kind: PantryMovement.Kind = .used
    @State private var restock = false
    @State private var editing = false
    @State private var askTrash = false
    init(id: UUID) {
        self.id = id
        #if DEBUG && targetEnvironment(simulator)
        if ScreenshotLaunch.key == "batch-details" { _restock = State(initialValue: true) }
        #endif
    }
    var body: some View {
        NavigationStack {
            if let batch = library.state.batches.first(where: { $0.id == id }) {
                Form {
                    Section {
                        VStack(alignment:.leading,spacing:10) {
                            Kicker(batch.place.rawValue).foregroundStyle(Paper.moss)
                            Text(batch.name).font(.system(.largeTitle,design:.serif).weight(.semibold))
                            if !batch.brand.isEmpty { Text(batch.brand).foregroundStyle(Paper.moss) }
                            HStack { Label(batch.quantity, systemImage:"shippingbox"); Spacer(); Text(batch.deadline()).foregroundStyle(batch.days() <= 1 ? Paper.berry : Paper.moss) }.font(.headline)
                        }.padding(.vertical,8)
                        LabeledContent("Label date") { Text(batch.expiry,format:.dateTime.day().month(.wide).year()) }
                        if let code = batch.barcode, code.allSatisfy(\.isNumber), !code.isEmpty, let url = URL(string:"https://world.openfoodfacts.org/product/" + code) {
                            Link("View on Open Food Facts ↗",destination:url)
                        }
                        Button("Edit batch") { editing = true }
                    }
                    Section("Record a movement") {
                        Picker("Action",selection:$kind) {
                            Text("Use").tag(PantryMovement.Kind.used)
                            Text("Discard").tag(PantryMovement.Kind.discarded)
                        }.pickerStyle(.segmented)
                        HStack {
                            TextField("Quantity",text:$amount).accessibilityIdentifier("batch.amount").keyboardType(.numberPad)
                            Text(batch.unit.rawValue).foregroundStyle(Paper.moss)
                            Button("All") { amount = String(batch.amount) }.buttonStyle(.bordered)
                        }
                        Toggle("Add to shopping list",isOn:$restock)
                        Button(kind == .used ? "Record use" : "Record waste") {
                            if kind == .discarded { askTrash = true }
                            else { move(batch) }
                        }.disabled(!(Int(amount).map { (1...batch.amount).contains($0) } ?? false))
                    }
                }.scrollContentBackground(.hidden).background(Paper.page)
                .navigationTitle("Batch details").navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement:.cancellationAction) { Button("Close") { dismiss() } } }
                .sheet(isPresented:$editing) { BatchForm(existing:batch) }
                .confirmationDialog("Discard \(amount) \(batch.unit.rawValue)?",isPresented:$askTrash,titleVisibility:.visible) {
                    Button("Discard",role:.destructive) { move(batch) }
                    Button("Cancel",role:.cancel) {}
                }
            } else {
                ContentUnavailableView("Batch finished",systemImage:"checkmark.circle").onAppear { dismiss() }
            }
        }
        #if DEBUG && targetEnvironment(simulator)
        .transaction { if ScreenshotLaunch.active { $0.disablesAnimations = true; $0.animation = nil } }
        #endif
    }
    private func move(_ batch: PantryBatch) {
        guard let n = Int(amount), (1...batch.amount).contains(n) else { return }
        library.change { $0.move(batch.id,amount:n,kind:kind,restock:restock) }; dismiss()
    }
}
