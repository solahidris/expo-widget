import WidgetKit
import SwiftUI

// Deterministic LCG shuffle of "abcdef" keyed on minute-of-day (0–1439)
private func wordForMinute(_ minuteOfDay: Int) -> String {
    var chars = Array("abcdef")
    var seed = minuteOfDay &* 1103515245 &+ 12345
    for i in stride(from: 5, through: 1, by: -1) {
        seed = seed &* 1103515245 &+ 12345
        let j = abs(seed) % (i + 1)
        chars.swapAt(i, j)
    }
    return String(chars)
}

struct WordEntry: TimelineEntry {
    let date: Date
    let word: String
}

struct WordProvider: TimelineProvider {
    func placeholder(in context: Context) -> WordEntry {
        WordEntry(date: Date(), word: "abcdef")
    }

    func getSnapshot(in context: Context, completion: @escaping (WordEntry) -> Void) {
        let now = Date()
        let cal = Calendar.current
        let h = cal.component(.hour, from: now)
        let m = cal.component(.minute, from: now)
        completion(WordEntry(date: now, word: wordForMinute(h * 60 + m)))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WordEntry>) -> Void) {
        let cal = Calendar.current
        let now = Date()
        let comps = cal.dateComponents([.year, .month, .day, .hour, .minute], from: now)
        let startOfMinute = cal.date(from: comps) ?? now
        let h = comps.hour ?? 0
        let m = comps.minute ?? 0
        let base = h * 60 + m

        var entries: [WordEntry] = []
        for offset in 0..<60 {
            guard let date = cal.date(byAdding: .minute, value: offset, to: startOfMinute) else { continue }
            let word = wordForMinute((base + offset) % 1440)
            entries.append(WordEntry(date: date, word: word))
        }

        let refresh = cal.date(byAdding: .minute, value: 60, to: startOfMinute) ?? now
        completion(Timeline(entries: entries, policy: .after(refresh)))
    }
}

struct LockWidgetView: View {
    var entry: WordEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .accessoryInline:
            Text(entry.word)
                .font(.system(.caption, design: .monospaced, weight: .bold))

        case .accessoryRectangular:
            VStack(alignment: .leading, spacing: 4) {
                Text("minute word")
                    .font(.system(.caption2))
                    .foregroundStyle(.secondary)
                Text(entry.word)
                    .font(.system(.title3, design: .monospaced, weight: .bold))
            }
            .frame(maxWidth: .infinity, alignment: .leading)

        case .accessoryCircular:
            Text(String(entry.word.prefix(3)))
                .font(.system(.caption, design: .monospaced, weight: .bold))
                .multilineTextAlignment(.center)

        default:
            Text(entry.word)
                .font(.system(.body, design: .monospaced))
        }
    }
}

@main
struct LockWidget: Widget {
    let kind = "LockWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WordProvider()) { entry in
            LockWidgetView(entry: entry)
                .containerBackground(.black, for: .widget)
        }
        .configurationDisplayName("Minute Word")
        .description("Shuffles abcdef every minute on your lock screen.")
        .supportedFamilies([
            .accessoryInline,
            .accessoryRectangular,
            .accessoryCircular,
        ])
    }
}
