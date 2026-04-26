import SwiftUI
import UIKit

// MARK: - Layout

enum ITGirlLayoutMetrics {
    /// Full-width scroll screens (routine detail, etc.): explicit inset so content never hugs the bezel.
    static let scrollContentHorizontalInset: CGFloat = 20
}

// MARK: - Screen backdrop

struct ItGirlScreenBackdrop: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.colorPalette) private var colorPalette
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.animation(minimumInterval: reduceMotion ? 60 : 2.5, paused: false)) { timeline in
            let phase = reduceMotion ? 0.0 : timeline.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 6) / 6
            ZStack {
                ThemeColors.backdropGradient(for: scheme, palette: colorPalette)
                RadialGradient(
                    colors: [
                        ThemeColors.secondaryAccent(for: scheme, palette: colorPalette).opacity(0.22),
                        .clear
                    ],
                    center: UnitPoint(x: 0.15 + phase * 0.2, y: 0.1 + phase * 0.15),
                    startRadius: 20,
                    endRadius: 380
                )
                .blendMode(.plusLighter)
                .animation(reduceMotion ? nil : .easeInOut(duration: 3), value: phase)
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Cards & headers

struct ItGirlCard<Content: View>: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.colorPalette) private var colorPalette
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(18)
            .background {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(ThemeColors.cardFill(for: scheme, palette: colorPalette))
                    .shadow(color: ThemeColors.cardShadow(for: scheme, palette: colorPalette), radius: 14, y: 6)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                ThemeColors.accent(for: scheme, palette: colorPalette).opacity(0.5),
                                ThemeColors.secondaryAccent(for: scheme, palette: colorPalette).opacity(0.35)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
    }
}

struct ItGirlSectionHeader: View {
    let title: String
    let systemImage: String

    @Environment(\.colorScheme) private var scheme
    @Environment(\.colorPalette) private var colorPalette

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: systemImage)
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
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 4)
    }
}

/// Primary CTAs — liquid glass (material + specular edge + soft depth).
struct LiquidGlassPrimaryButtonStyle: ButtonStyle {
    let accent: Color
    @Environment(\.colorScheme) private var scheme
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(.primary)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .padding(.horizontal, 10)
            .opacity(isEnabled ? 1 : 0.45)
            .background {
                ZStack {
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .fill(.ultraThinMaterial)
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .fill(accent.opacity(scheme == .dark ? 0.22 : 0.14))
                        .blendMode(.plusLighter)
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(scheme == .dark ? 0.42 : 0.72),
                                    Color.white.opacity(0.06)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                }
                .shadow(
                    color: Color.black.opacity(scheme == .dark ? 0.45 : 0.14),
                    radius: configuration.isPressed ? 6 : 18,
                    y: configuration.isPressed ? 2 : 9
                )
            }
            .scaleEffect(configuration.isPressed && isEnabled && !reduceMotion ? 0.97 : 1.0)
            .animation(reduceMotion ? nil : .spring(response: 0.32, dampingFraction: 0.74), value: configuration.isPressed)
    }
}

// MARK: - Rounded inputs (~2× default corner radius)

struct ITGirlRoundedFieldModifier: ViewModifier {
    @Environment(\.colorScheme) private var scheme

    func body(content: Content) -> some View {
        content
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color(uiColor: .secondarySystemGroupedBackground))
            }
            .overlay {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(Color.primary.opacity(scheme == .dark ? 0.12 : 0.08), lineWidth: 1)
            }
    }
}

extension View {
    func itGirlRoundedField() -> some View {
        modifier(ITGirlRoundedFieldModifier())
    }
}

extension View {
    func itGirlListChrome() -> some View {
        self
            .scrollContentBackground(.hidden)
    }

    func itGirlAppearAnimation(playful: Bool) -> some View {
        modifier(ItGirlAppearAnimationModifier(playful: playful))
    }
}

private struct ItGirlAppearAnimationModifier: ViewModifier {
    let playful: Bool
    @State private var appeared = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : ((playful && !reduceMotion) ? 10 : 0))
            .onAppear {
                guard playful, !reduceMotion else {
                    appeared = true
                    return
                }
                withAnimation(.spring(response: 0.52, dampingFraction: 0.82)) {
                    appeared = true
                }
            }
    }
}
