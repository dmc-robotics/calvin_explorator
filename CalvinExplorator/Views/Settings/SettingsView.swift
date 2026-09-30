import SwiftUI

/// The app's Settings window (⌘,)
struct SettingsView: View {
    private static let width: CGFloat = 460

    @Environment(AppModel.self) private var model
    @State private var host = ""
    /// Text rather than a number field: a number field only commits on Return or losing focus,
    /// so clicking Connect could use the old port
    @State private var portText = ""

    private var enteredEndpoint: CogitatorEndpoint {
        CogitatorEndpoint(
            host: host.trimmingCharacters(in: .whitespaces),
            port: Int(portText.trimmingCharacters(in: .whitespaces)) ?? 0
        )
    }

    var body: some View {
        Form {
            Section {
                TextField("Host", text: $host, prompt: Text(CogitatorEndpoint.defaultHost))
                TextField("Port", text: $portText, prompt: Text(String(CogitatorEndpoint.defaultPort)))
                LabeledContent("Status") {
                    TimelineView(.periodic(from: .now, by: 1)) { context in
                        Text(model.connection.status.label(now: context.date))
                    }
                }
            } header: {
                Text("Cogitator Connection")
            } footer: {
                HStack {
                    Text("Hostname or IP address of cogitator's WebSocket gateway. Put IPv6 addresses in brackets.")
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
            portText = String(model.endpoint.port)
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
