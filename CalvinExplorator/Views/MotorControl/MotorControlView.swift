import SwiftUI

/// Placeholder for the ODrive S1 motor controller interface
struct MotorControlView: View {
    var body: some View {
        ContentUnavailableView(
            "Motor Control",
            systemImage: Page.motorControl.systemImage,
            description: Text("ODrive S1 motor controller interface.")
        )
    }
}

#Preview {
    MotorControlView()
}
