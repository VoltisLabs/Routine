import Foundation
import Observation

@Observable
final class RoutineLibrary {
    private(set) var communityRoutines: [Routine] = []
    private(set) var myRoutines: [Routine] = []
    private(set) var savedRoutines: [Routine] = []

    var displayName: String {
        didSet { persistProfile() }
    }

    private let defaults = UserDefaults.standard
    private enum Key {
        static let my = "itgirl.myRoutines"
        static let saved = "itgirl.savedRoutines"
        static let communityExtras = "itgirl.communityExtras"
        static let displayName = "itgirl.displayName"
    }

    init() {
        displayName = defaults.string(forKey: Key.displayName) ?? "IT Girl"
        load()
    }

    func routinesMatchingSearch(_ query: String) -> [Routine] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return communityRoutines.sorted(by: { $0.createdAt > $1.createdAt }) }
        return communityRoutines.filter { $0.matchesSearch(q) }
            .sorted(by: { $0.createdAt > $1.createdAt })
    }

    /// Publishes a fully built routine (steps, images, labels already set on the value).
    func insertPublishedRoutine(_ routine: Routine) {
        myRoutines.insert(routine, at: 0)
        communityRoutines.insert(routine, at: 0)
        persistAll()
    }

    func updateMyRoutine(_ routine: Routine) {
        guard let idx = myRoutines.firstIndex(where: { $0.id == routine.id }) else { return }
        let old = myRoutines[idx]
        let removedImageIds = Set(old.imageAttachmentIds).subtracting(routine.imageAttachmentIds)
        RoutineImageStore.shared.delete(ids: Array(removedImageIds))
        myRoutines[idx] = routine
        if let cIdx = communityRoutines.firstIndex(where: { $0.id == routine.id }) {
            communityRoutines[cIdx] = routine
        }
        persistAll()
    }

    func deleteMyRoutine(id: UUID) {
        if let r = myRoutines.first(where: { $0.id == id }) {
            RoutineImageStore.shared.delete(ids: r.imageAttachmentIds)
        }
        myRoutines.removeAll { $0.id == id }
        communityRoutines.removeAll { $0.id == id }
        savedRoutines.removeAll { $0.derivedFromId == id }
        persistAll()
    }

    func saveRoutineToAccount(_ routine: Routine) {
        let already = savedRoutines.contains { $0.derivedFromId == routine.id || $0.id == routine.id }
        guard !already else { return }
        let newImageIds = RoutineImageStore.shared.duplicate(ids: routine.imageAttachmentIds)
        var copy = Routine(
            title: routine.title,
            body: routine.body,
            authorDisplayName: routine.authorDisplayName,
            createdAt: routine.createdAt,
            kind: routine.kind,
            derivedFromId: routine.id,
            steps: routine.steps,
            customKindLabel: routine.customKindLabel,
            imageAttachmentIds: newImageIds,
            remoteCoverImageURLs: routine.remoteCoverImageURLs
        )
        copy.id = UUID()
        savedRoutines.insert(copy, at: 0)
        persistSaved()
    }

    func removeSaved(id: UUID) {
        if let r = savedRoutines.first(where: { $0.id == id }) {
            RoutineImageStore.shared.delete(ids: r.imageAttachmentIds)
        }
        savedRoutines.removeAll { $0.id == id }
        persistSaved()
    }

    func isSaved(_ routine: Routine) -> Bool {
        savedRoutines.contains { $0.derivedFromId == routine.id || $0.id == routine.id }
    }

    // MARK: - Persistence

    private func load() {
        myRoutines = decode([Routine].self, from: defaults.data(forKey: Key.my)) ?? []
        savedRoutines = decode([Routine].self, from: defaults.data(forKey: Key.saved)) ?? []
        let extras = decode([Routine].self, from: defaults.data(forKey: Key.communityExtras)) ?? []
        communityRoutines = Self.seedCommunity + extras
        var seen = Set<UUID>()
        communityRoutines = communityRoutines.filter { seen.insert($0.id).inserted }
        communityRoutines.sort { $0.createdAt > $1.createdAt }
    }

    private func persistAll() {
        persistMy()
        persistSaved()
        persistCommunityExtras()
    }

    private func persistMy() {
        defaults.set(encode(myRoutines), forKey: Key.my)
    }

    private func persistSaved() {
        defaults.set(encode(savedRoutines), forKey: Key.saved)
    }

    private func persistProfile() {
        defaults.set(displayName, forKey: Key.displayName)
    }

    private func persistCommunityExtras() {
        let seedIds = Set(Self.seedCommunity.map(\.id))
        let extras = communityRoutines.filter { !seedIds.contains($0.id) }
        defaults.set(encode(extras), forKey: Key.communityExtras)
    }

    private func encode<T: Encodable>(_ value: T) -> Data? {
        try? JSONEncoder().encode(value)
    }

    private func decode<T: Decodable>(_ type: T.Type, from data: Data?) -> T? {
        guard let data else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }

    private static let seedCommunity: [Routine] = {
        let cal = Calendar.current
        func daysAgo(_ n: Int) -> Date {
            cal.date(byAdding: .day, value: -n, to: .now) ?? .now
        }

        // Curated HTTPS reference art (Unsplash) — cover + gear thumbnails.
        let imgRunHero = "https://images.unsplash.com/photo-1476480862126-209bfaa8edc8?auto=format&fit=crop&w=1400&q=80"
        let imgRunTrack = "https://images.unsplash.com/photo-1517649763962-0c62306601b7?auto=format&fit=crop&w=1200&q=80"
        let imgShoes = "https://images.unsplash.com/photo-1542291026-7eec264c27ef?auto=format&fit=crop&w=500&q=80"
        let imgGrwmHero = "https://images.unsplash.com/photo-1596462502278-27bfdc403348?auto=format&fit=crop&w=1400&q=80"
        let imgSkinHero = "https://images.unsplash.com/photo-1570172619644-dfd03ed5d881?auto=format&fit=crop&w=1400&q=80"
        let imgMask = "https://images.unsplash.com/photo-1596755389378-c31d21fd1273?auto=format&fit=crop&w=900&q=80"
        let imgStudyHero = "https://images.unsplash.com/photo-1456513080510-7bf3a84b82f8?auto=format&fit=crop&w=1400&q=80"
        let imgDesk = "https://images.unsplash.com/photo-1517842645767-c639b8808776?auto=format&fit=crop&w=900&q=80"

        let grwmSteps: [RoutineStep] = [
            RoutineStep(
                title: "Skin prep",
                instructions: "SPF first — let it set while you brew coffee. Layer humectants on damp skin so actives absorb evenly.",
                durationMinutes: 5,
                gear: [
                    RoutineGearItem(name: "SPF 50+"),
                    RoutineGearItem(name: "Barrier moisturizer")
                ],
                notes: "Pat in, don’t rub. Wait 60s between layers."
            ),
            RoutineStep(
                title: "Face & flush",
                instructions: "Light base, cream blush, one lip you love. Keep undertone consistent with your jewelry metal.",
                durationMinutes: 12,
                gear: [
                    RoutineGearItem(name: "Tinted moisturizer"),
                    RoutineGearItem(name: "Cream blush")
                ],
                notes: "Diffuse edges with a dry sponge — no harsh lines."
            ),
            RoutineStep(
                title: "Hair & outfit",
                instructions: "Rough dry, cool shot at the ends. Outfit was laid out last night — shoes by the door.",
                durationMinutes: 15,
                gear: [
                    RoutineGearItem(name: "Hair dryer"),
                    RoutineGearItem(name: "Heat protectant")
                ],
                notes: "No morning decision fatigue."
            )
        ]
        let grwmBody = Routine.flattenedBody(from: grwmSteps)

        let skincareSteps: [RoutineStep] = [
            RoutineStep(
                title: "Oil + surfactant cleanse",
                instructions: "60s massage with oil on dry skin. Emulsify, then gel cleanser — focus hairline and jaw.",
                durationMinutes: 4,
                gear: [
                    RoutineGearItem(name: "Cleansing oil"),
                    RoutineGearItem(name: "pH 5.5 gel cleanser")
                ],
                notes: "Lukewarm water only."
            ),
            RoutineStep(
                title: "Hydrating toner + essence",
                instructions: "3-skin method if dehydrated: thin layers, press with palms until tacky.",
                durationMinutes: 5,
                gear: [RoutineGearItem(name: "Hyaluronic toner")],
                notes: "Stop if skin feels tight — skip a layer."
            ),
            RoutineStep(
                title: "Treatment window",
                instructions: "Optional: clay mask T-zone only, 8 minutes max. Rinse before it cracks.",
                durationMinutes: 10,
                gear: [
                    RoutineGearItem(name: "Kaolin mask"),
                    RoutineGearItem(name: "Timer")
                ],
                notes: "Mist face between rinse and next step."
            ),
            RoutineStep(
                title: "Serum → moisturizer → occlusive",
                instructions: "Water-based serum first, then cream, then petrolatum or balm on dry patches only.",
                durationMinutes: 6,
                gear: [
                    RoutineGearItem(name: "Niacinamide serum"),
                    RoutineGearItem(name: "Barrier cream")
                ],
                notes: "Log any sting — note ingredient for patch tests."
            )
        ]
        let skincareBody = Routine.flattenedBody(from: skincareSteps)

        let walkSteps: [RoutineStep] = [
            RoutineStep(
                title: "Pre-flight checklist",
                instructions: "Lay clothes + shoes by the door. Check weather radar — grab wind shell if gusts > 25 km/h.",
                durationMinutes: 3,
                gear: [
                    RoutineGearItem(name: "Running shoes"),
                    RoutineGearItem(name: "GPS watch")
                ],
                notes: "Phone on Do Not Disturb; playlist queued."
            ),
            RoutineStep(
                title: "Hydration & warm-up",
                instructions: "150ml water + electrolyte tab. 90s ankle circles, calf pumps, two easy laps indoors.",
                durationMinutes: 4,
                gear: [
                    RoutineGearItem(name: "Soft flask"),
                    RoutineGearItem(name: "Headphones")
                ],
                notes: "Target RPE 2 — conversation pace."
            ),
            RoutineStep(
                title: "Main block — cadence lock",
                instructions: "Same playlist every day — no decision fatigue. Walk out within 2 minutes of alarm dismiss.",
                durationMinutes: 12,
                gear: [RoutineGearItem(name: "Playlist (locked order)")],
                notes: "Maintain 115–125 spm if tracking steps."
            ),
            RoutineStep(
                title: "Cool-down + mobility",
                instructions: "Slow last 3 minutes. Static hip flexor + calf stretch, 30s each side.",
                durationMinutes: 4,
                gear: [],
                notes: "Log perceived exertion 1–10 in Notes app."
            ),
            RoutineStep(
                title: "Recovery log",
                instructions: "Note distance, weather, any hotspots on feet. Swap insoles if arch feels flat.",
                durationMinutes: 2,
                gear: [RoutineGearItem(name: "Training journal")],
                notes: "Consistency beats intensity."
            )
        ]
        let walkBody = Routine.flattenedBody(from: walkSteps)

        let studySteps: [RoutineStep] = [
            RoutineStep(
                title: "Environment lock",
                instructions: "Phone in another room. Close irrelevant tabs. Timer visible at eye level.",
                durationMinutes: 3,
                gear: [
                    RoutineGearItem(name: "Analog timer"),
                    RoutineGearItem(name: "Noise isolating cans")
                ],
                notes: "Ambient 60–70 BPM instrumental only."
            ),
            RoutineStep(
                title: "Prime the pump",
                instructions: "Start with the smallest task to build momentum — one paragraph, one equation, one compile.",
                durationMinutes: 7,
                gear: [RoutineGearItem(name: "Index cards")],
                notes: "No inbox during this slice."
            ),
            RoutineStep(
                title: "Deep focus block",
                instructions: "50 min focus / 10 min break. Stand + sip every 25 min even if flow feels good.",
                durationMinutes: 50,
                gear: [],
                notes: "If stuck >6 min, write the blocker in one sentence and switch subtask."
            ),
            RoutineStep(
                title: "Hand-off note",
                instructions: "End block by writing the next first step on a sticky — place it on keyboard lid.",
                durationMinutes: 5,
                gear: [RoutineGearItem(name: "Sticky pad")],
                notes: "Makes tomorrow’s start frictionless."
            )
        ]
        let studyBody = Routine.flattenedBody(from: studySteps)

        let imgMorning = "https://images.unsplash.com/photo-1495616811223-4d98c6e9c869?auto=format&fit=crop&w=1400&q=80"
        let imgMeal = "https://images.unsplash.com/photo-1546069901-ba9599a7e63c?auto=format&fit=crop&w=1400&q=80"
        let imgTravel = "https://images.unsplash.com/photo-1488646953014-85cb44e25828?auto=format&fit=crop&w=1400&q=80"
        let imgHiit = "https://images.unsplash.com/photo-1517836357463-d25dfeac3438?auto=format&fit=crop&w=1400&q=80"
        let imgYoga = "https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?auto=format&fit=crop&w=1400&q=80"
        let imgBooks = "https://images.unsplash.com/photo-1512820790803-83ca734da794?auto=format&fit=crop&w=1400&q=80"

        let morningSteps: [RoutineStep] = [
            RoutineStep(
                title: "Light + water",
                instructions: "Open blinds fully. 300ml water before caffeine — rehydrate sleep debt first.",
                durationMinutes: 5,
                gear: [RoutineGearItem(name: "Glass bottle"), RoutineGearItem(name: "Daylight alarm")],
                notes: "No phone until water is finished."
            ),
            RoutineStep(
                title: "Movement snack",
                instructions: "8 cat-cow, 10 bodyweight squats, 30s wall sit. Heart rate up, joints oiled.",
                durationMinutes: 7,
                gear: [RoutineGearItem(name: "Yoga mat")],
                notes: "Keep nasal breathing."
            ),
            RoutineStep(
                title: "Intent line",
                instructions: "One sentence in notes: what would make today a win? Under twelve words.",
                durationMinutes: 3,
                gear: [RoutineGearItem(name: "Notebook")],
                notes: ""
            )
        ]
        let morningBody = Routine.flattenedBody(from: morningSteps)

        let mealPrepSteps: [RoutineStep] = [
            RoutineStep(
                title: "Mise en place",
                instructions: "Chop veg once for three meals. Label containers with eat-by dates.",
                durationMinutes: 25,
                gear: [RoutineGearItem(name: "Glass containers"), RoutineGearItem(name: "Chef knife")],
                notes: "Sharp knife = fewer slips."
            ),
            RoutineStep(
                title: "Batch cook",
                instructions: "Two sheet pans: protein + veg. Same oven temp, stagger start times.",
                durationMinutes: 40,
                gear: [RoutineGearItem(name: "Sheet pans"), RoutineGearItem(name: "Probe thermometer")],
                notes: "Rest proteins 5 min before slicing."
            )
        ]
        let mealPrepBody = Routine.flattenedBody(from: mealPrepSteps)

        let travelSteps: [RoutineStep] = [
            RoutineStep(
                title: "Pack cube logic",
                instructions: "Rolling method for knits; cubes for chargers and liquids separately.",
                durationMinutes: 15,
                gear: [RoutineGearItem(name: "Packing cubes"), RoutineGearItem(name: "Cable wrap")],
                notes: "Weigh bag before zipping."
            ),
            RoutineStep(
                title: "Documents + backup",
                instructions: "Passport photo on phone + printed hotel QR in jacket pocket, not checked bag.",
                durationMinutes: 8,
                gear: [RoutineGearItem(name: "Travel wallet")],
                notes: ""
            )
        ]
        let travelBody = Routine.flattenedBody(from: travelSteps)

        let hiitSteps: [RoutineStep] = [
            RoutineStep(
                title: "Warm-up",
                instructions: "Skipping or jog in place 3 min + dynamic leg swings both planes.",
                durationMinutes: 5,
                gear: [RoutineGearItem(name: "Jump rope")],
                notes: "RPE 5 max."
            ),
            RoutineStep(
                title: "Intervals",
                instructions: "12s all-out / 30s easy × 10 rounds. One movement per round: burpee, squat jump, high knees rotate.",
                durationMinutes: 18,
                gear: [RoutineGearItem(name: "Interval timer")],
                notes: "Stop if form breaks — sub marching."
            ),
            RoutineStep(
                title: "Flush",
                instructions: "Walk 3 min + slow quad stretch 45s each side.",
                durationMinutes: 5,
                gear: [],
                notes: ""
            )
        ]
        let hiitBody = Routine.flattenedBody(from: hiitSteps)

        let yogaSteps: [RoutineStep] = [
            RoutineStep(
                title: "Breath baseline",
                instructions: "4-7-8 breathing × 4 cycles seated. Shoulders away from ears.",
                durationMinutes: 4,
                gear: [RoutineGearItem(name: "Bolster")],
                notes: ""
            ),
            RoutineStep(
                title: "Slow flow",
                instructions: "Sun salutation A at half speed — pause in each downward dog 3 breaths.",
                durationMinutes: 20,
                gear: [RoutineGearItem(name: "Mat"), RoutineGearItem(name: "Blocks")],
                notes: "Knees down in chaturanga if wrists complain."
            )
        ]
        let yogaBody = Routine.flattenedBody(from: yogaSteps)

        let readSteps: [RoutineStep] = [
            RoutineStep(
                title: "Ambient lock",
                instructions: "Same chair, same lamp level, same playlist (instrumental only).",
                durationMinutes: 2,
                gear: [RoutineGearItem(name: "Reading light")],
                notes: ""
            ),
            RoutineStep(
                title: "Deep read block",
                instructions: "25 pages or one chapter — whichever comes first. Margin notes in pencil only.",
                durationMinutes: 35,
                gear: [RoutineGearItem(name: "Hardcover + pencil")],
                notes: "Phone in drawer, not face-down on desk."
            )
        ]
        let readBody = Routine.flattenedBody(from: readSteps)

        return [
            Routine(
                id: UUID(uuidString: "AAAAAAAA-BBBB-CCCC-DDDD-000000000001")!,
                title: "Soft launch GRWM",
                body: grwmBody,
                authorDisplayName: "Mara",
                createdAt: daysAgo(1),
                kind: .grwm,
                steps: grwmSteps,
                imageAttachmentIds: [],
                remoteCoverImageURLs: [imgGrwmHero, "https://images.unsplash.com/photo-1596462502278-27bfdc403348?auto=format&fit=crop&w=600&q=80"]
            ),
            Routine(
                id: UUID(uuidString: "AAAAAAAA-BBBB-CCCC-DDDD-000000000002")!,
                title: "Sunday reset skincare",
                body: skincareBody,
                authorDisplayName: "Jules",
                createdAt: daysAgo(3),
                kind: .skincare,
                steps: skincareSteps,
                imageAttachmentIds: [],
                remoteCoverImageURLs: [imgSkinHero, imgMask]
            ),
            Routine(
                id: UUID(uuidString: "AAAAAAAA-BBBB-CCCC-DDDD-000000000003")!,
                title: "20-minute morning walk",
                body: walkBody,
                authorDisplayName: "Alex",
                createdAt: daysAgo(5),
                kind: .fitness,
                steps: walkSteps,
                imageAttachmentIds: [],
                remoteCoverImageURLs: [imgRunHero, imgRunTrack, imgShoes]
            ),
            Routine(
                id: UUID(uuidString: "AAAAAAAA-BBBB-CCCC-DDDD-000000000004")!,
                title: "Study block that actually sticks",
                body: studyBody,
                authorDisplayName: "Sam",
                createdAt: daysAgo(7),
                kind: .study,
                steps: studySteps,
                imageAttachmentIds: [],
                remoteCoverImageURLs: [imgStudyHero, imgDesk]
            ),
            Routine(
                id: UUID(uuidString: "AAAAAAAA-BBBB-CCCC-DDDD-000000000005")!,
                title: "Golden hour wake — no scroll",
                body: morningBody,
                authorDisplayName: "Noa",
                createdAt: daysAgo(2),
                kind: .morning,
                steps: morningSteps,
                imageAttachmentIds: [],
                remoteCoverImageURLs: [imgMorning, "https://images.unsplash.com/photo-1506126613408-eca07ce68773?auto=format&fit=crop&w=900&q=80"]
            ),
            Routine(
                id: UUID(uuidString: "AAAAAAAA-BBBB-CCCC-DDDD-000000000006")!,
                title: "Sunday meal prep for two",
                body: mealPrepBody,
                authorDisplayName: "Riley",
                createdAt: daysAgo(4),
                kind: .other,
                steps: mealPrepSteps,
                customKindLabel: "Meal prep",
                imageAttachmentIds: [],
                remoteCoverImageURLs: [imgMeal, "https://images.unsplash.com/photo-1556910103-1c02745aae4d?auto=format&fit=crop&w=900&q=80"]
            ),
            Routine(
                id: UUID(uuidString: "AAAAAAAA-BBBB-CCCC-DDDD-000000000007")!,
                title: "Carry-on only — 48h trip",
                body: travelBody,
                authorDisplayName: "Dev",
                createdAt: daysAgo(6),
                kind: .other,
                steps: travelSteps,
                customKindLabel: "Travel",
                imageAttachmentIds: [],
                remoteCoverImageURLs: [imgTravel, "https://images.unsplash.com/photo-1565026057447-bc90a7d34399?auto=format&fit=crop&w=900&q=80"]
            ),
            Routine(
                id: UUID(uuidString: "AAAAAAAA-BBBB-CCCC-DDDD-000000000008")!,
                title: "HIIT living-room finisher",
                body: hiitBody,
                authorDisplayName: "Kai",
                createdAt: daysAgo(8),
                kind: .fitness,
                steps: hiitSteps,
                imageAttachmentIds: [],
                remoteCoverImageURLs: [imgHiit, imgRunTrack]
            ),
            Routine(
                id: UUID(uuidString: "AAAAAAAA-BBBB-CCCC-DDDD-000000000009")!,
                title: "Slow flow for tight hips",
                body: yogaBody,
                authorDisplayName: "Mina",
                createdAt: daysAgo(9),
                kind: .fitness,
                steps: yogaSteps,
                imageAttachmentIds: [],
                remoteCoverImageURLs: [imgYoga, "https://images.unsplash.com/photo-1508670166299-79c6f7e351e4?auto=format&fit=crop&w=900&q=80"]
            ),
            Routine(
                id: UUID(uuidString: "AAAAAAAA-BBBB-CCCC-DDDD-000000000010")!,
                title: "Analog reading hour",
                body: readBody,
                authorDisplayName: "Eli",
                createdAt: daysAgo(10),
                kind: .study,
                steps: readSteps,
                imageAttachmentIds: [],
                remoteCoverImageURLs: [imgBooks, imgDesk]
            )
        ]
    }()
}
