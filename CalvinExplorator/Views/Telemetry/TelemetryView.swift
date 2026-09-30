import SwiftUI

/// Live balance, IMU, and ToF sensor data
struct TelemetryView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        let telemetry = model.telemetry

        ScrollView {
            VStack(spacing: Layout.cardSpacing) {
                BalanceCard(balance: telemetry.balance)

                LazyVGrid(columns: Layout.cardColumns, spacing: Layout.cardSpacing) {
                    IMUCard(title: "Balancer IMU", sensor: telemetry.imuBalancer)
                    IMUCard(title: "OAK-D Pro W IMU", sensor: telemetry.imuOakD)
                }

                LazyVGrid(columns: Layout.cardColumns, spacing: Layout.cardSpacing) {
                    ToFCard(title: "Front Distance Sensor", sensor: telemetry.tofFront, color: ChartStyle.primary)
                    ToFCard(title: "Rear Distance Sensor", sensor: telemetry.tofRear, color: ChartStyle.secondary)
                }
            }
            .padding(Layout.pagePadding)
        }
    }
}

#Preview {
    TelemetryView()
        .environment(AppModel())
        .frame(width: 1000, height: 900)
}
