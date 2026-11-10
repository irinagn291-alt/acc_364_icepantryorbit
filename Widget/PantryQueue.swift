import SwiftUI
import WidgetKit

struct QueueEntry: TimelineEntry {
    var date: Date
    var snapshot: PocketSnapshot
}

struct QueueProvider: TimelineProvider {
    func placeholder(in context: Context) -> QueueEntry { sample }
    func getSnapshot(in context: Context, completion: @escaping (QueueEntry) -> Void) { completion(context.isPreview ? sample : current) }
    func getTimeline(in context: Context, completion: @escaping (Timeline<QueueEntry>) -> Void) {
        let now = Date()
        let nextDay = Calendar.current.dateInterval(of: .day, for: now)?.end ?? now.addingTimeInterval(3600)
        completion(Timeline(entries:[current],policy:.after(nextDay)))
    }
    private var current: QueueEntry {
        let defaults = UserDefaults(suiteName:PocketSnapshot.group)
        return QueueEntry(date:Date(),snapshot:defaults.map(PocketSnapshot.load) ?? .init())
    }
    private var sample: QueueEntry {
        let batch = PantryBatch(name:"Tomatoes",brand:"",amount:2,unit:.pieces,place:.fridge,expiry:Date())
        return QueueEntry(date:Date(),snapshot:PocketSnapshot(.init(batches:[batch])))
    }
}

@main
struct PantryQueueWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind:"PantryOrbitQueue",provider:QueueProvider()) { entry in
            QueueView(entry:entry).containerBackground(for:.widget) { Color(red:0.12,green:0.258,blue:0.18) }
        }.configurationDisplayName("Use first").description("See which pantry batches reach their printed dates first.").supportedFamilies([.systemSmall,.systemMedium])
    }
}

struct QueueView: View {
    var entry: QueueEntry
    @Environment(\.widgetFamily) var family
    var body: some View {
        VStack(alignment:.leading,spacing:6) {
            Label("PANTRY ORBIT",systemImage:"leaf.fill").font(.system(.caption2,design:.monospaced).bold()).tracking(1)
                .foregroundStyle(Color(red:0.99,green:0.70,blue:0.36))
            Spacer(minLength:2)
            if let batch = entry.snapshot.upcoming.first {
                Text(batch.name).font(.system(.title2,design:.serif).bold()).lineLimit(2)
                Text(batch.deadline(on:entry.date) + " · " + batch.quantity).font(.caption)
                if family == .systemMedium, let next = entry.snapshot.upcoming.dropFirst().first {
                    Divider().overlay(.white.opacity(0.35))
                    Text("Next · " + next.name + " · " + next.deadline(on:entry.date)).font(.caption2).lineLimit(1)
                }
            } else {
                Text("An open shelf").font(.system(.title2,design:.serif).bold())
                Text("Add your first batch in IcePantryOrbit.").font(.caption)
            }
            Spacer(minLength:2)
        }.foregroundStyle(.white).frame(maxWidth:.infinity,alignment:.leading)
        .widgetURL(entry.snapshot.upcoming.first.flatMap { URL(string:"pantryorbit://batch/" + $0.id.uuidString) } ?? URL(string:"pantryorbit://shelf"))
    }
}
