import SwiftUI
import UIKit

// MARK: - Discover

private enum DiscoverMode: String, CaseIterable {
    case feed = "Feed"
    case browse = "Browse"
}

struct DiscoverView: View {
    @Environment(RoutineLibrary.self) private var library
    @Environment(\.colorScheme) private var scheme
    @Environment(\.colorPalette) private var colorPalette
    @AppStorage("itgirl.playfulAnimations") private var playfulAnimations = true
    @State private var query = ""
    @State private var discoverMode: DiscoverMode = .feed

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
                            List {
                                Section {
                                    ForEach(results) { routine in
                                        NavigationLink(value: routine) {
                                            RoutineRowView(routine: routine)
                                        }
                                        .listRowBackground(listRowChrome)
                                    }
                                } header: {
                                    ItGirlSectionHeader(title: "Routines & GRWMs", systemImage: "sparkles")
                                } footer: {
                                    Text("Beauty, skincare, fitness, productivity, wellness — browse every routine from the community.")
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .listStyle(.insetGrouped)
                            .itGirlListChrome()
                            .searchable(text: $query, prompt: "Search routines")
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .navigationTitle("Discover")
                .navigationBarTitleDisplayMode(.large)
                .navigationDestination(for: Routine.self) { routine in
                    RoutineDetailView(routine: routine, context: .community)
                }
                .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            }
        }
        .itGirlAppearAnimation(playful: playfulAnimations)
    }

    private var listRowChrome: some View {
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

struct RoutineRowView: View {
    let routine: Routine
    @Environment(\.colorScheme) private var scheme
    @Environment(\.colorPalette) private var colorPalette

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: routine.kind.symbolName)
                .font(.title2)
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
                .frame(width: 40, height: 40)
                .background(
                    Circle()
                        .fill(ThemeColors.accent(for: scheme, palette: colorPalette).opacity(scheme == .dark ? 0.22 : 0.14))
                )

            VStack(alignment: .leading, spacing: 6) {
                Text(routine.title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text(routine.authorDisplayName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(routine.displayKindTitle)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(ThemeColors.accent(for: scheme, palette: colorPalette))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(ThemeColors.accent(for: scheme, palette: colorPalette).opacity(scheme == .dark ? 0.2 : 0.12))
                    )
                Text("\(routine.stepCount) steps")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 6)
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
    @Environment(\.dismiss) private var dismiss

    private var remoteGalleryTail: [String] {
        if routine.imageAttachmentIds.isEmpty {
            Array(routine.remoteCoverImageURLs.dropFirst())
        } else {
            routine.remoteCoverImageURLs
        }
    }

    var body: some View {
        ZStack {
            ItGirlScreenBackdrop()
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    RoutineCoverStrip(routine: routine, height: 220, cornerRadius: 22)
                        .padding(.horizontal)

                    RoutineDetailInstrumentStrip(routine: routine)
                        .padding(.horizontal)

                    RoutineDetailSignalRack(routine: routine)
                        .padding(.horizontal)

                    RoutineDetailDurationTimeline(routine: routine)
                        .padding(.horizontal)

                    HStack {
                        Label(routine.displayKindTitle, systemImage: routine.kind.symbolName)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(ThemeColors.accent(for: scheme, palette: colorPalette))
                        Spacer()
                        Text(routine.createdAt.formatted(date: .abbreviated, time: .omitted))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal)

                    Text("by \(routine.authorDisplayName)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)

                    if routine.imageAttachmentIds.count > 1 {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("LOCAL ROLL")
                                .font(.caption2.weight(.heavy))
                                .foregroundStyle(.tertiary)
                                .padding(.horizontal)
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
                                .padding(.horizontal)
                            }
                        }
                    }

                    RoutineRemoteGalleryStrip(urls: remoteGalleryTail)
                        .padding(.horizontal)

                    VStack(alignment: .leading, spacing: 16) {
                        ForEach(Array(routine.resolvedSteps.enumerated()), id: \.element.id) { index, step in
                            RoutineDetailStepCard(
                                step: step,
                                stepNumber: index + 1,
                                durationTotal: routine.resolvedTotalDurationMinutes
                            )
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.vertical)
            }
        }
        .navigationTitle(routine.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                if context == .community {
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
    @State private var showSettings = false

    var body: some View {
        @Bindable var library = library
        ZStack {
            ItGirlScreenBackdrop()
            NavigationStack {
                Form {
                    Section {
                        TextField("Display name", text: $library.displayName)
                            .foregroundStyle(.primary)
                    } header: {
                        Text("Your name on routines")
                            .foregroundStyle(.secondary)
                    } footer: {
                        Text("This name appears when you publish. Everything stays on-device in this draft.")
                            .foregroundStyle(.secondary)
                    }

                    Section {
                        LabeledContent("Published", value: "\(library.myRoutines.count)")
                        LabeledContent("Saved", value: "\(library.savedRoutines.count)")
                        LabeledContent("Discover feed", value: "\(library.communityRoutines.count)")
                    } header: {
                        Text("Stats")
                            .foregroundStyle(.secondary)
                    }

                    Section {
                        Text("A simple home for routines and GRWMs: write in plain text, search the feed, save favorites, and share anywhere.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    } header: {
                        Text("About IT Girl")
                            .foregroundStyle(.secondary)
                    }
                }
                .scrollContentBackground(.visible)
                .navigationTitle("You")
                .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            if playfulAnimations {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                    showSettings = true
                                }
                            } else {
                                showSettings = true
                            }
                        } label: {
                            Image(systemName: "gearshape.fill")
                                .font(.body.weight(.semibold))
                                .symbolRenderingMode(.hierarchical)
                                .foregroundStyle(ThemeColors.accent(for: scheme, palette: colorPalette))
                        }
                        .accessibilityLabel("Settings")
                    }
                }
                .sheet(isPresented: $showSettings) {
                    SettingsView()
                        .presentationDetents([.medium, .large])
                        .presentationDragIndicator(.visible)
                }
            }
        }
        .itGirlAppearAnimation(playful: playfulAnimations)
    }
}

// MARK: - Settings

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme
    @AppStorage("itgirl.appearance") private var appearanceRaw = "system"
    @AppStorage("itgirl.playfulAnimations") private var playfulAnimations = true
    @AppStorage("itgirl.colorPalette") private var colorPaletteRaw = ColorPaletteID.classic.rawValue

    private var settingsPalette: ColorPaletteID {
        ColorPaletteID(rawValue: colorPaletteRaw) ?? .classic
    }

    var body: some View {
        NavigationStack {
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
            }
            .tint(ThemeColors.accent(for: scheme, palette: settingsPalette))
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
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
