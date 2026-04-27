import SwiftUI

/// Which colour implementation is active. **Classic** is the original app look; **Chic** is the new pastel + gold theme.
enum ColorPaletteID: String, CaseIterable, Identifiable {
    case classic
    case chic
    case graphite

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .classic: "Classic (original)"
        case .chic: "Chic — pastel & gold"
        case .graphite: "Graphite — dark grey"
        }
    }
}

/// Routes to **Classic** (`ITGirlTheme`) or **Chic** (`ITGirlChicTheme`) without replacing either.
enum ThemeColors {
    static func accent(for scheme: ColorScheme, palette: ColorPaletteID) -> Color {
        switch palette {
        case .classic: ITGirlTheme.accent(for: scheme)
        case .chic: ITGirlChicTheme.accent(for: scheme)
        case .graphite: ITGirlGraphiteTheme.accent(for: scheme)
        }
    }

    static func secondaryAccent(for scheme: ColorScheme, palette: ColorPaletteID) -> Color {
        switch palette {
        case .classic: ITGirlTheme.secondaryAccent(for: scheme)
        case .chic: ITGirlChicTheme.secondaryAccent(for: scheme)
        case .graphite: ITGirlGraphiteTheme.secondaryAccent(for: scheme)
        }
    }

    static func backdropGradient(for scheme: ColorScheme, palette: ColorPaletteID) -> LinearGradient {
        switch palette {
        case .classic: ITGirlTheme.backdropGradient(for: scheme)
        case .chic: ITGirlChicTheme.backdropGradient(for: scheme)
        case .graphite: ITGirlGraphiteTheme.backdropGradient(for: scheme)
        }
    }

    static func cardFill(for scheme: ColorScheme, palette: ColorPaletteID) -> Color {
        switch palette {
        case .classic: ITGirlTheme.cardFill(for: scheme)
        case .chic: ITGirlChicTheme.cardFill(for: scheme)
        case .graphite: ITGirlGraphiteTheme.cardFill(for: scheme)
        }
    }

    static func cardStroke(for scheme: ColorScheme, palette: ColorPaletteID) -> Color {
        switch palette {
        case .classic: ITGirlTheme.cardStroke(for: scheme)
        case .chic: ITGirlChicTheme.cardStroke(for: scheme)
        case .graphite: ITGirlGraphiteTheme.cardStroke(for: scheme)
        }
    }

    static func cardShadow(for scheme: ColorScheme, palette: ColorPaletteID) -> Color {
        switch palette {
        case .classic: ITGirlTheme.cardShadow(for: scheme)
        case .chic: ITGirlChicTheme.cardShadow(for: scheme)
        case .graphite: ITGirlGraphiteTheme.cardShadow(for: scheme)
        }
    }
}

private struct ColorPaletteEnvironmentKey: EnvironmentKey {
    static let defaultValue = ColorPaletteID.graphite
}

extension EnvironmentValues {
    var colorPalette: ColorPaletteID {
        get { self[ColorPaletteEnvironmentKey.self] }
        set { self[ColorPaletteEnvironmentKey.self] = newValue }
    }
}

enum ITGirlGraphiteTheme {
    static func accent(for scheme: ColorScheme) -> Color {
        switch scheme {
        case .dark:
            Color(red: 0.78, green: 0.80, blue: 0.86)
        default:
            Color(red: 0.36, green: 0.40, blue: 0.48)
        }
    }

    static func secondaryAccent(for scheme: ColorScheme) -> Color {
        switch scheme {
        case .dark:
            Color(red: 0.64, green: 0.69, blue: 0.78)
        default:
            Color(red: 0.48, green: 0.54, blue: 0.66)
        }
    }

    static func backdropGradient(for scheme: ColorScheme) -> LinearGradient {
        switch scheme {
        case .dark:
            LinearGradient(
                colors: [
                    Color(red: 0.08, green: 0.09, blue: 0.11),
                    Color(red: 0.11, green: 0.12, blue: 0.15),
                    Color(red: 0.09, green: 0.10, blue: 0.12)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        default:
            LinearGradient(
                colors: [
                    Color(red: 0.96, green: 0.97, blue: 0.98),
                    Color(red: 0.94, green: 0.95, blue: 0.97),
                    Color(red: 0.97, green: 0.98, blue: 0.99)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    static func cardFill(for scheme: ColorScheme) -> Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 0.16, green: 0.17, blue: 0.20, alpha: 0.94)
                : UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.95)
        })
    }

    static func cardStroke(for scheme: ColorScheme) -> Color {
        accent(for: scheme).opacity(scheme == .dark ? 0.34 : 0.22)
    }

    static func cardShadow(for scheme: ColorScheme) -> Color {
        switch scheme {
        case .dark:
            Color.black.opacity(0.5)
        default:
            Color.black.opacity(0.12)
        }
    }
}
