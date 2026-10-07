import SwiftUI

/// Step-by-step navigation guide reached from About → Usage.
///
/// Every step describes a real control in the app, so the guide doubles as the
/// accessibility walkthrough of the product.
struct UsageView: View {
    /// One instruction in the guide.
    private struct Step: Identifiable {
        let id = UUID()
        let symbol: String
        let title: String
        let detail: String
    }

    private let steps: [Step] = [
        Step(
            symbol: "square.and.pencil",
            title: "Write your message",
            detail: "Open the Messages tab and tap the plus button in the top right. Type what you want your widget to say."
        ),
        Step(
            symbol: "calendar",
            title: "Choose when it appears",
            detail: "Turn on “Schedule for a specific time” to pick a date and time, then tap repeat days if the message should come back every week."
        ),
        Step(
            symbol: "paintbrush",
            title: "Pick a text style",
            detail: "Bold, Casual or Formal change how the message is rendered on the widget. The preview below the picker shows the real result."
        ),
        Step(
            symbol: "checkmark.circle",
            title: "Save",
            detail: "Tap Save in the top right. The message is written to shared storage and the widget is refreshed straight away."
        ),
        Step(
            symbol: "plus.app",
            title: "Add the widget",
            detail: "Touch and hold the Home Screen or Lock Screen, tap the plus button, search for Whisper and add the widget."
        ),
        Step(
            symbol: "slider.horizontal.3",
            title: "Edit, delete or start over",
            detail: "Tap any row to open it, where you can edit or delete it. Settings → Delete all messages clears the whole library."
        )
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.sectionSpacing) {
                header

                ForEach(Array(steps.enumerated()), id: \.element.id) { index, step in
                    stepCard(step, number: index + 1)
                        .transition(.whisperRise)
                        .animation(
                            AppMotion.entrance.delay(Double(min(index, AppMotion.staggerCap)) * AppMotion.stagger),
                            value: steps.count
                        )
                }
            }
            .padding(AppTheme.sectionSpacing)
        }
        .scrollBounceBehavior(.basedOnSize)
        .whisperScreenBackground()
        .navigationTitle("Usage")
        .navigationBarTitleDisplayMode(.inline)
        .whisperToolbarBackground()
    }

    // MARK: - Pieces

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("How to use WhisperWidget")
                .font(AppTypography.sectionTitle)
                .foregroundStyle(AppColors.textPrimary)

            Text("Six steps from a blank library to a message on your widget.")
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.textMuted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, 4)
    }

    private func stepCard(_ step: Step, number: Int) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Text("\(number)")
                .font(AppTypography.stepNumber)
                .foregroundStyle(AppColors.surface)
                .frame(width: 26, height: 26)
                .background(AppColors.accent)
                .clipShape(Circle())
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 6) {
                Label {
                    Text(step.title)
                        .font(AppTypography.cardTitle)
                        .foregroundStyle(AppColors.textPrimary)
                } icon: {
                    Image(systemName: step.symbol)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(AppColors.accent)
                }

                Text(step.detail)
                    .font(AppTypography.body)
                    .foregroundStyle(AppColors.textMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Spacer(minLength: 0)
        }
        .whisperCard(cornerRadius: AppTheme.controlCornerRadius, padding: 14)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Step \(number). \(step.title). \(step.detail)")
    }
}
