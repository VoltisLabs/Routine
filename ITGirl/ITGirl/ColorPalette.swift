import SwiftUI

/// Which colour implementation is active. **Classic** is the original app look; **Chic** is the new pastel + gold theme.
enum ColorPaletteID: String, CaseIterable, Identifiable {
    case classic
    case chic

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .classic: "Classic (original)"
        case .chic: "Chic — pastel & gold"
        }
    }
}

/// Routes to **Classic** (`ITGirlTheme`) or **Chic** (`ITGirlChicTheme`) without replacing either.
enum ThemeColors {
    static func accent(for scheme: ColorScheme, palette: ColorPaletteID) -> Color {
        switch palette {
        case .classic: ITGirlTheme.accent(for: scheme)
        case .chic: ITGirlChicTheme.accent(for: scheme)
        }
    }

    static func secondaryAccent(for scheme: ColorScheme, palette: ColorPaletteID) -> Color {
        switch palette {
        case .classic: ITGirlTheme.secondaryAccent(for: scheme)
        case .chic: ITGirlChicTheme.secondaryAccent(for: scheme)
        }
    }

    static func backdropGradient(for scheme: ColorScheme, palette: ColorPaletteID) -> LinearGradient {
        switch palette {
        case .classic: ITGirlTheme.backdropGradient(for: scheme)
        case .chic: ITGirlChicTheme.backdropGradient(for: scheme)
        }
    }

    static func cardFill(for scheme: ColorScheme, palette: ColorPaletteID) -> Color {
        switch palette {
        case .classic: ITGirlTheme.cardFill(for: scheme)
        case .chic: ITGirlChicTheme.cardFill(for: scheme)
        }
    }

    static func cardStroke(for scheme: ColorScheme, palette: ColorPaletteID) -> Color {
        switch palette {
        case .classic: ITGirlTheme.cardStroke(for: scheme)
        case .chic: ITGirlChicTheme.cardStroke(for: scheme)
        }
    }

    static func cardShadow(for scheme: ColorScheme, palette: ColorPaletteID) -> Color {
        switch palette {
        case .classic: ITGirlTheme.cardShadow(for: scheme)
        case .chic: ITGirlChicTheme.cardShadow(for: scheme)
        }
    }
}

private struct ColorPaletteEnvironmentKey: EnvironmentKey {
    static let defaultValue = ColorPaletteID.classic
}

extension EnvironmentValues {
    var colorPalette: ColorPaletteID {
        get { self[ColorPaletteEnvironmentKey.self] }
        set { self[ColorPaletteEnvironmentKey.self] = newValue }
    }
}
