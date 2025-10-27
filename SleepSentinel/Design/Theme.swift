import SwiftUI

enum Theme {
    static let accent = Color(hex: 0x6EA8FE)
    static let primary = Color(hex: 0x141A2A)
    static let secondary = Color(hex: 0x1E2740)
    static let card = Color(hex: 0x202A48)
    static let cardAlt = Color(hex: 0x243055)
    static let good = Color(hex: 0x6AD59A)
    static let warn = Color(hex: 0xF3B76B)
    static let alert = Color(hex: 0xF07C7C)

    static let appBackground = LinearGradient(
        colors: [Color(hex: 0x0F1422), Color(hex: 0x0A0F1C)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

/// Concrete modifier type. Do not use `any ViewModifier`.
struct ThemedCardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Theme.card, Theme.cardAlt],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.06), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.25), radius: 10, x: 0, y: 6)
    }
}

extension View {
    func themedCard() -> some View { self.modifier(ThemedCardStyle()) }
}
