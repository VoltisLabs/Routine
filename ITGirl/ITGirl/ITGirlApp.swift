import SwiftUI

@main
struct ITGirlApp: App {
    @State private var library = RoutineLibrary()
    @AppStorage("itgirl.signedIn") private var signedIn = false
    @AppStorage("itgirl.appearance") private var appearanceRaw = "system"
    @AppStorage("itgirl.colorPalette") private var colorPaletteRaw = ColorPaletteID.graphite.rawValue

    private var preferredScheme: ColorScheme? {
        switch appearanceRaw {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }

    private var colorPalette: ColorPaletteID {
        ColorPaletteID(rawValue: colorPaletteRaw) ?? .classic
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if signedIn {
                    MainTabView()
                } else {
                    AuthWelcomeView()
                }
            }
            .environment(library)
            .environment(\.colorPalette, colorPalette)
            .preferredColorScheme(preferredScheme)
        }
    }
}
