import SwiftUI

/// One action's own route, staged by the editor panel that presents it until Save.
struct QuickActionModelPicker: View {
    @Binding var selection: AIModelSelection?
    @Environment(AppCore.self) private var core

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Model")
                .font(.callout.weight(.medium))
            HStack(spacing: Theme.Spacing.lg) {
                AIModelSelectionRows(
                    selection: selection,
                    inheritedTitle: "Same as Quick Actions",
                    showsSourceInOptionTitle: true,
                    select: { selection = $0 },
                    modelLabel: { Text("Model") },
                    effortLabel: { Text("Reasoning effort") })
            }
            .labelsHidden()
        }
        .onAppear { core.aiChatCoordinator.prepareModelSwitcher() }
    }
}
