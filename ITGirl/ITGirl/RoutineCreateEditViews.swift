import PhotosUI
import SwiftUI
import UIKit

private struct CreateRoutineDraftSnapshot: Codable {
    var title: String
    var kind: RoutineKind
    var customOtherLabel: String
    var steps: [RoutineStep]
    var coverURLsText: String
}

private enum CreateDraftStore {
    static let key = "itgirl.createRoutineDraft.v1"
}

private func parsedRoutineImageURLLines(_ text: String) -> [String] {
    text
        .split(whereSeparator: \.isNewline)
        .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
        .filter { !$0.isEmpty }
        .filter {
            guard let s = URL(string: $0)?.scheme?.lowercased() else { return false }
            return s == "https" || s == "http"
        }
}

// MARK: - Small field helpers

struct ITGFieldLabel: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
    }
}

// MARK: - Step duration (clock-style picker)

private struct StepDurationPicker: View {
    @Binding var minutesTotal: Int?

    private static var anchor: Date {
        Calendar.current.date(from: DateComponents(year: 2000, month: 1, day: 1))!
    }

    private var dateBinding: Binding<Date> {
        Binding(
            get: {
                let m = minutesTotal ?? 0
                return Calendar.current.date(bySettingHour: m / 60, minute: m % 60, second: 0, of: Self.anchor) ?? Self.anchor
            },
            set: { d in
                let h = Calendar.current.component(.hour, from: d)
                let mi = Calendar.current.component(.minute, from: d)
                let t = h * 60 + mi
                minutesTotal = t > 0 ? t : nil
            }
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ITGFieldLabel(text: "Duration")
            DatePicker("", selection: dateBinding, displayedComponents: [.hourAndMinute])
                .datePickerStyle(.wheel)
                .labelsHidden()
                .frame(maxWidth: .infinity)
            Button("Clear duration") {
                minutesTotal = nil
            }
            .font(.caption.weight(.medium))
            .buttonStyle(.borderless)
        }
    }
}

// MARK: - Gear (names only — images via routine cover uploads)

private struct StepGearEditor: View {
    @Binding var gear: [RoutineGearItem]
    let scheme: ColorScheme
    let palette: ColorPaletteID
    let playfulAnimations: Bool

    @State private var nameDraft = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ITGFieldLabel(text: "Gear & products")
            HStack(alignment: .center, spacing: 10) {
                TextField("Add item…", text: $nameDraft)
                    .submitLabel(.done)
                    .onSubmit(addDraftIfNeeded)
                    .itGirlRoundedField()
                Button {
                    addDraftIfNeeded()
                } label: {
                    Label("Add", systemImage: "plus.circle.fill")
                        .labelStyle(.iconOnly)
                        .font(.title2)
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(ThemeColors.accent(for: scheme, palette: palette))
                        .symbolEffect(.bounce, value: gear.count)
                }
                .buttonStyle(.plain)
                .sensoryFeedback(.impact(weight: .light), trigger: gear.count)
            }

            if !gear.isEmpty {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 120), spacing: 8)], spacing: 8) {
                    ForEach(gear) { item in
                        HStack(spacing: 8) {
                            Text(item.name)
                                .font(.subheadline)
                                .lineLimit(2)
                            Spacer(minLength: 0)
                            Button {
                                if playfulAnimations {
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                        gear.removeAll { $0.id == item.id }
                                    }
                                } else {
                                    gear.removeAll { $0.id == item.id }
                                }
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .imageScale(.small)
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(ThemeColors.accent(for: scheme, palette: palette).opacity(0.12))
                        )
                    }
                }
            }
        }
    }

    private func addDraftIfNeeded() {
        let n = nameDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !n.isEmpty else { return }
        if playfulAnimations {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.78)) {
                gear.append(RoutineGearItem(name: n))
                nameDraft = ""
            }
        } else {
            gear.append(RoutineGearItem(name: n))
            nameDraft = ""
        }
    }
}

// MARK: - Step editor

private struct StepEditorBlock: View {
    @Binding var step: RoutineStep
    let index: Int
    let total: Int
    let scheme: ColorScheme
    let palette: ColorPaletteID
    let playfulAnimations: Bool
    let onDelete: () -> Void
    let onMoveUp: () -> Void
    let onMoveDown: () -> Void
    let onSaveStep: () -> Void
    let onAddStepAfter: () -> Void
    let onDuplicateStep: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var showSavedFlash = false
    @State private var iconPulse = 0
    @State private var saveStepCount = 0

    var body: some View {
        ItGirlCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Step \(index + 1)")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(ThemeColors.accent(for: scheme, palette: palette))
                        .contentTransition(.numericText())
                    Spacer()
                    HStack(spacing: 4) {
                        Button(action: onMoveUp) {
                            Image(systemName: "arrow.up.circle")
                        }
                        .disabled(index == 0)
                        Button(action: onMoveDown) {
                            Image(systemName: "arrow.down.circle")
                        }
                        .disabled(index >= total - 1)
                        Button(role: .destructive, action: onDelete) {
                            Image(systemName: "trash.circle")
                        }
                        .disabled(total <= 1)
                    }
                    .font(.title3)
                    .labelStyle(.iconOnly)
                }

                VStack(alignment: .leading, spacing: 6) {
                    ITGFieldLabel(text: "Step title")
                    TextField("e.g. Double cleanse", text: $step.title)
                        .itGirlRoundedField()
                }
                .animation(reduceMotion || !playfulAnimations ? nil : .spring(response: 0.35, dampingFraction: 0.85), value: step.title)

                VStack(alignment: .leading, spacing: 6) {
                    ITGFieldLabel(text: "What to do")
                    TextField("Instructions, order, reps…", text: $step.instructions, axis: .vertical)
                        .lineLimit(3 ... 10)
                        .itGirlRoundedField()
                }
                .animation(reduceMotion || !playfulAnimations ? nil : .spring(response: 0.35, dampingFraction: 0.85), value: step.instructions)

                StepDurationPicker(minutesTotal: $step.durationMinutes)

                StepGearEditor(
                    gear: $step.gear,
                    scheme: scheme,
                    palette: palette,
                    playfulAnimations: playfulAnimations
                )

                VStack(alignment: .leading, spacing: 10) {
                    ITGFieldLabel(text: "Notes & cues")
                    TextField("Mindset, substitutions, rest, hydration…", text: $step.notes, axis: .vertical)
                        .lineLimit(2 ... 8)
                        .itGirlRoundedField()

                    Button {
                        onSaveStep()
                        saveStepCount += 1
                        if playfulAnimations && !reduceMotion {
                            withAnimation(.spring(response: 0.42, dampingFraction: 0.72)) {
                                showSavedFlash = true
                            }
                        } else {
                            showSavedFlash = true
                        }
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        Task {
                            try? await Task.sleep(nanoseconds: 1_400_000_000)
                            await MainActor.run {
                                withAnimation(playfulAnimations && !reduceMotion ? .easeOut(duration: 0.25) : nil) {
                                    showSavedFlash = false
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "square.and.arrow.down.fill")
                                .symbolEffect(.bounce, value: saveStepCount)
                            Text("Save step")
                                .font(.subheadline.weight(.semibold))
                            if showSavedFlash {
                                Image(systemName: "checkmark.circle.fill")
                                    .symbolEffect(.bounce, value: showSavedFlash)
                                    .transition(.scale.combined(with: .opacity))
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(LiquidGlassPrimaryButtonStyle(accent: ThemeColors.accent(for: scheme, palette: palette)))
                    .sensoryFeedback(.success, trigger: saveStepCount)

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Add new")
                            .font(.caption2.weight(.heavy))
                            .foregroundStyle(.tertiary)
                            .tracking(0.6)
                        HStack(spacing: 10) {
                            stepQuickIcon("plus.rectangle.on.rectangle", label: "Step below") {
                                pulseIcon { onAddStepAfter() }
                            }
                            stepQuickIcon("doc.on.doc", label: "Duplicate") {
                                pulseIcon { onDuplicateStep() }
                            }
                            stepQuickIcon("list.bullet", label: "Bullet") {
                                pulseIcon { appendNoteSnippet("\n• ") }
                            }
                            stepQuickIcon("timer", label: "Timer cue") {
                                pulseIcon { appendNoteSnippet("\n⏱ ") }
                            }
                            stepQuickIcon("sparkles", label: "Tip") {
                                pulseIcon { appendNoteSnippet("\n💡 ") }
                            }
                        }
                    }
                }
                .animation(reduceMotion || !playfulAnimations ? nil : .spring(response: 0.38, dampingFraction: 0.8), value: step.notes)
            }
        }
        .transition(.asymmetric(
            insertion: .scale(scale: 0.96).combined(with: .opacity),
            removal: .opacity
        ))
    }

    private func pulseIcon(_ action: () -> Void) {
        iconPulse += 1
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        if playfulAnimations && !reduceMotion {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.78)) {
                action()
            }
        } else {
            action()
        }
    }

    private func appendNoteSnippet(_ snippet: String) {
        if step.notes.isEmpty {
            step.notes = String(snippet.drop(while: \.isNewline))
        } else if !step.notes.hasSuffix("\n"), !snippet.hasPrefix("\n") {
            step.notes += snippet
        } else {
            step.notes += snippet
        }
    }

    @ViewBuilder
    private func stepQuickIcon(_ systemName: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.title3)
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(ThemeColors.secondaryAccent(for: scheme, palette: palette))
                .frame(width: 44, height: 44)
                .background {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .overlay {
                            Circle()
                                .strokeBorder(
                                    ThemeColors.accent(for: scheme, palette: palette).opacity(0.35),
                                    lineWidth: 1
                                )
                        }
                }
                .symbolEffect(.bounce, value: iconPulse)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}

// MARK: - Create

struct CreateRoutineView: View {
    @Environment(RoutineLibrary.self) private var library
    @Environment(\.colorScheme) private var scheme
    @Environment(\.colorPalette) private var colorPalette
    @AppStorage("itgirl.playfulAnimations") private var playfulAnimations = true

    @State private var title = ""
    @State private var kind: RoutineKind = .grwm
    @State private var customOtherLabel = ""
    @State private var steps: [RoutineStep] = [RoutineStep()]
    @State private var photoPickerItems: [PhotosPickerItem] = []
    @State private var stagedPhotoData: [Data] = []
    @State private var coverImageURLsText = ""
    @State private var didPublish = false
    @State private var showOtherWarning = false
    @State private var showStepsWarning = false
    @State private var showApiSyncAlert = false
    @State private var apiSyncMessage = ""

    var body: some View {
        ZStack {
            ItGirlScreenBackdrop()
            NavigationStack {
                ScrollView {
                    VStack(spacing: 22) {
                        ItGirlSectionHeader(title: "Routine basics", systemImage: "heart.text.square.fill")
                        ItGirlCard {
                            VStack(alignment: .leading, spacing: 14) {
                                TextField("Routine title", text: $title)
                                    .font(.body.weight(.medium))
                                    .foregroundStyle(.primary)
                                    .itGirlRoundedField()

                                Divider()
                                    .overlay(ThemeColors.accent(for: scheme, palette: colorPalette).opacity(0.25))

                                Picker("Type", selection: $kind) {
                                    ForEach(RoutineKind.allCases) { k in
                                        Text(k.title).tag(k)
                                    }
                                }
                                .pickerStyle(.menu)
                                .tint(ThemeColors.accent(for: scheme, palette: colorPalette))
                                .animation(
                                    playfulAnimations
                                        ? .spring(response: 0.4, dampingFraction: 0.78)
                                        : .easeOut(duration: 0.001),
                                    value: kind
                                )

                                if kind == .other {
                                    VStack(alignment: .leading, spacing: 6) {
                                        ITGFieldLabel(text: "Name this category")
                                        TextField("e.g. Meal prep, Travel reset, Dog walk", text: $customOtherLabel)
                                            .itGirlRoundedField()
                                    }
                                    .padding(.top, 4)
                                }
                            }
                        }

                        ItGirlSectionHeader(title: "Cover photos", systemImage: "photo.on.rectangle.angled")
                        ItGirlCard {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Add a hero image or a short gallery (up to 8).")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                                PhotosPicker(
                                    selection: $photoPickerItems,
                                    maxSelectionCount: 8,
                                    matching: .images,
                                    photoLibrary: .shared()
                                ) {
                                    Label("Choose from library", systemImage: "plus.circle.fill")
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                }
                                .buttonStyle(.bordered)
                                .tint(ThemeColors.accent(for: scheme, palette: colorPalette))
                                .onChange(of: photoPickerItems) { _, items in
                                    Task { await reloadStagedPhotos(from: items) }
                                }

                                if !stagedPhotoData.isEmpty {
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 10) {
                                            ForEach(Array(stagedPhotoData.enumerated()), id: \.offset) { _, data in
                                                if let ui = UIImage(data: data) {
                                                    Image(uiImage: ui)
                                                        .resizable()
                                                        .scaledToFill()
                                                        .frame(width: 88, height: 88)
                                                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                                }
                                            }
                                        }
                                    }
                                    Button("Clear all photos", role: .destructive) {
                                        stagedPhotoData = []
                                        photoPickerItems = []
                                    }
                                    .font(.caption)
                                }

                                Divider()
                                    .overlay(ThemeColors.accent(for: scheme, palette: colorPalette).opacity(0.2))
                                ITGFieldLabel(text: "Cover image URLs (one per line, https)")
                                TextField("https://…", text: $coverImageURLsText, axis: .vertical)
                                    .lineLimit(3 ... 8)
                                    .itGirlRoundedField()
                            }
                        }

                        HStack {
                            ItGirlSectionHeader(title: "Steps", systemImage: "list.bullet.clipboard.fill")
                            Spacer()
                            Button {
                                if playfulAnimations {
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                        steps.append(RoutineStep())
                                    }
                                } else {
                                    steps.append(RoutineStep())
                                }
                            } label: {
                                Label("Add step", systemImage: "plus.circle.fill")
                                    .font(.subheadline.weight(.semibold))
                                    .symbolEffect(.bounce, value: steps.count)
                            }
                            .tint(ThemeColors.secondaryAccent(for: scheme, palette: colorPalette))
                            .sensoryFeedback(.impact(weight: .medium), trigger: steps.count)
                        }
                        .padding(.horizontal, 4)

                        ForEach(Array(steps.enumerated()), id: \.element.id) { idx, _ in
                            StepEditorBlock(
                                step: $steps[idx],
                                index: idx,
                                total: steps.count,
                                scheme: scheme,
                                palette: colorPalette,
                                playfulAnimations: playfulAnimations,
                                onDelete: { deleteStep(at: idx) },
                                onMoveUp: { moveStep(from: idx, to: idx - 1) },
                                onMoveDown: { moveStep(from: idx, to: idx + 1) },
                                onSaveStep: { saveStepCreate(at: idx) },
                                onAddStepAfter: { addStepAfterCreate(at: idx) },
                                onDuplicateStep: { duplicateStepCreate(at: idx) }
                            )
                        }

                        Button {
                            publish()
                        } label: {
                            Label("Publish to Discover", systemImage: "sparkles")
                        }
                        .buttonStyle(LiquidGlassPrimaryButtonStyle(accent: ThemeColors.accent(for: scheme, palette: colorPalette)))
                        .disabled(!canPublish)
                        .padding(.top, 4)
                    }
                    .padding()
                    .padding(.bottom, 28)
                }
                .navigationTitle("New routine")
                .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
                .alert("Name your category", isPresented: $showOtherWarning) {
                    Button("OK", role: .cancel) {}
                } message: {
                    Text("When you pick “Other”, add a short label so people know what this routine is.")
                }
                .alert("Add at least one step", isPresented: $showStepsWarning) {
                    Button("OK", role: .cancel) {}
                } message: {
                    Text("Give each step a title or instructions (or both).")
                }
                .alert("Published", isPresented: $didPublish) {
                    Button("OK", role: .cancel) {}
                } message: {
                    Text("Your routine is live in Discover and in Mine.")
                }
                .alert("Couldn’t sync to server", isPresented: $showApiSyncAlert) {
                    Button("OK", role: .cancel) {}
                } message: {
                    Text(apiSyncMessage)
                }
                .onAppear {
                    restoreCreateDraftIfNeeded()
                }
            }
        }
        .itGirlAppearAnimation(playful: playfulAnimations)
    }

    private var canPublish: Bool {
        let t = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty else { return false }
        if kind == .other, customOtherLabel.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return false
        }
        return steps.contains { $0.hasAnyContent }
    }

    private func moveStep(from: Int, to: Int) {
        guard steps.indices.contains(from), steps.indices.contains(to) else { return }
        steps.swapAt(from, to)
        persistCreateDraft()
    }

    private func deleteStep(at index: Int) {
        guard steps.indices.contains(index) else { return }
        if steps.count <= 1 {
            steps = [RoutineStep()]
        } else {
            steps.remove(at: index)
        }
        persistCreateDraft()
    }

    private func addStepAfterCreate(at index: Int) {
        guard steps.indices.contains(index) else { return }
        if playfulAnimations {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.78)) {
                steps.insert(RoutineStep(), at: index + 1)
            }
        } else {
            steps.insert(RoutineStep(), at: index + 1)
        }
        persistCreateDraft()
    }

    private func duplicateStepCreate(at index: Int) {
        guard steps.indices.contains(index) else { return }
        var copy = steps[index]
        copy.id = UUID()
        if playfulAnimations {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.78)) {
                steps.insert(copy, at: index + 1)
            }
        } else {
            steps.insert(copy, at: index + 1)
        }
        persistCreateDraft()
    }

    private func saveStepCreate(at _: Int) {
        persistCreateDraft()
    }

    private func persistCreateDraft() {
        let snap = CreateRoutineDraftSnapshot(
            title: title,
            kind: kind,
            customOtherLabel: customOtherLabel,
            steps: steps,
            coverURLsText: coverImageURLsText
        )
        if let data = try? JSONEncoder().encode(snap) {
            UserDefaults.standard.set(data, forKey: CreateDraftStore.key)
        }
    }

    private func restoreCreateDraftIfNeeded() {
        guard let data = UserDefaults.standard.data(forKey: CreateDraftStore.key),
              let snap = try? JSONDecoder().decode(CreateRoutineDraftSnapshot.self, from: data) else { return }
        title = snap.title
        kind = snap.kind
        customOtherLabel = snap.customOtherLabel
        steps = snap.steps.isEmpty ? [RoutineStep()] : snap.steps
        coverImageURLsText = snap.coverURLsText
    }

    private func clearCreateDraft() {
        UserDefaults.standard.removeObject(forKey: CreateDraftStore.key)
    }

    @MainActor
    private func reloadStagedPhotos(from items: [PhotosPickerItem]) async {
        var out: [Data] = []
        for item in items.prefix(8) {
            if let d = try? await item.loadTransferable(type: Data.self) {
                out.append(d)
            }
        }
        stagedPhotoData = out
    }

    private func publish() {
        if kind == .other, customOtherLabel.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            showOtherWarning = true
            return
        }
        let valid = steps.filter(\.hasAnyContent)
        guard !valid.isEmpty else {
            showStepsWarning = true
            return
        }
        let bodyText = Routine.flattenedBody(from: valid)
        var imageIds: [UUID] = []
        for data in stagedPhotoData {
            let id = UUID()
            if (try? RoutineImageStore.shared.saveJPEG(data: data, id: id)) != nil {
                imageIds.append(id)
            }
        }
        let routine = Routine(
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            body: bodyText,
            authorDisplayName: library.displayName,
            kind: kind,
            steps: valid,
            customKindLabel: kind == .other ? customOtherLabel.trimmingCharacters(in: .whitespacesAndNewlines) : nil,
            imageAttachmentIds: imageIds,
            remoteCoverImageURLs: parsedRoutineImageURLLines(coverImageURLsText)
        )
        library.insertPublishedRoutine(routine)
        clearCreateDraft()
        title = ""
        kind = .grwm
        customOtherLabel = ""
        steps = [RoutineStep()]
        stagedPhotoData = []
        photoPickerItems = []
        coverImageURLsText = ""
        didPublish = true
        Task {
            do {
                _ = try await VoltisGraphQLClient.shared.syncRoutineForDiscover(routine)
            } catch {
                await MainActor.run {
                    apiSyncMessage = error.localizedDescription
                    showApiSyncAlert = true
                }
            }
        }
    }
}

// MARK: - Edit

struct EditRoutineView: View {
    @Environment(RoutineLibrary.self) private var library
    @Environment(\.colorScheme) private var scheme
    @Environment(\.colorPalette) private var colorPalette
    @AppStorage("itgirl.playfulAnimations") private var playfulAnimations = true
    @State var routine: Routine
    @Environment(\.dismiss) private var dismiss

    @State private var steps: [RoutineStep] = []
    @State private var customOtherLabel = ""
    @State private var photoPickerItems: [PhotosPickerItem] = []
    @State private var stagedPhotoData: [Data] = []
    @State private var coverURLsText = ""
    @State private var showOtherWarning = false
    @State private var showStepsWarning = false
    @State private var showApiSyncAlert = false
    @State private var apiSyncMessage = ""

    var body: some View {
        editRoutineChrome
    }

    private var editRoutineChrome: some View {
        ZStack {
            ItGirlScreenBackdrop()
            NavigationStack {
                ScrollView {
                    editRoutineFormStack
                        .padding()
                        .padding(.bottom, 28)
                }
                .navigationTitle("Edit")
                .navigationBarTitleDisplayMode(.inline)
                .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
                .onAppear(perform: loadEditRoutineState)
                .alert("Name your category", isPresented: $showOtherWarning) {
                    Button("OK", role: .cancel) {}
                } message: {
                    Text("When type is “Other”, add a short label.")
                }
                .alert("Add at least one step", isPresented: $showStepsWarning) {
                    Button("OK", role: .cancel) {}
                } message: {
                    Text("Each step needs a title or instructions.")
                }
                .alert("Couldn’t sync to server", isPresented: $showApiSyncAlert) {
                    Button("OK", role: .cancel) {}
                } message: {
                    Text(apiSyncMessage)
                }
            }
        }
        .itGirlAppearAnimation(playful: playfulAnimations)
    }

    @ViewBuilder
    private var editRoutineFormStack: some View {
        VStack(spacing: 22) {
            ItGirlCard {
                VStack(alignment: .leading, spacing: 14) {
                    TextField("Title", text: $routine.title)
                        .font(.body.weight(.medium))
                        .foregroundStyle(.primary)
                        .itGirlRoundedField()
                    Divider()
                        .overlay(ThemeColors.accent(for: scheme, palette: colorPalette).opacity(0.25))
                    Picker("Type", selection: $routine.kind) {
                        ForEach(RoutineKind.allCases) { k in
                            Text(k.title).tag(k)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(ThemeColors.accent(for: scheme, palette: colorPalette))

                    if routine.kind == .other {
                        VStack(alignment: .leading, spacing: 6) {
                            ITGFieldLabel(text: "Name this category")
                            TextField("e.g. Meal prep, Travel reset", text: $customOtherLabel)
                                .itGirlRoundedField()
                        }
                        .padding(.top, 4)
                    }
                }
            }

            ItGirlSectionHeader(title: "Photos", systemImage: "photo.on.rectangle.angled")
            ItGirlCard {
                editPhotosCard
            }

            HStack {
                ItGirlSectionHeader(title: "Steps", systemImage: "list.bullet.clipboard.fill")
                Spacer()
                Button {
                    if playfulAnimations {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            steps.append(RoutineStep())
                        }
                    } else {
                        steps.append(RoutineStep())
                    }
                } label: {
                    Label("Add step", systemImage: "plus.circle.fill")
                        .font(.subheadline.weight(.semibold))
                        .symbolEffect(.bounce, value: steps.count)
                }
                .tint(ThemeColors.secondaryAccent(for: scheme, palette: colorPalette))
                .sensoryFeedback(.impact(weight: .medium), trigger: steps.count)
            }
            .padding(.horizontal, 4)

            ForEach(Array(steps.enumerated()), id: \.element.id) { idx, _ in
                StepEditorBlock(
                    step: $steps[idx],
                    index: idx,
                    total: steps.count,
                    scheme: scheme,
                    palette: colorPalette,
                    playfulAnimations: playfulAnimations,
                    onDelete: { deleteStep(at: idx) },
                    onMoveUp: { moveStep(from: idx, to: idx - 1) },
                    onMoveDown: { moveStep(from: idx, to: idx + 1) },
                    onSaveStep: { saveStepEdit(at: idx) },
                    onAddStepAfter: { addStepAfterEdit(at: idx) },
                    onDuplicateStep: { duplicateStepEdit(at: idx) }
                )
            }

            Button {
                save()
            } label: {
                Label("Save changes", systemImage: "checkmark.circle.fill")
            }
            .buttonStyle(LiquidGlassPrimaryButtonStyle(accent: ThemeColors.secondaryAccent(for: scheme, palette: colorPalette)))
            .disabled(!canSave)
        }
    }

    @ViewBuilder
    private var editPhotosCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            PhotosPicker(
                selection: $photoPickerItems,
                maxSelectionCount: 8,
                matching: .images,
                photoLibrary: .shared()
            ) {
                Label("Replace / add from library", systemImage: "photo.badge.plus")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
            }
            .buttonStyle(.bordered)
            .tint(ThemeColors.accent(for: scheme, palette: colorPalette))
            .onChange(of: photoPickerItems) { _, items in
                Task { await reloadStagedPhotos(from: items) }
            }
            if !stagedPhotoData.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(Array(stagedPhotoData.enumerated()), id: \.offset) { _, data in
                            if let ui = UIImage(data: data) {
                                Image(uiImage: ui)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 88, height: 88)
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            }
                        }
                    }
                }
                Button("Clear all photos", role: .destructive) {
                    stagedPhotoData = []
                    photoPickerItems = []
                }
                .font(.caption)
            }

            Divider()
                .overlay(ThemeColors.accent(for: scheme, palette: colorPalette).opacity(0.2))
            ITGFieldLabel(text: "Cover image URLs (one per line)")
            TextField("https://…", text: $coverURLsText, axis: .vertical)
                .lineLimit(3 ... 8)
                .itGirlRoundedField()
        }
    }

    private func loadEditRoutineState() {
        if let s = routine.steps, !s.isEmpty {
            steps = s
        } else {
            steps = [
                RoutineStep(
                    title: "Your routine",
                    instructions: routine.body,
                    durationMinutes: nil,
                    gear: [],
                    notes: ""
                )
            ]
        }
        customOtherLabel = routine.customKindLabel ?? ""
        coverURLsText = routine.remoteCoverImageURLs.joined(separator: "\n")
        stagedPhotoData = routine.imageAttachmentIds.compactMap { RoutineImageStore.shared.loadData(id: $0) }
    }

    private var canSave: Bool {
        if routine.kind == .other, customOtherLabel.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return false
        }
        return !routine.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && steps.contains { $0.hasAnyContent }
    }

    private func addStepAfterEdit(at index: Int) {
        guard steps.indices.contains(index) else { return }
        if playfulAnimations {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.78)) {
                steps.insert(RoutineStep(), at: index + 1)
            }
        } else {
            steps.insert(RoutineStep(), at: index + 1)
        }
    }

    private func duplicateStepEdit(at index: Int) {
        guard steps.indices.contains(index) else { return }
        var copy = steps[index]
        copy.id = UUID()
        if playfulAnimations {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.78)) {
                steps.insert(copy, at: index + 1)
            }
        } else {
            steps.insert(copy, at: index + 1)
        }
    }

    private func saveStepEdit(at _: Int) {
        guard !routine.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        if routine.kind == .other, customOtherLabel.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            showOtherWarning = true
            return
        }
        routine.steps = steps
        let valid = steps.filter(\.hasAnyContent)
        routine.body = valid.isEmpty ? routine.body : Routine.flattenedBody(from: valid)
        routine.customKindLabel = routine.kind == .other ? customOtherLabel.trimmingCharacters(in: .whitespacesAndNewlines) : nil
        routine.remoteCoverImageURLs = parsedRoutineImageURLLines(coverURLsText)
        library.updateMyRoutine(routine)
        Task {
            do {
                _ = try await VoltisGraphQLClient.shared.syncRoutineForDiscover(routine)
            } catch {
                await MainActor.run {
                    apiSyncMessage = error.localizedDescription
                    showApiSyncAlert = true
                }
            }
        }
    }

    private func moveStep(from: Int, to: Int) {
        guard steps.indices.contains(from), steps.indices.contains(to) else { return }
        steps.swapAt(from, to)
    }

    private func deleteStep(at index: Int) {
        guard steps.indices.contains(index) else { return }
        if steps.count <= 1 {
            steps = [RoutineStep()]
        } else {
            steps.remove(at: index)
        }
    }

    @MainActor
    private func reloadStagedPhotos(from items: [PhotosPickerItem]) async {
        var out: [Data] = []
        for item in items.prefix(8) {
            if let d = try? await item.loadTransferable(type: Data.self) {
                out.append(d)
            }
        }
        stagedPhotoData = out
    }

    private func save() {
        if routine.kind == .other, customOtherLabel.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            showOtherWarning = true
            return
        }
        let valid = steps.filter(\.hasAnyContent)
        guard !valid.isEmpty else {
            showStepsWarning = true
            return
        }
        RoutineImageStore.shared.delete(ids: routine.imageAttachmentIds)
        var newIds: [UUID] = []
        for data in stagedPhotoData {
            let id = UUID()
            if (try? RoutineImageStore.shared.saveJPEG(data: data, id: id)) != nil {
                newIds.append(id)
            }
        }
        routine.body = Routine.flattenedBody(from: valid)
        routine.steps = valid
        routine.customKindLabel = routine.kind == .other ? customOtherLabel.trimmingCharacters(in: .whitespacesAndNewlines) : nil
        routine.imageAttachmentIds = newIds
        routine.remoteCoverImageURLs = parsedRoutineImageURLLines(coverURLsText)
        library.updateMyRoutine(routine)
        Task {
            do {
                _ = try await VoltisGraphQLClient.shared.syncRoutineForDiscover(routine)
            } catch {
                await MainActor.run {
                    apiSyncMessage = error.localizedDescription
                    showApiSyncAlert = true
                }
            }
        }
        dismiss()
    }
}
