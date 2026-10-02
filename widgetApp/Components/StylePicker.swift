import SwiftUI

/// Style selection control. The mapping from style to typography and color
/// lives on `MessageStyle`, so this control only collects the user's choice.
struct StylePicker: View {
    @Binding var selection: MessageStyle

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Text Style")
                .font(AppTypography.cardTitle)
                .foregroundStyle(AppColors.textPrimary)

            Picker("Text Style", selection: $selection) {
                ForEach(MessageStyle.allCases) { style in
                    Text(style.title)
                        .tag(style)
                }
            }
            .pickerStyle(.segmented)
            .accessibilityLabel("Text style")
            .accessibilityValue(selection.title)

            Text(selection.accessibilityDescription)
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.textMuted)
                .accessibilityHidden(true)
        }
        .accessibilityElement(children: .contain)
    }
}
