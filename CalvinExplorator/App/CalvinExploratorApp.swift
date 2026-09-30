import SwiftUI

@main
struct CalvinExploratorApp: App {
    @State private var model = AppModel()

    var body: some Scene {
        Window("Calvin Explorator", id: "main") {
            ContentView()
                .environment(model)
        }
        .defaultSize(width: 1200, height: 800)
        .commands {
            AppCommands(model: model)
        }

        Settings {
            SettingsView()
                .environment(model)
        }
    }
}
