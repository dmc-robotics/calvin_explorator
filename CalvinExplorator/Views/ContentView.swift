import SwiftUI

/// Main window: page sidebar, the selected page, and the robot status toolbar
struct ContentView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        @Bindable var model = model
        let page = model.selectedPage

        NavigationSplitView {
            List(Page.allCases, selection: sidebarSelection) { page in
                Label(page.title, systemImage: page.systemImage)
            }
            .navigationSplitViewColumnWidth(min: 180, ideal: 200, max: 260)
        } detail: {
            PageView(page: page)
                .navigationTitle(page.title)
                .navigationSubtitle(model.endpoint.displayName)
        }
        .toolbar {
            RobotStatusToolbar(model: model)
        }
        .task {
            model.start()
        }
        .alert("STOP isn't connected yet", isPresented: $model.isStopAlertPresented) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Nothing was sent to Calvin. Cogitator's gateway doesn't accept commands yet.")
        }
    }

    /// Ignores deselection (⌘-click on the selected row) so a page is always selected
    private var sidebarSelection: Binding<Page?> {
        Binding(
            get: { model.selectedPage },
            set: { newPage in
                if let newPage { model.selectedPage = newPage }
            }
        )
    }
}

/// The view for one sidebar page
private struct PageView: View {
    let page: Page

    var body: some View {
        switch page {
        case .dashboard: DashboardView()
        case .services: ServicesView()
        case .telemetry: TelemetryView()
        case .motorControl: MotorControlView()
        case .diagnostics: DiagnosticsView()
        case .logger: LoggerView()
        }
    }
}

#Preview {
    ContentView()
        .environment(AppModel())
        .frame(width: 1200, height: 800)
}
