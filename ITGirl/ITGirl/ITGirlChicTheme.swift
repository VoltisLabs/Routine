import SwiftUI
import UIKit

/// **Chic** palette — pastel base + gold accents (product brief).  
/// This is an **additional** theme; it does not replace `ITGirlTheme` (Classic).
enum ITGirlChicTheme {
    // Gold trim (shared reference)
    private static let goldLight = Color(red: 0.72, green: 0.55, blue: 0.20)
    private static let goldDark = Color(red: 0.92, green: 0.78, blue: 0.42)

    static func accent(for scheme: ColorScheme) -> Color {
        switch scheme {
        case .dark: goldDark
        default: goldLight
        }
    }

    static func secondaryAccent(for scheme: ColorScheme) -> Color {
        switch scheme {
        case .dark:
            Color(red: 0.88, green: 0.52, blue: 0.72)
        default:
            Color(red: 0.78, green: 0.42, blue: 0.58)
        }
    }

    static func backdropGradient(for scheme: ColorScheme) -> LinearGradient {
        switch scheme {
        case .dark:
            LinearGradient(
                colors: [
                    Color(red: 0.09, green: 0.08, blue: 0.11),
                    Color(red: 0.12, green: 0.09, blue: 0.13),
                    Color(red: 0.08, green: 0.07, blue: 0.12)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        default:
            LinearGradient(
                colors: [
                    Color(red: 0.99, green: 0.97, blue: 0.94),
                    Color(red: 0.98, green: 0.94, blue: 0.97),
                    Color(red: 0.94, green: 0.98, blue: 0.96)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    static func cardFill(for scheme: ColorScheme) -> Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 0.16, green: 0.14, blue: 0.18, alpha: 0.94)
                : UIColor(red: 1.0, green: 0.995, blue: 0.98, alpha: 0.96)
        })
    }

    static func cardStroke(for scheme: ColorScheme) -> Color {
        accent(for: scheme).opacity(scheme == .dark ? 0.42 : 0.28)
    }

    static func cardShadow(for scheme: ColorScheme) -> Color {
        switch scheme {
        case .dark:
            Color.black.opacity(0.5)
        default:
            Color(red: 0.45, green: 0.38, blue: 0.30, opacity: 0.14)
        }
    }
}
