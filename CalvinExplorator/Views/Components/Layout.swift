import SwiftUI

/// Shared spacing and sizes
enum Layout {
    static let cornerRadius: CGFloat = 12
    static let pagePadding: CGFloat = 20
    static let cardSpacing: CGFloat = 16
    /// Cards sit side by side when each can be at least this wide
    static let minimumCardWidth: CGFloat = 440

    /// Adaptive grid for pairs of cards
    static let cardColumns = [
        GridItem(.adaptive(minimum: minimumCardWidth), spacing: cardSpacing, alignment: .top),
    ]
}
