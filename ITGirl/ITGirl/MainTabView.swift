import SwiftUI

struct MainTabView: View {
    @Environment(RoutineLibrary.self) private var library
    @Environment(\.colorPalette) private var colorPalette
    @State private var selectedTab = 0
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        TabView(selection: $selectedTab) {
            DiscoverView()
                .tabItem { Label("Discover", systemImage: "sparkle.magnifyingglass") }
                .tag(0)

            NavigationStack {
                MessagesView()
            }
            .tabItem { Label("Messages", systemImage: "bubble.left.and.bubble.right") }
            .tag(1)

            CreateRoutineView()
                .tabItem { Label("Create", systemImage: "square.and.pencil") }
                .tag(2)

            MyRoutinesView()
                .tabItem { Label("Mine", systemImage: "person.crop.circle") }
                .tag(3)

            AccountView()
                .tabItem { Label("You", systemImage: "heart.circle") }
                .tag(4)
        }
        .tint(ThemeColors.accent(for: scheme, palette: colorPalette))
        .sensoryFeedback(.selection, trigger: selectedTab)
    }
}
