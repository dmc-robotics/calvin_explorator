import SwiftUI

/// Video feed with a command box pinned underneath
struct DashboardView: View {
    /// Keeps the video and command box from getting too wide on large windows
    private static let maxContentWidth: CGFloat = 1024

    var body: some View {
        VideoPlaceholder()
            .frame(maxWidth: Self.maxContentWidth, maxHeight: .infinity)
            .padding(Layout.pagePadding)
            .frame(maxWidth: .infinity)
            .safeAreaInset(edge: .bottom) {
                CommandField()
                    .frame(maxWidth: Self.maxContentWidth)
                    .padding([.horizontal, .bottom], Layout.pagePadding)
            }
    }
}

/// 4:3 stand-in for the OAK-D video stream
private struct VideoPlaceholder: View {
    private static let aspectRatio: CGFloat = 4 / 3

    var body: some View {
        RoundedRectangle(cornerRadius: Layout.cornerRadius)
            .fill(.black)
            .overlay {
                Text("Video stream will display here")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            .aspectRatio(Self.aspectRatio, contentMode: .fit)
    }
}

/// Multi-line command entry. Return sends; Option-Return inserts a new line
private struct CommandField: View {
    private static let lineLimit = 3...8

    @State private var command = ""

    private var trimmedCommand: String {
        command.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: 10) {
            TextField("Enter command to send to remote host…", text: $command, axis: .vertical)
                .textFieldStyle(.plain)
                .lineLimit(Self.lineLimit)
                .onSubmit(send)

            Button("Send", systemImage: "arrow.up", action: send)
                .labelStyle(.iconOnly)
                .fontWeight(.bold)
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.circle)
                .disabled(trimmedCommand.isEmpty)
        }
        .padding(12)
        .glassEffect(in: .rect(cornerRadius: Layout.cornerRadius + 4))
    }

    private func send() {
        guard !trimmedCommand.isEmpty else { return }
        // TODO: send to cogitator once it accepts commands (they'll go to its local LLM)
        command = ""
    }
}

#Preview {
    DashboardView()
        .frame(width: 900, height: 700)
}
