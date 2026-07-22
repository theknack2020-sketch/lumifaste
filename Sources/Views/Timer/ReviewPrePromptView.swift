import SwiftUI

/// The honest in-app review pre-prompt — a warm "Enjoying Lumifaste?" card
/// surfaced only at a peak moment (a completed fast, see ``ReviewPromptManager``).
/// A happy tap opens Apple's native rating prompt; an unhappy tap opens private
/// feedback so a gripe reaches us in Mail instead of a public one-star.
///
/// This is the honest "flavor a" pattern: a genuine two-option ask. It is never a
/// fake star UI that secretly routes 1–3 taps to feedback and 4–5 to the App
/// Store — Apple's HIG discourages that review-gating and it clashes with the
/// TheKnack honest-brand rule (canonical: Sillora `ReviewPrePromptView`).
struct ReviewPrePromptView: View {
    let onLove: () -> Void
    let onFeedback: () -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(ThemeManager.self) private var themeManager

    var body: some View {
        VStack(spacing: 22) {
            ZStack {
                Circle()
                    .fill(themeManager.selectedTheme.accentGradient)
                    .frame(width: 66, height: 66)
                Image(systemName: "leaf.fill")
                    .font(.system(size: 27, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .accessibilityHidden(true)

            VStack(spacing: 6) {
                Text("Enjoying Lumifaste?")
                    .font(.system(.title2, design: .rounded, weight: .bold))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)

                Text("A quick word helps other fasters find it — and if something's off, tell us and we'll fix it.")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(spacing: 10) {
                Button {
                    HapticManager.shared.success()
                    onLove()
                    dismiss()
                } label: {
                    Text("I love it")
                        .font(.system(.body, design: .rounded, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, minHeight: 52)
                        .background(themeManager.selectedTheme.accentGradient, in: .rect(cornerRadius: 15, style: .continuous))
                }
                .buttonStyle(.plain)
                .accessibilityHint("Opens the App Store rating prompt")

                Button {
                    HapticManager.shared.selectionChanged()
                    onFeedback()
                    dismiss()
                } label: {
                    Text("Could be better")
                        .font(.system(.body, design: .rounded, weight: .medium))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, minHeight: 46)
                }
                .buttonStyle(.plain)
                .accessibilityHint("Opens a private feedback email")
            }
        }
        .padding(28)
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
        .presentationDetents([.height(370)])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(28)
    }
}

#if DEBUG
    #Preview("Review pre-prompt") {
        Color.black.opacity(0.2)
            .sheet(isPresented: .constant(true)) {
                ReviewPrePromptView(onLove: {}, onFeedback: {})
                    .environment(ThemeManager())
            }
    }
#endif
