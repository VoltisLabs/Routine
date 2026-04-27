import SwiftUI
import UIKit
import PhotosUI

// MARK: - Discover

private enum DiscoverMode: String, CaseIterable {
    case feed = "Feed"
    case browse = "Browse"
}

private enum BrowseViewMode: String, CaseIterable {
    case list = "List"
    case cards = "Cards"
}

struct DiscoverView: View {
    @Environment(RoutineLibrary.self) private var library
    @Environment(\.colorScheme) private var scheme
    @Environment(\.colorPalette) private var colorPalette
    @AppStorage("itgirl.playfulAnimations") private var playfulAnimations = true
    @State private var query = ""
    @State private var discoverMode: DiscoverMode = .feed
    @State private var browseViewMode: BrowseViewMode = .list

    private var results: [Routine] {
        library.routinesMatchingSearch(query)
    }

    var body: some View {
        ZStack {
            ItGirlScreenBackdrop()
            NavigationStack {
                VStack(spacing: 0) {
                    Picker("View", selection: $discoverMode) {
                        ForEach(DiscoverMode.allCases, id: \.rawValue) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    .padding(.top, 8)
                    .padding(.bottom, 4)

                    Group {
                        if discoverMode == .feed {
                            RoutineFeedScroll()
                        } else {
                            Group {
                                if browseViewMode == .list {
                                    List(results) { routine in
                                        NavigationLink(value: routine) {
                                            RoutineRowView(routine: routine)
                                        }
                                        .listRowSeparator(.hidden)
                                        .listRowInsets(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
                                        .listRowBackground(Color.clear)
                                    }
                                    .listStyle(.plain)
                                    .scrollContentBackground(.hidden)
                                } else {
                                    ScrollView {
                                        LazyVStack(spacing: 14) {
                                            ForEach(results) { routine in
                                                NavigationLink(value: routine) {
                                                    RoutineBrowseCardView(routine: routine)
                                                }
                                                .buttonStyle(.plain)
                                            }
                                        }
                                        .padding(.vertical, 10)
                                        .padding(.bottom, 24)
                                    }
                                }
                            }
                            .searchable(text: $query, prompt: "Search routines")
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .navigationTitle("Discover")
                .navigationBarTitleDisplayMode(.inline)
                .navigationDestination(for: Routine.self) { routine in
                    RoutineDetailView(routine: routine, context: .community)
                }
                .toolbar {
                    if discoverMode == .browse {
                        ToolbarItem(placement: .topBarTrailing) {
                            Menu {
                                Button {
                                    browseViewMode = .list
                                } label: {
                                    Label("List", systemImage: browseViewMode == .list ? "checkmark" : "list.bullet")
                                }
                                Button {
                                    browseViewMode = .cards
                                } label: {
                                    Label("Cards", systemImage: browseViewMode == .cards ? "checkmark" : "rectangle.grid.1x2")
                                }
                            } label: {
                                Image(systemName: browseViewMode == .list ? "list.bullet" : "rectangle.grid.1x2")
                            }
                        }
                    }
                }
                .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            }
        }
        .itGirlAppearAnimation(playful: playfulAnimations)
    }
}

struct RoutineRowView: View {
    let routine: Routine
    @Environment(\.colorScheme) private var scheme
    @Environment(\.colorPalette) private var colorPalette

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 12) {
                BrowseRoutineThumbnail(routine: routine)
                    .frame(width: 82, height: 82)

                VStack(alignment: .leading, spacing: 6) {
                    Text(routine.title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    HStack(spacing: 8) {
                        Text(routine.authorDisplayName)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Spacer(minLength: 0)
                        Text(routine.isPaywalled ? routine.displayUnlockPriceGBP : "Free")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(routine.isPaywalled ? .orange : .green)
                    }
                    HStack(spacing: 8) {
                        Text("\(routine.stepCount) steps")
                            .font(.footnote.weight(.medium))
                            .foregroundStyle(.tertiary)
                        Text("•")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                        Text("★★★★☆ (\(routine.browseReviewCount))")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.yellow)
                    }
                    Text(routine.displayKindTitle)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(ThemeColors.accent(for: scheme, palette: colorPalette))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(ThemeColors.accent(for: scheme, palette: colorPalette).opacity(scheme == .dark ? 0.2 : 0.12))
                        )
                }
                Spacer(minLength: 0)
            }
            .padding(.vertical, 2)

            Divider()
                .overlay(ThemeColors.cardStroke(for: scheme, palette: colorPalette).opacity(0.7))
                .padding(.top, 10)
        }
    }
}

private extension Routine {
    var browseReviewCount: Int {
        let seed = abs(title.hashValue % 240) + 24
        return seed
    }
}

private struct RoutineBrowseCardView: View {
    let routine: Routine
    @Environment(\.colorScheme) private var scheme
    @Environment(\.colorPalette) private var colorPalette

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            RoutineCoverStrip(routine: routine, height: 160, cornerRadius: 20)

            Text(routine.title)
                .font(.title3.weight(.semibold))
                .foregroundStyle(.primary)

            Text(routine.feedPreview)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(2)

            HStack(spacing: 8) {
                Label(routine.authorDisplayName, systemImage: "person.crop.circle.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer(minLength: 8)
                Text(routine.displayKindTitle)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(ThemeColors.accent(for: scheme, palette: colorPalette))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(ThemeColors.accent(for: scheme, palette: colorPalette).opacity(scheme == .dark ? 0.2 : 0.12))
                    )
                Text(routine.isPaywalled ? routine.displayUnlockPriceGBP : "Free")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(routine.isPaywalled ? .orange : .green)
            }
        }
        .padding(16)
        .background(ThemeColors.cardFill(for: scheme, palette: colorPalette), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(ThemeColors.cardStroke(for: scheme, palette: colorPalette), lineWidth: 0.5)
        }
        .shadow(color: ThemeColors.cardShadow(for: scheme, palette: colorPalette), radius: 10, y: 4)
        .padding(.horizontal)
    }
}

private struct BrowseRoutineThumbnail: View {
    let routine: Routine
    private let corner: CGFloat = 14

    var body: some View {
        let firstId = routine.imageAttachmentIds.first
        let firstRemote = routine.remoteCoverImageURLs.first.flatMap(URL.init(string:))
        Group {
            if let id = firstId, let data = RoutineImageStore.shared.loadData(id: id), let ui = UIImage(data: data) {
                Image(uiImage: ui)
                    .resizable()
                    .scaledToFill()
            } else if let u = firstRemote {
                AsyncImage(url: u) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    case .failure:
                        fallback
                    default:
                        fallback
                    }
                }
            } else {
                fallback
            }
        }
        .frame(width: 96, height: 96)
        .clipped()
        .clipShape(RoundedRectangle(cornerRadius: corner, style: .continuous))
    }

    private var fallback: some View {
        ZStack {
            LinearGradient(colors: [.gray.opacity(0.4), .gray.opacity(0.25)], startPoint: .topLeading, endPoint: .bottomTrailing)
            Image(systemName: routine.kind.symbolName)
                .font(.title3)
                .foregroundStyle(.white.opacity(0.7))
        }
    }
}

// MARK: - Detail

enum RoutineDetailContext {
    case community
    case mine
    case saved
}

struct RoutineDetailView: View {
    @Environment(RoutineLibrary.self) private var library
    @Environment(\.colorScheme) private var scheme
    @Environment(\.colorPalette) private var colorPalette
    @AppStorage("itgirl.playfulAnimations") private var playfulAnimations = true
    let routine: Routine
    var context: RoutineDetailContext

    @State private var sharePayload: String?
    @State private var checkoutError = ""
    @State private var showCheckoutError = false
    @State private var checkoutInFlight = false
    @AppStorage("itgirl.authToken") private var authToken = ""
    @Environment(\.openURL) private var openURL
    @Environment(\.dismiss) private var dismiss

    private var remoteGalleryTail: [String] {
        if routine.imageAttachmentIds.isEmpty {
            Array(routine.remoteCoverImageURLs.dropFirst())
        } else {
            routine.remoteCoverImageURLs
        }
    }

    private var isLocked: Bool {
        context == .community && routine.isPaywalled && !library.canAccessPaidRoutine(routine)
    }

    var body: some View {
        ZStack {
            ItGirlScreenBackdrop()
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    RoutineCoverStrip(routine: routine, height: 220, cornerRadius: 22)

                    if isLocked {
                        ItGirlCard {
                            VStack(alignment: .leading, spacing: 12) {
                                Label("Premium routine", systemImage: "lock.fill")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.orange)
                                Text("Unlock for \(routine.displayUnlockPriceGBP) to view all steps and keep this routine in your account.")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                                Button {
                                    beginCheckout()
                                } label: {
                                    Label(checkoutInFlight ? "Opening payment..." : "Unlock now", systemImage: "creditcard.fill")
                                }
                                .disabled(checkoutInFlight)
                                .buttonStyle(LiquidGlassPrimaryButtonStyle(accent: ThemeColors.accent(for: scheme, palette: colorPalette)))
                            }
                        }
                    } else {
                        RoutineDetailInstrumentStrip(routine: routine)

                        RoutineDetailSignalRack(routine: routine)

                        RoutineDetailDurationTimeline(routine: routine)

                        HStack {
                            Label(routine.displayKindTitle, systemImage: routine.kind.symbolName)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(ThemeColors.accent(for: scheme, palette: colorPalette))
                            Spacer()
                            Text(routine.createdAt.formatted(date: .abbreviated, time: .omitted))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Text("by \(routine.authorDisplayName)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        if routine.imageAttachmentIds.count > 1 {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("LOCAL ROLL")
                                    .font(.caption2.weight(.heavy))
                                    .foregroundStyle(.tertiary)
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 10) {
                                        ForEach(routine.imageAttachmentIds, id: \.self) { imgId in
                                            if let data = RoutineImageStore.shared.loadData(id: imgId), let ui = UIImage(data: data) {
                                                Image(uiImage: ui)
                                                    .resizable()
                                                    .scaledToFill()
                                                    .frame(width: 88, height: 88)
                                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                                    .overlay {
                                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                            .strokeBorder(
                                                                ThemeColors.cardStroke(for: scheme, palette: colorPalette),
                                                                lineWidth: 0.5
                                                            )
                                                    }
                                            }
                                        }
                                    }
                                    .padding(.horizontal, 4)
                                }
                            }
                        }

                        RoutineRemoteGalleryStrip(urls: remoteGalleryTail)

                        VStack(alignment: .leading, spacing: 16) {
                            ForEach(Array(routine.resolvedSteps.enumerated()), id: \.element.id) { index, step in
                                RoutineDetailStepCard(
                                    step: step,
                                    stepNumber: index + 1,
                                    durationTotal: routine.resolvedTotalDurationMinutes
                                )
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, ITGirlLayoutMetrics.scrollContentHorizontalInset)
                .padding(.vertical)
            }
        }
        .navigationTitle(routine.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                if context == .community {
                    if isLocked {
                        Button {
                            beginCheckout()
                        } label: {
                            Label(checkoutInFlight ? "Opening..." : "Buy", systemImage: "lock.open.fill")
                        }
                        .disabled(checkoutInFlight)
                    } else {
                        Button {
                            if playfulAnimations {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.72)) {
                                    library.saveRoutineToAccount(routine)
                                }
                            } else {
                                library.saveRoutineToAccount(routine)
                            }
                        } label: {
                            Label(
                                library.isSaved(routine) ? "Saved" : "Save",
                                systemImage: library.isSaved(routine) ? "bookmark.fill" : "bookmark"
                            )
                        }
                        .disabled(library.isSaved(routine))
                    }
                }

                Button {
                    sharePayload = routine.shareablePlainText(currentUserName: library.displayName)
                } label: {
                    Label("Share", systemImage: "square.and.arrow.up")
                }

                if context == .mine {
                    NavigationLink("Edit") {
                        EditRoutineView(routine: routine)
                    }
                }
            }

            if context == .mine {
                ToolbarItem(placement: .bottomBar) {
                    Button(role: .destructive) {
                        library.deleteMyRoutine(id: routine.id)
                        dismiss()
                    } label: {
                        Label("Delete routine", systemImage: "trash")
                    }
                }
            }

            if context == .saved {
                ToolbarItem(placement: .bottomBar) {
                    Button(role: .destructive) {
                        library.removeSaved(id: routine.id)
                        dismiss()
                    } label: {
                        Label("Remove from saved", systemImage: "bookmark.slash")
                    }
                }
            }
        }
        .sheet(item: Binding(
            get: { sharePayload.map { ShareItem(text: $0) } },
            set: { _ in sharePayload = nil }
        )) { item in
            ShareSheet(activityItems: [item.text])
        }
        .alert("Couldn’t open payment", isPresented: $showCheckoutError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(checkoutError)
        }
    }

    private func beginCheckout() {
        checkoutInFlight = true
        Task {
            do {
                let url = try await VoltisGraphQLClient.shared.createStripeCheckoutURL(
                    for: routine,
                    bearerToken: authToken.isEmpty ? nil : authToken
                )
                await MainActor.run {
                    checkoutInFlight = false
                    openURL(url)
                }
            } catch {
                await MainActor.run {
                    checkoutInFlight = false
                    checkoutError = error.localizedDescription
                    showCheckoutError = true
                }
            }
        }
    }
}

private struct ShareItem: Identifiable {
    let id = UUID()
    let text: String
}

// MARK: - Mine

struct MyRoutinesView: View {
    @Environment(RoutineLibrary.self) private var library
    @Environment(\.colorScheme) private var scheme
    @Environment(\.colorPalette) private var colorPalette
    @AppStorage("itgirl.playfulAnimations") private var playfulAnimations = true

    var body: some View {
        ZStack {
            ItGirlScreenBackdrop()
            NavigationStack {
                Group {
                    if library.myRoutines.isEmpty {
                        ContentUnavailableView(
                            "No routines yet",
                            systemImage: "square.and.pencil",
                            description: Text("Create a routine and publish it to see it here.")
                        )
                        .tint(ThemeColors.accent(for: scheme, palette: colorPalette))
                    } else {
                        List(library.myRoutines) { routine in
                            NavigationLink(value: routine) {
                                RoutineRowView(routine: routine)
                            }
                            .listRowBackground(myListRowChrome)
                        }
                        .itGirlListChrome()
                        .listStyle(.insetGrouped)
                    }
                }
                .navigationTitle("Mine")
                .navigationBarTitleDisplayMode(.inline)
                .navigationDestination(for: Routine.self) { routine in
                    RoutineDetailView(routine: routine, context: .mine)
                }
                .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            }
        }
        .itGirlAppearAnimation(playful: playfulAnimations)
    }

    private var myListRowChrome: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(ThemeColors.cardFill(for: scheme, palette: colorPalette))
            .shadow(color: ThemeColors.cardShadow(for: scheme, palette: colorPalette), radius: 8, y: 3)
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(ThemeColors.cardStroke(for: scheme, palette: colorPalette), lineWidth: 0.5)
            }
            .padding(.vertical, 3)
    }
}

// MARK: - Saved

struct SavedRoutinesView: View {
    @Environment(RoutineLibrary.self) private var library
    @Environment(\.colorScheme) private var scheme
    @Environment(\.colorPalette) private var colorPalette
    @AppStorage("itgirl.playfulAnimations") private var playfulAnimations = true

    var body: some View {
        ZStack {
            ItGirlScreenBackdrop()
            NavigationStack {
                Group {
                    if library.savedRoutines.isEmpty {
                        ContentUnavailableView(
                            "Nothing saved",
                            systemImage: "bookmark",
                            description: Text("Open a routine from Discover and tap Save to keep it on this account.")
                        )
                        .tint(ThemeColors.accent(for: scheme, palette: colorPalette))
                    } else {
                        List(library.savedRoutines) { routine in
                            NavigationLink(value: routine) {
                                RoutineRowView(routine: routine)
                            }
                            .listRowBackground(savedListRowChrome)
                        }
                        .itGirlListChrome()
                        .listStyle(.insetGrouped)
                    }
                }
                .navigationTitle("Saved")
                .navigationDestination(for: Routine.self) { routine in
                    RoutineDetailView(routine: routine, context: .saved)
                }
                .toolbar(.hidden, for: .tabBar)
                .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            }
        }
        .itGirlAppearAnimation(playful: playfulAnimations)
    }

    private var savedListRowChrome: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(ThemeColors.cardFill(for: scheme, palette: colorPalette))
            .shadow(color: ThemeColors.cardShadow(for: scheme, palette: colorPalette), radius: 8, y: 3)
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(ThemeColors.cardStroke(for: scheme, palette: colorPalette), lineWidth: 0.5)
            }
            .padding(.vertical, 3)
    }
}

// MARK: - Account

struct AccountView: View {
    @Environment(RoutineLibrary.self) private var library
    @Environment(\.colorScheme) private var scheme
    @Environment(\.colorPalette) private var colorPalette
    @AppStorage("itgirl.playfulAnimations") private var playfulAnimations = true
    @AppStorage("itgirl.authToken") private var authToken = ""
    @State private var photoPickerItem: PhotosPickerItem?
    @State private var photoUploadError = ""
    @State private var showPhotoUploadError = false

    var body: some View {
        @Bindable var library = library
        ZStack {
            ItGirlScreenBackdrop()
            NavigationStack {
                ScrollView {
                    VStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 14) {
                            HStack(alignment: .top, spacing: 14) {
                                ZStack(alignment: .bottomTrailing) {
                                    Group {
                                        if let data = library.profilePhotoData, let image = UIImage(data: data) {
                                            Image(uiImage: image)
                                                .resizable()
                                                .scaledToFill()
                                        } else {
                                            AsyncImage(url: URL(string: library.profilePhotoURL)) { phase in
                                                switch phase {
                                                case .success(let image):
                                                    image.resizable().scaledToFill()
                                                default:
                                                    Image(systemName: "person.crop.circle.fill")
                                                        .resizable()
                                                        .scaledToFit()
                                                        .padding(10)
                                                        .foregroundStyle(.secondary)
                                                }
                                            }
                                        }
                                    }
                                    .frame(width: 76, height: 76)
                                    .background(.ultraThinMaterial)
                                    .clipShape(Circle())

                                    PhotosPicker(selection: $photoPickerItem, matching: .images, photoLibrary: .shared()) {
                                        Image(systemName: "camera.fill")
                                            .font(.caption.weight(.bold))
                                            .padding(6)
                                            .background(.ultraThinMaterial, in: Circle())
                                    }
                                    .onChange(of: photoPickerItem) { _, item in
                                        guard let item else { return }
                                        Task { await uploadProfilePhoto(item) }
                                    }
                                }

                                VStack(alignment: .leading, spacing: 8) {
                                    TextField("Display name", text: $library.displayName)
                                        .font(.headline.weight(.semibold))
                                    HStack(spacing: 20) {
                                        profileCount("Routines", value: library.myRoutines.count)
                                        profileCount("Followers", value: library.followers.count)
                                        profileCount("Following", value: library.following.count)
                                    }
                                }
                            }

                            VStack(alignment: .leading, spacing: 8) {
                                if library.reviews.isEmpty {
                                    Text("No reviews yet.")
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                } else {
                                    NavigationLink(value: AccountMenuRoute.reviews) {
                                        HStack {
                                            Text("★★★★★ (\(library.reviews.count))")
                                                .font(.subheadline.weight(.semibold))
                                                .foregroundStyle(.yellow)
                                            Spacer()
                                            Image(systemName: "chevron.right")
                                                .font(.caption.weight(.semibold))
                                                .foregroundStyle(.secondary)
                                        }
                                        .padding(.vertical, 4)
                                    }
                                }
                            }
                            VStack(alignment: .leading, spacing: 6) {
                                Text(library.bio.isEmpty ? "No bio yet." : library.bio)
                                    .font(.body)
                                    .foregroundStyle(library.bio.isEmpty ? .secondary : .primary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                Divider()
                                    .overlay(ThemeColors.cardStroke(for: scheme, palette: colorPalette).opacity(0.7))
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding()
                    .padding(.bottom, 24)
                }
                .navigationTitle("You")
                .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        NavigationLink(value: AccountMenuRoute.menu) {
                            Image(systemName: "ellipsis.circle.fill")
                                .font(.body.weight(.semibold))
                                .symbolRenderingMode(.hierarchical)
                                .foregroundStyle(ThemeColors.accent(for: scheme, palette: colorPalette))
                        }
                        .accessibilityLabel("Menu")
                    }
                }
                .navigationDestination(for: AccountMenuRoute.self) { route in
                    switch route {
                    case .menu:
                        AccountMenuView()
                    case .stats:
                        AccountStatsSheet()
                    case .saved:
                        SavedRoutinesView()
                    case .about:
                        AccountAboutSheet()
                    case .settings:
                        SettingsView()
                    case .signIn:
                        SignInView()
                    case .signUp:
                        SignUpView()
                    case .reviews:
                        ProfileReviewsView()
                    }
                }
            }
        }
        .itGirlAppearAnimation(playful: playfulAnimations)
        .alert("Couldn’t upload photo", isPresented: $showPhotoUploadError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(photoUploadError)
        }
    }

    @ViewBuilder
    private func profileCount(_ label: String, value: Int) -> some View {
        VStack(spacing: 2) {
            Text("\(value)")
                .font(.headline.weight(.bold))
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    @MainActor
    private func uploadProfilePhoto(_ item: PhotosPickerItem) async {
        guard let data = try? await item.loadTransferable(type: Data.self), !data.isEmpty else { return }
        library.profilePhotoData = data
        do {
            let uploaded = try await VoltisGraphQLClient.shared.uploadProfilePhoto(
                data,
                bearerToken: authToken.isEmpty ? nil : authToken
            )
            library.profilePhotoURL = uploaded
        } catch {
            photoUploadError = error.localizedDescription
            showPhotoUploadError = true
        }
    }
}

private enum AccountMenuRoute: Hashable {
    case menu
    case stats
    case saved
    case about
    case settings
    case signIn
    case signUp
    case reviews
}

private struct AccountMenuView: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.colorPalette) private var colorPalette
    @AppStorage("itgirl.signedIn") private var signedIn = false
    @AppStorage("itgirl.authToken") private var authToken = ""
    @AppStorage("itgirl.refreshToken") private var refreshToken = ""

    var body: some View {
        ZStack {
            ItGirlScreenBackdrop()
            List {
            NavigationLink(value: AccountMenuRoute.stats) {
                Label("Stats", systemImage: "chart.bar.fill")
            }
            NavigationLink(value: AccountMenuRoute.saved) {
                Label("Saved", systemImage: "bookmark.fill")
            }
            NavigationLink(value: AccountMenuRoute.about) {
                Label("About", systemImage: "info.circle")
            }
            if signedIn {
                Button(role: .destructive) {
                    authToken = ""
                    refreshToken = ""
                    signedIn = false
                } label: {
                    Label("Log out", systemImage: "rectangle.portrait.and.arrow.right")
                }
            }
            }
            .listStyle(.insetGrouped)
            .itGirlListChrome()
            .scrollContentBackground(.hidden)
            .tint(ThemeColors.accent(for: scheme, palette: colorPalette))
        }
        .navigationTitle("Menu")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink(value: AccountMenuRoute.settings) {
                    Image(systemName: "gearshape.fill")
                        .font(.body.weight(.semibold))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(ThemeColors.accent(for: scheme, palette: colorPalette))
                }
                .accessibilityLabel("Settings")
            }
        }
    }
}

private struct ProfileReviewsView: View {
    @Environment(RoutineLibrary.self) private var library
    @Environment(\.colorScheme) private var scheme
    @Environment(\.colorPalette) private var colorPalette

    var body: some View {
        ZStack {
            ItGirlScreenBackdrop()
            if library.reviews.isEmpty {
                ContentUnavailableView(
                    "No reviews yet",
                    systemImage: "star",
                    description: Text("Your rating summary will appear here as people leave feedback.")
                )
            } else {
                List(library.reviews) { review in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(review.reviewerName)
                                .font(.subheadline.weight(.semibold))
                            Spacer()
                            Text(String(repeating: "★", count: review.rating))
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.yellow)
                        }
                        Text(review.text)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
                .listStyle(.insetGrouped)
                .itGirlListChrome()
                .scrollContentBackground(.hidden)
            }
        }
        .tint(ThemeColors.accent(for: scheme, palette: colorPalette))
        .navigationTitle("Reviews")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }
}

// MARK: - Settings

struct MessagesView: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.colorPalette) private var colorPalette

    private let threads: [MessageThread] = [
        MessageThread(
            name: "Noa",
            preview: "Can you drop your morning routine template?",
            avatarURL: "https://images.unsplash.com/photo-1544005313-94ddf0286df2?auto=format&fit=crop&w=256&q=80",
            timeText: "10:42"
        ),
        MessageThread(
            name: "Mara",
            preview: "Loved your skincare steps. Sharing with my group.",
            avatarURL: "https://images.unsplash.com/photo-1546961329-78bef0414d7c?auto=format&fit=crop&w=256&q=80",
            timeText: "09:18"
        ),
        MessageThread(
            name: "Kai",
            preview: "New HIIT plan posted. Want early access?",
            avatarURL: "https://images.unsplash.com/photo-1504593811423-6dd665756598?auto=format&fit=crop&w=256&q=80",
            timeText: "Yesterday"
        )
    ]

    var body: some View {
        ZStack {
            ItGirlScreenBackdrop()
            List(threads) { thread in
                NavigationLink(value: thread) {
                    HStack(alignment: .top, spacing: 10) {
                        AsyncImage(url: URL(string: thread.avatarURL)) { phase in
                            switch phase {
                            case .success(let image):
                                image.resizable().scaledToFill()
                            default:
                                Image(systemName: "person.crop.circle.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .padding(7)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .frame(width: 42, height: 42)
                        .background(.ultraThinMaterial, in: Circle())
                        .clipShape(Circle())

                        VStack(alignment: .leading, spacing: 4) {
                            HStack(alignment: .firstTextBaseline) {
                                Text(thread.name)
                                    .font(.headline)
                                Spacer()
                                Text(thread.timeText)
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            }
                            Text(thread.preview)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .listStyle(.insetGrouped)
            .itGirlListChrome()
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Messages")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: MessageThread.self) { thread in
            MessageThreadDetailView(thread: thread)
        }
        .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .tint(ThemeColors.accent(for: scheme, palette: colorPalette))
    }
}

private struct MessageThread: Identifiable, Hashable {
    let id: String
    let name: String
    let preview: String
    let avatarURL: String
    let timeText: String

    init(name: String, preview: String, avatarURL: String, timeText: String) {
        self.id = name
        self.name = name
        self.preview = preview
        self.avatarURL = avatarURL
        self.timeText = timeText
    }
}

private struct MessageThreadDetailView: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.colorPalette) private var colorPalette
    let thread: MessageThread
    @State private var draft = ""
    @State private var messages: [String]

    init(thread: MessageThread) {
        self.thread = thread
        _messages = State(initialValue: [thread.preview])
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(Array(messages.enumerated()), id: \.offset) { index, text in
                        HStack {
                            if index % 2 == 0 {
                                Text(text)
                                    .font(.footnote)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 10)
                                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                                Spacer()
                            } else {
                                Spacer()
                                Text(text)
                                    .font(.footnote)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 10)
                                    .background(ThemeColors.accent(for: scheme, palette: colorPalette).opacity(0.18), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                            }
                        }
                    }
                }
                .padding()
            }

            HStack(spacing: 10) {
                TextField("Type a message…", text: $draft)
                    .textInputAutocapitalization(.sentences)
                    .itGirlRoundedField()
                Button {
                    let text = draft.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !text.isEmpty else { return }
                    messages.append(text)
                    draft = ""
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                }
                .buttonStyle(.plain)
            }
            .padding()
            .background(.ultraThinMaterial)
        }
        .background(ItGirlScreenBackdrop())
        .navigationTitle(thread.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .tint(ThemeColors.accent(for: scheme, palette: colorPalette))
    }
}

private struct AccountStatsSheet: View {
    @Environment(RoutineLibrary.self) private var library

    var body: some View {
        List {
            LabeledContent("Published", value: "\(library.myRoutines.count)")
            LabeledContent("Purchased", value: "\(library.purchasedRoutineSourceIDs.count)")
            LabeledContent("Saved", value: "\(library.savedRoutines.count)")
            LabeledContent("Discover feed", value: "\(library.communityRoutines.count)")
        }
        .navigationTitle("Stats")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }
}

private struct AccountAboutSheet: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                ItGirlCard {
                    Text("A simple home for routines and GRWMs: write in plain text, search the feed, save favorites, and share anywhere.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
        }
        .navigationTitle("About IT Girl")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }
}

// MARK: - Auth (launch)

struct AuthWelcomeView: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.colorPalette) private var colorPalette

    var body: some View {
        ZStack {
            ItGirlScreenBackdrop()
            NavigationStack {
                VStack(spacing: 0) {
                    Spacer(minLength: 12)

                    VStack(spacing: 20) {
                        Image(systemName: "heart.circle.fill")
                            .font(.system(size: 64))
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [
                                        ThemeColors.accent(for: scheme, palette: colorPalette),
                                        ThemeColors.secondaryAccent(for: scheme, palette: colorPalette)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: ThemeColors.cardShadow(for: scheme, palette: colorPalette), radius: 12, y: 6)

                        VStack(spacing: 6) {
                            Text("IT Girl")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                            Text("Voltis Labs")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.secondary)
                        }

                        Text("Routines, GRWM, and a feed you actually want to open.")
                            .font(.body)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 28)
                    }
                    .frame(maxWidth: .infinity)

                    Spacer()
                    Spacer()

                    VStack(spacing: 12) {
                        NavigationLink {
                            SignInView()
                        } label: {
                            Text("Sign in")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(ThemeColors.accent(for: scheme, palette: colorPalette), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                                .foregroundStyle(.white)
                        }
                        .buttonStyle(.plain)

                        NavigationLink {
                            SignUpView()
                        } label: {
                            Text("Create account")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(ThemeColors.cardFill(for: scheme, palette: colorPalette), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                                .overlay {
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .strokeBorder(ThemeColors.cardStroke(for: scheme, palette: colorPalette), lineWidth: 1)
                                }
                                .foregroundStyle(.primary)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, ITGirlLayoutMetrics.scrollContentHorizontalInset)
                    .padding(.bottom, 36)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .navigationBarTitleDisplayMode(.inline)
            }
        }
    }
}

struct SignInView: View {
    @Environment(RoutineLibrary.self) private var library
    @Environment(\.colorScheme) private var scheme
    @Environment(\.colorPalette) private var colorPalette
    @AppStorage("itgirl.signedIn") private var signedIn = false
    @AppStorage("itgirl.authToken") private var authToken = ""
    @AppStorage("itgirl.refreshToken") private var refreshToken = ""
    @State private var username = ""
    @State private var password = ""
    @State private var isSubmitting = false
    @State private var authError = ""
    @State private var showAuthError = false

    var body: some View {
        ZStack {
            ItGirlScreenBackdrop()
            Form {
                Section("Sign In") {
                    TextField("Username", text: $username)
                        .textInputAutocapitalization(.never)
                    SecureField("Password", text: $password)
                    Button(isSubmitting ? "Signing in..." : "Sign In") {
                        signIn()
                    }
                    .disabled(isSubmitting || username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || password.isEmpty)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .scrollContentBackground(.hidden)
        }
        .tint(ThemeColors.accent(for: scheme, palette: colorPalette))
        .navigationTitle("Sign In")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .alert("Sign-in failed", isPresented: $showAuthError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(authError)
        }
    }

    private func signIn() {
        isSubmitting = true
        Task {
            do {
                let session = try await VoltisGraphQLClient.shared.signIn(
                    username: username.trimmingCharacters(in: .whitespacesAndNewlines),
                    password: password
                )
                await MainActor.run {
                    library.applyAuthSession(session)
                    authToken = session.token
                    refreshToken = session.refreshToken
                    signedIn = true
                    isSubmitting = false
                }
            } catch {
                await MainActor.run {
                    isSubmitting = false
                    authError = error.localizedDescription
                    showAuthError = true
                }
            }
        }
    }
}

struct SignUpView: View {
    @Environment(RoutineLibrary.self) private var library
    @Environment(\.colorScheme) private var scheme
    @Environment(\.colorPalette) private var colorPalette
    @AppStorage("itgirl.signedIn") private var signedIn = false
    @AppStorage("itgirl.authToken") private var authToken = ""
    @AppStorage("itgirl.refreshToken") private var refreshToken = ""
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var username = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isSubmitting = false
    @State private var authError = ""
    @State private var showAuthError = false

    var body: some View {
        ZStack {
            ItGirlScreenBackdrop()
            Form {
                Section("Create account") {
                    TextField("First name", text: $firstName)
                    TextField("Last name", text: $lastName)
                    TextField("Username", text: $username)
                        .textInputAutocapitalization(.never)
                    TextField("Email", text: $email)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                    SecureField("Password", text: $password)
                    SecureField("Confirm password", text: $confirmPassword)
                    Button(isSubmitting ? "Creating account..." : "Create account") {
                        signUp()
                    }
                    .disabled(
                        isSubmitting
                            || firstName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                            || lastName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                            || username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                            || email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                            || password.isEmpty
                            || password != confirmPassword
                    )
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .scrollContentBackground(.hidden)
        }
        .tint(ThemeColors.accent(for: scheme, palette: colorPalette))
        .navigationTitle("Sign Up")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .alert("Sign-up failed", isPresented: $showAuthError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(authError)
        }
    }

    private func signUp() {
        guard password == confirmPassword else {
            authError = "Passwords do not match."
            showAuthError = true
            return
        }
        isSubmitting = true
        Task {
            do {
                let session = try await VoltisGraphQLClient.shared.signUp(
                    firstName: firstName.trimmingCharacters(in: .whitespacesAndNewlines),
                    lastName: lastName.trimmingCharacters(in: .whitespacesAndNewlines),
                    username: username.trimmingCharacters(in: .whitespacesAndNewlines),
                    email: email.trimmingCharacters(in: .whitespacesAndNewlines),
                    password: password
                )
                await MainActor.run {
                    library.applyAuthSession(session)
                    authToken = session.token
                    refreshToken = session.refreshToken
                    signedIn = true
                    isSubmitting = false
                }
            } catch {
                await MainActor.run {
                    isSubmitting = false
                    authError = error.localizedDescription
                    showAuthError = true
                }
            }
        }
    }
}

struct SettingsView: View {
    @Environment(\.colorScheme) private var scheme
    @AppStorage("itgirl.signedIn") private var signedIn = false
    @AppStorage("itgirl.authToken") private var authToken = ""
    @AppStorage("itgirl.refreshToken") private var refreshToken = ""
    @AppStorage("itgirl.appearance") private var appearanceRaw = "system"
    @AppStorage("itgirl.playfulAnimations") private var playfulAnimations = true
    @AppStorage("itgirl.colorPalette") private var colorPaletteRaw = ColorPaletteID.graphite.rawValue

    private var settingsPalette: ColorPaletteID {
        ColorPaletteID(rawValue: colorPaletteRaw) ?? .graphite
    }

    var body: some View {
        Form {
            Section {
                Picker("Color mode", selection: $appearanceRaw) {
                    Text("System").tag("system")
                    Text("Light").tag("light")
                    Text("Dark").tag("dark")
                }
                .pickerStyle(.segmented)
            } header: {
                Text("Appearance")
            } footer: {
                Text("Light / dark for the whole app. Pair with a color palette below.")
                    .foregroundStyle(.secondary)
            }

            Section {
                Picker("Color palette", selection: $colorPaletteRaw) {
                    ForEach(ColorPaletteID.allCases) { palette in
                        Text(palette.displayName).tag(palette.rawValue)
                    }
                }
                .pickerStyle(.inline)
            } header: {
                Text("Colour theme")
            } footer: {
                Text("Classic keeps the original IT Girl colours. Chic adds pastel fields and gold accents — nothing is removed.")
                    .foregroundStyle(.secondary)
            }

            Section {
                Toggle("Playful animations", isOn: $playfulAnimations)
            } header: {
                Text("Feel")
            } footer: {
                Text("Turn off for a calmer, more static UI.")
                    .foregroundStyle(.secondary)
            }

            Section {
                LabeledContent("Version", value: "1.0 (draft)")
            } header: {
                Text("About")
            }

            Section {
                Button("Sign out", role: .destructive) {
                    authToken = ""
                    refreshToken = ""
                    signedIn = false
                }
            } footer: {
                Text("You will return to the sign-in screen. Local routines stay on this device.")
                    .foregroundStyle(.secondary)
            }
        }
        .tint(ThemeColors.accent(for: scheme, palette: settingsPalette))
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }
}

// MARK: - Share sheet

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
