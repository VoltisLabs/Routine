import SwiftUI
import UIKit

struct RoutineFeedScroll: View {
    @Environment(RoutineLibrary.self) private var library
    @Environment(\.colorScheme) private var scheme
    @Environment(\.colorPalette) private var colorPalette

    private var feedRoutines: [Routine] {
        library.communityRoutines.sorted { $0.createdAt > $1.createdAt }
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 18) {
                Text("Trending & for you")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.primary)
                    .padding(.horizontal)

                Text("Tap any card for the full routine — skincare, fitness, study, mornings, and more.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)

                if feedRoutines.isEmpty {
                    ContentUnavailableView(
                        "No routines yet",
                        systemImage: "sparkles",
                        description: Text("Publish from Create to fill the feed.")
                    )
                    .padding(.top, 40)
                } else {
                    ForEach(feedRoutines) { routine in
                        NavigationLink(value: routine) {
                            RoutineFeedRealCard(routine: routine)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.vertical, 12)
            .padding(.bottom, 24)
        }
    }
}

struct RoutineFeedRealCard: View {
    let routine: Routine
    @Environment(\.colorScheme) private var scheme
    @Environment(\.colorPalette) private var colorPalette

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack(alignment: .bottomLeading) {
                RoutineCoverStrip(routine: routine, height: 160, cornerRadius: 20)
                    .allowsHitTesting(false)
                HStack(spacing: 8) {
                    Label(routine.displayKindTitle, systemImage: routine.kind.symbolName)
                        .font(.caption2.weight(.bold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(.ultraThinMaterial, in: Capsule())
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .padding(8)
                        .background(.ultraThinMaterial, in: Circle())
                }
                .padding(10)
            }

            Text(routine.title)
                .font(.headline)
                .foregroundStyle(.primary)

            Text(routine.feedPreview)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(3)
                .multilineTextAlignment(.leading)

            HStack {
                Label(routine.authorDisplayName, systemImage: "person.crop.circle.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Spacer(minLength: 8)
                Label("\(routine.stepCount) steps", systemImage: "list.number")
                    .font(.caption)
                    .foregroundStyle(ThemeColors.accent(for: scheme, palette: colorPalette))
                Image(systemName: "bookmark")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
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

/// Hero strip: first saved image or remote URL or gradient + icon.
struct RoutineCoverStrip: View {
    let routine: Routine
    var height: CGFloat = 160
    var cornerRadius: CGFloat = 20

    @Environment(\.colorScheme) private var scheme
    @Environment(\.colorPalette) private var colorPalette

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
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure:
                        fallbackGradient
                    default:
                        fallbackGradient
                            .overlay { ProgressView().tint(.white) }
                    }
                }
            } else {
                fallbackGradient
            }
        }
        .frame(height: height)
        .frame(maxWidth: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }

    private var fallbackGradient: some View {
        LinearGradient(
            colors: [
                ThemeColors.accent(for: scheme, palette: colorPalette).opacity(0.45),
                ThemeColors.secondaryAccent(for: scheme, palette: colorPalette).opacity(0.3)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay {
            Image(systemName: routine.kind.symbolName)
                .font(.system(size: 40))
                .foregroundStyle(.white.opacity(0.4))
        }
    }
}
