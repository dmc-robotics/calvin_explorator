import SwiftUI

/// Rounded section container with a title, optional subtitle, and optional trailing accessory
struct Card<Accessory: View, Content: View>: View {
    let title: String
    var subtitle: String?
    @ViewBuilder var accessory: Accessory
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                    if let subtitle {
                        Text(subtitle)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                // Let the accessory give up space before the title wraps
                .layoutPriority(1)
                Spacer()
                accessory
            }
            content
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background.secondary, in: .rect(cornerRadius: Layout.cornerRadius))
    }
}

extension Card where Accessory == EmptyView {
    init(title: String, subtitle: String? = nil, @ViewBuilder content: () -> Content) {
        self.init(title: title, subtitle: subtitle, accessory: { EmptyView() }, content: content)
    }
}

#Preview {
    Card(title: "Front Distance Sensor", subtitle: "VL53L4CX ToF - Adafruit 5425") {
        Text("Content")
    }
    .padding()
}
