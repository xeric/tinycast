import SwiftUI

/// AI's built-ins and custom prompt commands, each independently bindable and hideable.
struct AICommandSection: View {
    @Environment(VisibilityStore.self) private var visibility
    @Environment(AISettingsStore.self) private var settings
    @Environment(AppCore.self) private var core
    @State private var editor: AICommandEditorTarget?

    var body: some View {
        Section {
            ForEach(CommandCatalog.entries(ownedBy: .ai)) { entry in
                FeatureCommandRow(entry: entry)
            }
            ForEach(sortedCommands) { command in
                let entry = AppEntry(command)
                AICommandSettingsRow(
                    entry: entry, name: command.name, prompt: command.prompt,
                    action: .customAICommand(id: command.id),
                    isVisible: visibilityBinding(entry),
                    onEdit: { editor = AICommandEditorTarget(command: command) },
                    onDelete: { confirmDeletion(command) })
            }
            Button {
                editor = AICommandEditorTarget(command: nil)
            } label: {
                SettingsRowTitle(.aiCommands, "Add Custom AI Command")
            }
        } header: {
            SettingsSectionHeader(.aiCommands)
        } footer: {
            Text("The shortcut works even when the command is hidden from the launcher.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .sheet(item: $editor) { target in
            AICommandEditorSheet(command: target.command)
        }
    }

    private var sortedCommands: [CustomAICommand] {
        settings.customCommands.sorted {
            $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
    }

    private func confirmDeletion(_ command: CustomAICommand) {
        Task {
            guard
                await core.confirm(
                    title: "Delete “\(command.name)”?”",
                    message: "Its global shortcut and launcher references will also be removed.",
                    symbol: "trash", confirmTitle: "Delete", confirmRole: .destructive)
            else { return }
            core.aiChatCoordinator.deleteCustomAICommand(id: command.id)
        }
    }

    private func visibilityBinding(_ entry: AppEntry) -> Binding<Bool> {
        Binding(
            get: { visibility.isItemVisible(entry) },
            set: { visibility.setItemVisible($0, for: entry) })
    }
}

private struct AICommandEditorTarget: Identifiable {
    let id = UUID()
    let command: CustomAICommand?
}

private struct AICommandSettingsRow: View {
    let entry: AppEntry
    let name: String
    let prompt: String?
    let action: HotKeyAction
    @Binding var isVisible: Bool
    var onEdit: (() -> Void)?
    var onDelete: (() -> Void)?

    var body: some View {
        SettingsRow(title: name, subtitle: prompt) {
            Image(systemName: CustomAICommand.sfSymbol)
                .frame(width: Theme.Size.settingsRowIcon)
        } trailing: {
            AliasField(entry: entry)
            ShortcutRecorder(action: action)
            if let onEdit {
                Button(action: onEdit) { Image(systemName: "pencil") }
                    .buttonStyle(.plain)
                    .help("Edit AI Command")
                    .accessibilityLabel("Edit \(name)")
            }
            if let onDelete {
                Button(action: onDelete) {
                    Image(systemName: "trash").foregroundStyle(.red)
                }
                .buttonStyle(.plain)
                .help("Delete AI Command")
                .accessibilityLabel("Delete \(name)")
            }
            Toggle("", isOn: $isVisible)
                .labelsHidden()
                .toggleStyle(.checkbox)
                .accessibilityLabel("Show \(name) in launcher")
        }
    }
}
