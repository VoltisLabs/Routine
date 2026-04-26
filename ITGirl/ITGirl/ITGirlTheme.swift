import SwiftUI
import UIKit

/// **Classic** IT Girl palette — unchanged since the first draft.  
/// For the alternate “Chic” look, see `ITGirlChicTheme` and `ThemeColors`.
enum ITGirlTheme {
    // MARK: - Adaptive accents (Classic)

    static func accent(for scheme: ColorScheme) -> Color {
        switch scheme {
        case .dark:
            Color(red: 0.98, green: 0.62, blue: 0.78)
        default:
            Color(red: 0.76, green: 0.28, blue: 0.48)
        }
    }

    static func secondaryAccent(for scheme: ColorScheme) -> Color {
        switch scheme {
        case .dark:
            Color(red: 0.72, green: 0.58, blue: 0.98)
        default:
            Color(red: 0.58, green: 0.42, blue: 0.86)
        }
    }

    // MARK: - Screen backdrop (Classic)

    static func backdropGradient(for scheme: ColorScheme) -> LinearGradient {
        switch scheme {
        case .dark:
            LinearGradient(
                colors: [
                    Color(red: 0.12, green: 0.06, blue: 0.14),
                    Color(red: 0.10, green: 0.08, blue: 0.18),
                    Color(red: 0.08, green: 0.06, blue: 0.14)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        default:
            LinearGradient(
                colors: [
                    Color(red: 1.0, green: 0.93, blue: 0.96),
                    Color(red: 0.96, green: 0.90, blue: 1.0),
                    Color(red: 0.98, green: 0.94, blue: 1.0)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    static func cardFill(for scheme: ColorScheme) -> Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 0.18, green: 0.12, blue: 0.22, alpha: 0.92)
                : UIColor(red: 1.0, green: 0.98, blue: 1.0, alpha: 0.94)
        })
    }

    static func cardStroke(for scheme: ColorScheme) -> Color {
        accent(for: scheme).opacity(scheme == .dark ? 0.35 : 0.22)
    }

    static func cardShadow(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color.black.opacity(0.45) : Color(red: 0.55, green: 0.35, blue: 0.55, opacity: 0.18)
    }
}
