import SwiftUI
import UIKit

/// Design tokens modelled on Peloton Strength+: flat white cards on a cool grey page, a single
/// red call-to-action, small tracked uppercase section labels, and a dark charcoal + mint
/// treatment for live workout screens.
enum Theme {
    // MARK: Colour

    /// Page background behind cards.
    static let page = dynamic(light: 0xE9EBEF, dark: 0x0F1012)
    /// Card surface.
    static let card = dynamic(light: 0xFFFFFF, dark: 0x1A1C20)
    /// Tile / accordion row sitting on a card.
    static let tile = dynamic(light: 0xF3F4F6, dark: 0x25282D)
    static let divider = dynamic(light: 0xE3E5E9, dark: 0x2E3238)
    static let textPrimary = dynamic(light: 0x16181C, dark: 0xF5F6F7)
    static let textSecondary = dynamic(light: 0x6A707A, dark: 0x9AA0A8)
    /// Brand call-to-action and selected-tab red.
    static let red = Color(hex: 0xFF2D4B)
    /// Progress / completed state, used on dark workout screens.
    static let mint = Color(hex: 0x3DCDB4)
    /// Positive trend arrows.
    static let up = Color(hex: 0x2BB38A)
    /// Data blue used for muscle activity and links inside cards.
    static let blue = Color(hex: 0x3B82D6)
    static let amber = Color(hex: 0xF2B544)

    // MARK: Shape

    static let cardRadius: CGFloat = 12
    static let tileRadius: CGFloat = 8

    private static func dynamic(light: UInt32, dark: UInt32) -> Color {
        Color(UIColor { $0.userInterfaceStyle == .dark ? UIColor(hex: dark) : UIColor(hex: light) })
    }
}

extension Color {
    init(hex: UInt32) { self.init(UIColor(hex: hex)) }
}

extension UIColor {
    convenience init(hex: UInt32) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: 1
        )
    }
}

// MARK: - Containers

/// Page scaffold: grey background, scrolling stack of cards.
struct ThemedScroll<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) { content }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
        }
        .background(Theme.page.ignoresSafeArea())
        .scrollDismissesKeyboard(.interactively)
    }
}

struct Card<Content: View>: View {
    var padding: CGFloat = 16
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) { content }
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.card, in: RoundedRectangle(cornerRadius: Theme.cardRadius))
    }
}

/// Small tracked uppercase label ("WORKOUT PLAN", "BODY ACTIVITY").
struct SectionLabel: View {
    let text: String
    init(_ text: String) { self.text = text }

    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 12, weight: .semibold))
            .tracking(1.2)
            .foregroundStyle(Theme.textSecondary)
    }
}

// MARK: - Controls

/// Full-width red capsule with an optional leading icon ("▶ START").
struct PrimaryButton: View {
    let title: String
    var icon: String?
    var tint: Color = Theme.red
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon { Image(systemName: icon).font(.system(size: 14, weight: .bold)) }
                Text(title.uppercased()).font(.system(size: 16, weight: .semibold)).tracking(1)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(tint, in: Capsule())
        }
        .buttonStyle(.plain)
    }
}

/// Outlined capsule ("✓ DONE").
struct OutlineButton: View {
    let title: String
    var icon: String?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon { Image(systemName: icon).font(.system(size: 15, weight: .semibold)) }
                Text(title.uppercased()).font(.system(size: 15, weight: .semibold)).tracking(1)
            }
            .foregroundStyle(Theme.textPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: 46)
            .overlay(Capsule().strokeBorder(Theme.textSecondary.opacity(0.5), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

/// Round icon button used for stop / pause on workout screens.
struct RoundIconButton: View {
    let icon: String
    var fill: Color
    var size: CGFloat = 44
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: size * 0.36, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: size, height: size)
                .background(fill, in: Circle())
        }
        .buttonStyle(.plain)
    }
}

/// Segmented progress bar, one dash per block ("7/7 Blocks").
struct BlockProgress: View {
    let completed: Int
    let total: Int

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<max(total, 1), id: \.self) { index in
                Capsule()
                    .fill(index < completed ? Theme.mint : Theme.divider)
                    .frame(height: 3)
            }
        }
    }
}

/// Thin red-or-mint determinate bar.
struct ThinProgress: View {
    let value: Double
    var tint: Color = Theme.red

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(Theme.divider)
                Capsule().fill(tint).frame(width: proxy.size.width * min(max(value, 0), 1))
            }
        }
        .frame(height: 4)
    }
}

// MARK: - Data display

/// Label over a large value, with an optional green delta ("▲ 1").
struct StatTile: View {
    let label: String
    let value: String
    var unit: String?
    var delta: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).font(.system(size: 12)).foregroundStyle(Theme.textSecondary)
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(value).font(.system(size: 22, weight: .medium)).monospacedDigit()
                if let unit { Text(unit).font(.system(size: 12)).foregroundStyle(Theme.textSecondary) }
                if let delta {
                    Image(systemName: "arrowtriangle.up.fill").font(.system(size: 8)).foregroundStyle(Theme.up)
                    Text(delta).font(.system(size: 11)).foregroundStyle(Theme.textSecondary)
                }
            }
            .foregroundStyle(Theme.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Theme.tile, in: RoundedRectangle(cornerRadius: Theme.tileRadius))
    }
}

/// Label on the left, value on the right, hairline below ("Glutes   14%").
struct StatRow: View {
    let label: String
    let value: String
    var showsDivider = true

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(label).font(.system(size: 15)).foregroundStyle(Theme.textPrimary)
                Spacer()
                Text(value).font(.system(size: 15)).monospacedDigit().foregroundStyle(Theme.textPrimary)
            }
            .padding(.vertical, 12)
            if showsDivider { Divider().overlay(Theme.divider) }
        }
    }
}

/// Underlined text tabs ("Overview | Workouts | Achievements").
struct UnderlineTabs<Value: Hashable>: View {
    let items: [(value: Value, title: String)]
    @Binding var selection: Value

    var body: some View {
        HStack(spacing: 0) {
            ForEach(items, id: \.value) { item in
                Button { selection = item.value } label: {
                    VStack(spacing: 8) {
                        Text(item.title)
                            .font(.system(size: 15, weight: selection == item.value ? .semibold : .regular))
                            .foregroundStyle(selection == item.value ? Theme.textPrimary : Theme.textSecondary)
                        Rectangle()
                            .fill(selection == item.value ? Theme.red : .clear)
                            .frame(height: 2)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
            }
        }
        .background(alignment: .bottom) { Rectangle().fill(Theme.divider).frame(height: 1) }
    }
}

/// Sits on a card and shows a tappable row with chevron (accordion / navigation row).
struct TileRow: View {
    var icon: String?
    let title: String
    var subtitle: String?
    var chevron = "chevron.right"

    var body: some View {
        HStack(spacing: 12) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundStyle(Theme.textPrimary)
                    .frame(width: 28)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.system(size: 15, weight: .medium)).foregroundStyle(Theme.textPrimary)
                if let subtitle {
                    Text(subtitle).font(.system(size: 13)).foregroundStyle(Theme.textSecondary).lineLimit(1)
                }
            }
            Spacer()
            Image(systemName: chevron).font(.system(size: 13, weight: .medium)).foregroundStyle(Theme.textSecondary)
        }
        .padding(12)
        .background(Theme.tile, in: RoundedRectangle(cornerRadius: Theme.tileRadius))
    }
}

/// Small coloured level tag ("■ INTERMEDIATE").
struct LevelTag: View {
    let text: String
    var tint: Color = Theme.amber

    var body: some View {
        HStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 2).fill(tint).frame(width: 8, height: 8)
            Text(text.uppercased()).font(.system(size: 11, weight: .medium)).tracking(0.8)
                .foregroundStyle(Theme.textSecondary)
        }
    }
}
