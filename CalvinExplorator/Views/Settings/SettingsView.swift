import SwiftUI

/// The app's Settings window (⌘,)
struct SettingsView: View {
    private static let width: CGFloat = 460

    @Environment(AppModel.self) private var model
    @State private var host = ""
    @State private var port = CogitatorEndpoint.defaultPort

    private var enteredEndpoint: CogitatorEndpoint {
        CogitatorEndpoint(host: host.trimmingCharacters(in: .whitespaces), port: port)
    }

    var body: some View {
        Form {
            Section {
                TextField("Host", text: $host, prompt: Text(CogitatorEndpoint.defaultHost))
                TextField("Port", value: $port, format: .number.grouping(.never), prompt: Text(String(CogitatorEndpoint.defaultPort)))
                LabeledContent("Status") {
                    TimelineView(.periodic(from: .now, by: 1)) { context in
                        Text(model.connection.status.label(now: context.date))
                    }
                }
            } header: {
                Text("Cogitator Connection")
            } footer: {
                HStack {
                    Text("Hostname or IP address of cogitator's WebSocket gateway.")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button("Connect", action: connect)
                        .keyboardShortcut(.defaultAction)
                        .disabled(enteredEndpoint.url == nil)
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: Self.width)
        .fixedSize()
        .onAppear {
            host = model.endpoint.host
            port = model.endpoint.port
        }
    }

    private func connect() {
        guard enteredEndpoint.url != nil else { return }
        model.connect(to: enteredEndpoint)
    }
}

#Preview {
    SettingsView()
        .environment(AppModel())
}
