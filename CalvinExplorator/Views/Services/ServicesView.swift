import SwiftUI

/// On/off switches for cogitator services (stubs, saved locally)
struct ServicesView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        Form {
            Section {
                ForEach(ServicesStore.definitions) { service in
                    Toggle(isOn: binding(for: service)) {
                        Text(service.title)
                        Text(service.description)
                    }
                    .toggleStyle(.switch)
                }
            } footer: {
                Text("Service switches are saved on this Mac and aren't sent to cogitator yet.")
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
    }

    private func binding(for service: ServiceDefinition) -> Binding<Bool> {
        let services = model.services
        return Binding(
            get: { services.isEnabled(service) },
            set: { services.setEnabled($0, for: service) }
        )
    }
}

#Preview {
    ServicesView()
        .environment(AppModel())
}
