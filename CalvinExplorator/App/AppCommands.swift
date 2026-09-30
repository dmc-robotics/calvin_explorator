import SwiftUI

/// Menu bar additions: page switching in the View menu and a Robot menu
struct AppCommands: Commands {
    let model: AppModel

    var body: some Commands {
        SidebarCommands()

        CommandGroup(before: .sidebar) {
            ForEach(Page.allCases) { page in
                Button(page.title) {
                    model.selectedPage = page
                }
                .keyboardShortcut(page.keyboardShortcut)
            }
            Divider()
        }

        CommandMenu("Robot") {
            Button("Emergency Stop") {
                model.emergencyStop()
            }
            .keyboardShortcut(".")

            Divider()

            Button("Reconnect to Cogitator") {
                model.reconnect()
            }
            .keyboardShortcut("r", modifiers: [.command, .shift])
        }
    }
}
