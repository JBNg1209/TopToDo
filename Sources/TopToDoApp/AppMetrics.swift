import SwiftUI

/// User-selectable font size, persisted across launches via @AppStorage.
enum FontSize: String, CaseIterable, Identifiable {
    case small
    case medium
    case large
    case extraLarge

    var id: String { rawValue }

    /// Multiplier applied to user-scaled fonts and spacings.
    var scale: Double {
        switch self {
        case .small: return 0.9
        case .medium: return 1.0
        case .large: return 1.15
        case .extraLarge: return 1.3
        }
    }

    func label(using strings: AppStrings) -> String {
        switch self {
        case .small: strings.fontSizeSmall
        case .medium: strings.fontSizeMedium
        case .large: strings.fontSizeLarge
        case .extraLarge: strings.fontSizeExtraLarge
        }
    }
}

private struct FontScaleKey: EnvironmentKey {
    static let defaultValue: Double = 1.0
}

extension EnvironmentValues {
    /// Multiplier derived from the user's font size preference.
    var fontScale: Double {
        get { self[FontScaleKey.self] }
        set { self[FontScaleKey.self] = newValue }
    }
}

/// Scaled layout and typography values, derived from the current font scale.
/// Use this everywhere the title is not, so that growing text also grows the surrounding
/// spacing / row heights and avoids a cramped page.
struct AppMetrics {
    let scale: CGFloat

    init(scale: Double) {
        self.scale = CGFloat(scale)
    }

    // MARK: Spacing
    var tinySpacing: CGFloat { 4 * scale }
    var compactSpacing: CGFloat { 8 * scale }
    var standardSpacing: CGFloat { 10 * scale }
    var comfortableSpacing: CGFloat { 12 * scale }
    var spaciousSpacing: CGFloat { 16 * scale }
    var tagPickerSpacing: CGFloat { 6 * scale }

    // MARK: Frame sizes
    var rowHeight: CGFloat { 32 * scale }
    var minEditHeight: CGFloat { 24 * scale }

    // MARK: Font sizes (macOS default points)
    var captionSize: CGFloat { 11 * scale }
    var bodySize: CGFloat { 13 * scale }
}
