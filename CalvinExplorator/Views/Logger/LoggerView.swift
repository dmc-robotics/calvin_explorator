import SwiftUI

/// Every WebSocket message sent (TX) and received (RX), following the newest
struct LoggerView: View {
    @Environment(AppModel.self) private var model
    @State private var filter = ""

    var body: some View {
        let log = model.messageLog
        let entries = filteredEntries(log.entries)

        VStack(spacing: 12) {
            HStack {
                Text(log.isPaused ? "Paused" : "\(log.entries.count) messages")
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
                Spacer()
                TextField("Filter", text: $filter, prompt: Text("Filter messages"))
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: 240)
                Button(log.isPaused ? "Resume" : "Pause", systemImage: log.isPaused ? "play.fill" : "pause.fill") {
                    log.isPaused.toggle()
                }
                .help(log.isPaused ? "Resume recording" : "Pause recording")
                Button("Clear", systemImage: "trash", action: log.clear)
                    .help("Clear all messages")
            }
            .labelStyle(.iconOnly)

            // A List (table-backed) stays responsive with thousands of rows arriving 10× a second
            ScrollViewReader { proxy in
                List(entries) { entry in
                    LogRow(entry: entry)
                        .listRowSeparator(.hidden)
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .textSelection(.enabled)
                // Follow new messages. Pausing stops recording, so the view holds still for reading
                .onChange(of: entries.last?.id, initial: true) { _, lastID in
                    if let lastID {
                        proxy.scrollTo(lastID, anchor: .bottom)
                    }
                }
            }
            .overlay {
                if entries.isEmpty {
                    Text(log.entries.isEmpty ? "No messages yet" : "No matching messages")
                        .foregroundStyle(.secondary)
                }
            }
            .background(.background.secondary, in: .rect(cornerRadius: Layout.cornerRadius))
        }
        .padding(Layout.pagePadding)
    }

    private func filteredEntries(_ entries: [LogEntry]) -> [LogEntry] {
        let filter = filter.trimmingCharacters(in: .whitespaces)
        guard !filter.isEmpty else { return entries }
        return entries.filter { $0.text.localizedCaseInsensitiveContains(filter) }
    }
}

private struct LogRow: View {
    private static let timeFormat = Date.VerbatimFormatStyle(
        format: "\(hour: .twoDigits(clock: .twentyFourHour, hourCycle: .zeroBased)):\(minute: .twoDigits):\(second: .twoDigits).\(secondFraction: .fractional(3))",
        timeZone: .current,
        calendar: .current
    )

    let entry: LogEntry

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(entry.time, format: Self.timeFormat)
                .foregroundStyle(.secondary)
            Text(entry.direction == .sent ? "TX" : "RX")
                .foregroundStyle(entry.direction == .sent ? Color.accentColor : .green)
            Text(entry.text)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .font(.system(.caption, design: .monospaced))
    }
}

#Preview {
    LoggerView()
        .environment(AppModel())
        .frame(width: 900, height: 600)
}
