import SwiftUI

/// Sidebar destinations. Settings live in the standard Settings window (⌘,)
enum Page: String, CaseIterable, Identifiable {
    case dashboard
    case services
    case telemetry
    case motorControl
    case diagnostics
    case logger

    var id: Self { self }

    var title: String {
        switch self {
        case .dashboard: "Dashboard"
        case .services: "Services"
        case .telemetry: "Telemetry"
        case .motorControl: "Motor Control"
        case .diagnostics: "Diagnostics"
        case .logger: "Logger"
        }
    }

    var systemImage: String {
        switch self {
        case .dashboard: "play.tv"
        case .services: "square.stack.3d.up"
        case .telemetry: "antenna.radiowaves.left.and.right"
        case .motorControl: "gearshape.2"
        case .diagnostics: "waveform.path.ecg"
        case .logger: "list.bullet.rectangle"
        }
    }

    /// ⌘1 through ⌘6, in sidebar order
    var keyboardShortcut: KeyEquivalent {
        let index = Self.allCases.firstIndex(of: self)!
        return KeyEquivalent(Character(String(index + 1)))
    }
}
