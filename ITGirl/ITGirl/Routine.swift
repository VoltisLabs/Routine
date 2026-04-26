import Foundation

enum RoutineKind: String, Codable, CaseIterable, Identifiable {
    case grwm
    case morning
    case skincare
    case fitness
    case study
    case other

    var id: String { rawValue }

    var title: String {
        switch self {
        case .grwm: "GRWM"
        case .morning: "Morning"
        case .skincare: "Skincare"
        case .fitness: "Fitness"
        case .study: "Study"
        case .other: "Other"
        }
    }

    var symbolName: String {
        switch self {
        case .grwm: "sparkles"
        case .morning: "sun.horizon.fill"
        case .skincare: "drop.fill"
        case .fitness: "figure.run"
        case .study: "book.fill"
        case .other: "list.bullet"
        }
    }
}

/// Gear / product label (images are routine-level uploads only).
struct RoutineGearItem: Identifiable, Codable, Hashable {
    var id: UUID
    var name: String

    init(id: UUID = UUID(), name: String) {
        self.id = id
        self.name = name
    }

    enum CodingKeys: String, CodingKey {
        case id, name, imageURL
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        _ = try? c.decodeIfPresent(String.self, forKey: .imageURL)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(name, forKey: .name)
    }
}

/// One actionable step in a routine.
struct RoutineStep: Identifiable, Codable, Hashable {
    var id: UUID
    var title: String
    var instructions: String
    var durationMinutes: Int?
    var gear: [RoutineGearItem]
    var notes: String

    enum CodingKeys: String, CodingKey {
        case id, title, instructions, durationMinutes, notes, gear
        case referenceImageURL
        case products
        case equipmentOrProducts
        case linkURL
    }

    init(
        id: UUID = UUID(),
        title: String = "",
        instructions: String = "",
        durationMinutes: Int? = nil,
        gear: [RoutineGearItem] = [],
        notes: String = ""
    ) {
        self.id = id
        self.title = title
        self.instructions = instructions
        self.durationMinutes = durationMinutes
        self.gear = gear
        self.notes = notes
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        title = try c.decode(String.self, forKey: .title)
        instructions = try c.decode(String.self, forKey: .instructions)
        durationMinutes = try c.decodeIfPresent(Int.self, forKey: .durationMinutes)
        notes = try c.decodeIfPresent(String.self, forKey: .notes) ?? ""
        _ = try? c.decodeIfPresent(String.self, forKey: .referenceImageURL)
        if let g = try c.decodeIfPresent([RoutineGearItem].self, forKey: .gear) {
            gear = g
        } else if let arr = try c.decodeIfPresent([String].self, forKey: .products) {
            gear = arr.map { RoutineGearItem(name: $0) }
        } else if let legacy = try c.decodeIfPresent(String.self, forKey: .equipmentOrProducts) {
            gear = Self.splitProducts(from: legacy).map { RoutineGearItem(name: $0) }
        } else {
            gear = []
        }
        _ = try? c.decodeIfPresent(String.self, forKey: .linkURL)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(title, forKey: .title)
        try c.encode(instructions, forKey: .instructions)
        try c.encodeIfPresent(durationMinutes, forKey: .durationMinutes)
        try c.encode(notes, forKey: .notes)
        if !gear.isEmpty {
            try c.encode(gear, forKey: .gear)
        }
    }

    private static func splitProducts(from string: String) -> [String] {
        string
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    var hasAnyContent: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || !instructions.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || !notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || !gear.isEmpty
    }
}

struct Routine: Identifiable, Codable, Hashable {
    var id: UUID
    var title: String
    var body: String
    var authorDisplayName: String
    var createdAt: Date
    var kind: RoutineKind
    var derivedFromId: UUID?
    var steps: [RoutineStep]?
    var customKindLabel: String?
    var imageAttachmentIds: [UUID]
    /// HTTPS image URLs for cover / gallery (shown when no local photos, or alongside).
    var remoteCoverImageURLs: [String]

    init(
        id: UUID = UUID(),
        title: String,
        body: String,
        authorDisplayName: String,
        createdAt: Date = .now,
        kind: RoutineKind,
        derivedFromId: UUID? = nil,
        steps: [RoutineStep]? = nil,
        customKindLabel: String? = nil,
        imageAttachmentIds: [UUID] = [],
        remoteCoverImageURLs: [String] = []
    ) {
        self.id = id
        self.title = title
        self.body = body
        self.authorDisplayName = authorDisplayName
        self.createdAt = createdAt
        self.kind = kind
        self.derivedFromId = derivedFromId
        self.steps = steps
        self.customKindLabel = customKindLabel
        self.imageAttachmentIds = imageAttachmentIds
        self.remoteCoverImageURLs = remoteCoverImageURLs
    }

    enum CodingKeys: String, CodingKey {
        case id, title, body, authorDisplayName, createdAt, kind, derivedFromId
        case steps, customKindLabel, imageAttachmentIds, remoteCoverImageURLs
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        title = try c.decode(String.self, forKey: .title)
        body = try c.decode(String.self, forKey: .body)
        authorDisplayName = try c.decode(String.self, forKey: .authorDisplayName)
        createdAt = try c.decode(Date.self, forKey: .createdAt)
        kind = try c.decode(RoutineKind.self, forKey: .kind)
        derivedFromId = try c.decodeIfPresent(UUID.self, forKey: .derivedFromId)
        steps = try c.decodeIfPresent([RoutineStep].self, forKey: .steps)
        customKindLabel = try c.decodeIfPresent(String.self, forKey: .customKindLabel)
        imageAttachmentIds = try c.decodeIfPresent([UUID].self, forKey: .imageAttachmentIds) ?? []
        remoteCoverImageURLs = try c.decodeIfPresent([String].self, forKey: .remoteCoverImageURLs) ?? []
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(title, forKey: .title)
        try c.encode(body, forKey: .body)
        try c.encode(authorDisplayName, forKey: .authorDisplayName)
        try c.encode(createdAt, forKey: .createdAt)
        try c.encode(kind, forKey: .kind)
        try c.encodeIfPresent(derivedFromId, forKey: .derivedFromId)
        try c.encodeIfPresent(steps, forKey: .steps)
        try c.encodeIfPresent(customKindLabel, forKey: .customKindLabel)
        if !imageAttachmentIds.isEmpty {
            try c.encode(imageAttachmentIds, forKey: .imageAttachmentIds)
        }
        if !remoteCoverImageURLs.isEmpty {
            try c.encode(remoteCoverImageURLs, forKey: .remoteCoverImageURLs)
        }
    }

    var displayKindTitle: String {
        if kind == .other {
            let t = customKindLabel?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            return t.isEmpty ? kind.title : t
        }
        return kind.title
    }

    /// Short preview for feed / list cards (first substantive step line, else body).
    var feedPreview: String {
        if let s = steps {
            for step in s {
                let title = step.title.trimmingCharacters(in: .whitespacesAndNewlines)
                let ins = step.instructions.trimmingCharacters(in: .whitespacesAndNewlines)
                if !title.isEmpty, !ins.isEmpty {
                    let firstLine = ins.split(whereSeparator: \.isNewline).map(String.init).first ?? ins
                    return Self.clampFeedBlurb(firstLine, limit: 160)
                }
                if !ins.isEmpty {
                    let firstLine = ins.split(whereSeparator: \.isNewline).map(String.init).first ?? ins
                    return Self.clampFeedBlurb(firstLine, limit: 180)
                }
                if !title.isEmpty { return Self.clampFeedBlurb(title, limit: 120) }
            }
        }
        let trimmed = body.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "Open for the full step list." }
        let lines = trimmed.split(whereSeparator: \.isNewline).map(String.init)
        return Self.clampFeedBlurb(lines.prefix(2).joined(separator: " "), limit: 200)
    }

    private static func clampFeedBlurb(_ s: String, limit: Int) -> String {
        let t = s.trimmingCharacters(in: .whitespacesAndNewlines)
        guard t.count > limit else { return t }
        return String(t.prefix(limit)).trimmingCharacters(in: .whitespacesAndNewlines) + "…"
    }

    var resolvedSteps: [RoutineStep] {
        if let s = steps, !s.isEmpty { return s }
        return [
            RoutineStep(
                title: "Your routine",
                instructions: body,
                durationMinutes: nil,
                gear: [],
                notes: ""
            )
        ]
    }

    /// Sum of step `durationMinutes` when every step has a value.
    var resolvedTotalDurationMinutes: Int? {
        let steps = resolvedSteps
        let mins = steps.compactMap(\.durationMinutes)
        guard mins.count == steps.count, !mins.isEmpty else { return nil }
        return mins.reduce(0, +)
    }

    var stepCount: Int {
        if let s = steps, !s.isEmpty { return s.count }
        return body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0 : 1
    }

    static func flattenedBody(from steps: [RoutineStep]) -> String {
        steps.enumerated().map { index, step in
            var parts: [String] = ["\(index + 1). \(step.title)\n\(step.instructions)"]
            if let m = step.durationMinutes {
                parts.append("Duration: \(Self.formatDurationMinutes(m))")
            }
            if !step.gear.isEmpty {
                let line = step.gear.map(\.name).joined(separator: ", ")
                parts.append("Gear: \(line)")
            }
            if !step.notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                parts.append("Notes: \(step.notes)")
            }
            return parts.joined(separator: "\n")
        }
        .joined(separator: "\n\n")
    }

    static func formatDurationMinutes(_ total: Int) -> String {
        let h = total / 60
        let m = total % 60
        if h == 0 { return "\(m) min" }
        if m == 0 { return "\(h) hr" }
        return "\(h) hr \(m) min"
    }

    func shareablePlainText(currentUserName: String) -> String {
        let kindLine = displayKindTitle
        let main: String
        if let s = steps, !s.isEmpty {
            main = Self.flattenedBody(from: s)
        } else {
            main = body
        }
        return """
        \(title) — \(kindLine) on IT Girl
        by \(authorDisplayName)

        \(main)

        — Shared from IT Girl
        """
    }

    func matchesSearch(_ q: String) -> Bool {
        let hay = [
            title, body, authorDisplayName, kind.title, displayKindTitle,
            (steps ?? []).map { step in
                let gearHay = step.gear.map(\.name).joined(separator: " ")
                return [step.title, step.instructions, step.notes, gearHay].joined(separator: " ")
            }.joined(separator: " "),
            remoteCoverImageURLs.joined(separator: " ")
        ].joined(separator: " ").lowercased()
        return hay.contains(q)
    }
}
