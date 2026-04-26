import SwiftUI

// MARK: - Spec / instrumentation row

struct RoutineDetailInstrumentStrip: View {
    let routine: Routine

    @Environment(\.colorScheme) private var scheme
    @Environment(\.colorPalette) private var colorPalette

    private let cols = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        let steps = routine.resolvedSteps
        let gearCount = steps.reduce(0) { $0 + $1.gear.count }
        let mediaCount = routine.imageAttachmentIds.count + routine.remoteCoverImageURLs.count

        ItGirlCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "waveform.path.ecg")
                        .symbolRenderingMode(.hierarchical)
                    Text("RUN LOG")
                        .font(.caption2.weight(.heavy))
                        .tracking(1.4)
                    Spacer()
                    Text(String(routine.id.uuidString.prefix(8)).uppercased())
                        .font(.caption2.monospaced())
                        .foregroundStyle(.secondary)
                }
                .foregroundStyle(ThemeColors.accent(for: scheme, palette: colorPalette))

                LazyVGrid(columns: cols, spacing: 10) {
                    specCell(title: "STEPS", value: "\(steps.count)")
                    specCell(
                        title: "BLOCK",
                        value: routine.resolvedTotalDurationMinutes.map { Routine.formatDurationMinutes($0) } ?? "MIXED"
                    )
                    specCell(title: "MEDIA", value: "\(mediaCount)")
                    specCell(title: "GEAR", value: "\(gearCount)")
                    specCell(title: "REMOTE", value: "\(routine.remoteCoverImageURLs.count)")
                    specCell(title: "CLASS", value: routine.displayKindTitle.uppercased())
                }
            }
        }
    }

    private func specCell(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .foregroundStyle(.tertiary)
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.primary.opacity(scheme == .dark ? 0.07 : 0.045))
        )
    }
}

// MARK: - Signal rack

struct RoutineDetailSignalRack: View {
    let routine: Routine

    @Environment(\.colorScheme) private var scheme
    @Environment(\.colorPalette) private var colorPalette

    private var tags: [(String, String)] {
        switch routine.kind {
        case .fitness:
            [
                ("location.fill", "GPS TRACE"),
                ("drop.fill", "HYDRATION 150ML"),
                ("metronome", "CADENCE LOCK"),
                ("heart.fill", "RPE 2–4"),
                ("wind", "WEATHER PULL")
            ]
        case .skincare:
            [
                ("drop.triangle.fill", "BARRIER FIRST"),
                ("timer", "LAYER COOLDOWN"),
                ("sun.max.fill", "PHOTOPROTECTION"),
                ("leaf.fill", "OCCLUSIVE ZONE"),
                ("eyedropper.halffull", "PATCH LOG")
            ]
        case .study:
            [
                ("iphone.slash", "DND ROOM"),
                ("timer", "50 / 10 GRID"),
                ("note.text", "STICKY HANDOFF"),
                ("headphones", "AUDIO ONLY"),
                ("chart.line.uptrend.xyaxis", "MOMENTUM")
            ]
        case .grwm:
            [
                ("sparkles", "LIGHT METER"),
                ("sun.max.fill", "SPF UNDER BASE"),
                ("wind", "COOL SHOT"),
                ("tshirt.fill", "OUTFIT LOCK"),
                ("clock.fill", "DEPARTURE ETA")
            ]
        case .morning:
            [
                ("sunrise.fill", "DAWN SYNC"),
                ("cup.and.saucer.fill", "CAFFEINE WINDOW"),
                ("figure.walk", "MOVEMENT FIRST"),
                ("alarm.fill", "ALARM HANDSHAKE")
            ]
        case .other:
            [
                ("slider.horizontal.3", "CUSTOM PIPE"),
                ("square.stack.3d.up", "MODULAR"),
                ("bolt.fill", "QUICK ITER")
            ]
        }
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Array(tags.enumerated()), id: \.offset) { _, tag in
                    HStack(spacing: 6) {
                        Image(systemName: tag.0)
                            .font(.caption.weight(.semibold))
                        Text(tag.1)
                            .font(.caption2.weight(.heavy))
                            .tracking(0.6)
                    }
                    .foregroundStyle(ThemeColors.secondaryAccent(for: scheme, palette: colorPalette))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(.ultraThinMaterial)
                            .overlay {
                                Capsule()
                                    .strokeBorder(
                                        ThemeColors.accent(for: scheme, palette: colorPalette).opacity(0.35),
                                        lineWidth: 1
                                    )
                            }
                    )
                }
            }
            .padding(.vertical, 2)
        }
    }
}

// MARK: - Duration timeline

struct RoutineDetailDurationTimeline: View {
    let routine: Routine

    @Environment(\.colorScheme) private var scheme
    @Environment(\.colorPalette) private var colorPalette

    var body: some View {
        let steps = routine.resolvedSteps
        let pairs: [(Int, Int)] = steps.enumerated().compactMap { idx, s in
            guard let m = s.durationMinutes, m > 0 else { return nil }
            return (idx, m)
        }
        let total = pairs.map(\.1).reduce(0, +)

        Group {
            if total > 0 {
                ItGirlCard {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("DURATION MAP")
                                .font(.caption2.weight(.heavy))
                                .tracking(1.2)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(Routine.formatDurationMinutes(total))
                                .font(.caption.monospaced().weight(.semibold))
                        }
                        GeometryReader { geo in
                            HStack(spacing: 3) {
                                ForEach(pairs, id: \.0) { pair in
                                    let w = max(8, geo.size.width * CGFloat(pair.1) / CGFloat(total))
                                    VStack(spacing: 4) {
                                        RoundedRectangle(cornerRadius: 5, style: .continuous)
                                            .fill(
                                                LinearGradient(
                                                    colors: [
                                                        ThemeColors.accent(for: scheme, palette: colorPalette),
                                                        ThemeColors.secondaryAccent(for: scheme, palette: colorPalette)
                                                    ],
                                                    startPoint: .top,
                                                    endPoint: .bottom
                                                )
                                            )
                                            .frame(width: w, height: 18)
                                            .overlay {
                                                Text("S\(pair.0 + 1)")
                                                    .font(.system(size: 9, weight: .heavy, design: .rounded))
                                                    .foregroundStyle(.white.opacity(0.95))
                                            }
                                        Text("\(pair.1)m")
                                            .font(.system(size: 8, weight: .medium, design: .monospaced))
                                            .foregroundStyle(.tertiary)
                                    }
                                    .frame(width: w)
                                }
                            }
                        }
                        .frame(height: 44)
                    }
                }
            }
        }
    }
}

// MARK: - Remote gallery

struct RoutineRemoteGalleryStrip: View {
    let urls: [String]

    @Environment(\.colorScheme) private var scheme
    @Environment(\.colorPalette) private var colorPalette

    var body: some View {
        Group {
            if urls.isEmpty {
                EmptyView()
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "link.circle.fill")
                            .foregroundStyle(ThemeColors.accent(for: scheme, palette: colorPalette))
                        Text("Reference gallery")
                            .font(.caption.weight(.heavy))
                            .tracking(0.8)
                        Spacer()
                        Text("\(urls.count) ASSET\(urls.count == 1 ? "" : "S")")
                            .font(.caption2.monospaced())
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.horizontal, 4)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(Array(urls.enumerated()), id: \.offset) { _, raw in
                                if let u = URL(string: raw) {
                                    AsyncImage(url: u) { phase in
                                        switch phase {
                                        case .success(let img):
                                            img
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: 120, height: 88)
                                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                        case .failure:
                                            galleryPlaceholder
                                                .frame(width: 120, height: 88)
                                        default:
                                            ProgressView()
                                                .frame(width: 120, height: 88)
                                        }
                                    }
                                    .overlay {
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .strokeBorder(
                                                ThemeColors.cardStroke(for: scheme, palette: colorPalette),
                                                lineWidth: 0.5
                                            )
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private var galleryPlaceholder: some View {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
            .fill(Color.primary.opacity(0.06))
            .overlay {
                Image(systemName: "wifi.exclamationmark")
                    .foregroundStyle(.secondary)
            }
    }
}

// MARK: - Step card

struct RoutineDetailStepCard: View {
    let step: RoutineStep
    let stepNumber: Int
    let durationTotal: Int?

    @Environment(\.colorScheme) private var scheme
    @Environment(\.colorPalette) private var colorPalette

    var body: some View {
        ItGirlCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        ThemeColors.accent(for: scheme, palette: colorPalette).opacity(0.35),
                                        ThemeColors.secondaryAccent(for: scheme, palette: colorPalette).opacity(0.25)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 40, height: 40)
                        Text("\(stepNumber)")
                            .font(.headline.weight(.heavy))
                            .foregroundStyle(.primary)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text("STEP \(stepNumber)")
                            .font(.caption2.weight(.heavy))
                            .tracking(1)
                            .foregroundStyle(ThemeColors.secondaryAccent(for: scheme, palette: colorPalette))
                        if let m = step.durationMinutes, let t = durationTotal, t > 0 {
                            HStack(spacing: 6) {
                                Text(Routine.formatDurationMinutes(m))
                                    .font(.caption.monospaced().weight(.medium))
                                GeometryReader { g in
                                    let frac = min(1, CGFloat(m) / CGFloat(t))
                                    ZStack(alignment: .leading) {
                                        Capsule()
                                            .fill(Color.primary.opacity(0.08))
                                        Capsule()
                                            .fill(ThemeColors.accent(for: scheme, palette: colorPalette))
                                            .frame(width: max(4, g.size.width * frac))
                                    }
                                }
                                .frame(width: 72, height: 6)
                            }
                        } else if let m = step.durationMinutes {
                            Text(Routine.formatDurationMinutes(m))
                                .font(.caption.monospaced().weight(.medium))
                                .foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                }

                if !step.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text(step.title)
                        .font(.headline)
                }

                Text(step.instructions)
                    .font(.body)
                    .foregroundStyle(.primary)

                if !step.gear.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("GEAR MANIFEST")
                            .font(.caption2.weight(.heavy))
                            .foregroundStyle(.tertiary)
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 88), spacing: 8)], alignment: .leading, spacing: 8) {
                            ForEach(step.gear) { item in
                                Text(item.name)
                                    .font(.caption.weight(.semibold))
                                    .lineLimit(2)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 8)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .strokeBorder(
                                                ThemeColors.accent(for: scheme, palette: colorPalette).opacity(0.25),
                                                lineWidth: 1
                                            )
                                    )
                            }
                        }
                    }
                }

                if !step.notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "text.badge.checkmark")
                            .font(.caption)
                            .foregroundStyle(ThemeColors.accent(for: scheme, palette: colorPalette))
                        Text(step.notes)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color.primary.opacity(scheme == .dark ? 0.08 : 0.04))
                    )
                }
            }
        }
    }
}
