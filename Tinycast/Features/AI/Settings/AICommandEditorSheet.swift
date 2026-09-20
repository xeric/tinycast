import SwiftUI

struct AICommandEditorSheet: View {
    let command: CustomAICommand?

    @Environment(\.dismiss) private var dismiss
    @Environment(AppCore.self) private var core
    @State private var name: String
    @State private var prompt: String
    @State private var model: AIModelSelection?
    @State private var errorMessage: String?

    init(command: CustomAICommand?) {
        self.command = command
        _name = State(initialValue: command?.name ?? "")
        _prompt = State(initialValue: command?.prompt ?? "")
        _model = State(initialValue: command?.model)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
            Text(command == nil ? "Add Custom AI Command" : "Edit Custom AI Command")
                .font(.title2.weight(.bold))

            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                Text("Name")
                    .font(.callout.weight(.medium))
                TextField("Summarize This", text: $name)
                    .textFieldStyle(.roundedBorder)
            }

            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                Text("Prompt")
                    .font(.callout.weight(.medium))
                VerbatimTextEditor(text: $prompt)
                    .padding(Theme.Spacing.sm)
                    .frame(height: Theme.Size.editorTextHeight)
                    .background(
                        RoundedRectangle(cornerRadius: Theme.Radius.row, style: .continuous)
                            .fill(Theme.Colors.cardFill)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.Radius.row, style: .continuous)
                            .strokeBorder(Theme.Colors.cardStroke, lineWidth: 1)
                    )
            }
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                Text("Model")
                    .font(.callout.weight(.medium))
                Picker("Model", selection: $model) {
                    Text(defaultModelTitle)
                        .tag(nil as AIModelSelection?)
                    ForEach(core.aiChatCoordinator.modelOptions) { option in
                        Text("\(option.title) — \(option.sourceTitle)")
                            .tag(Optional(option.selection))
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                Text("Arguments (\(template.arguments.count)/\(AICommandTemplate.maximumArgumentCount))")
                    .font(.callout.weight(.medium))
                if template.arguments.isEmpty {
                    Text("Add up to three {argument} or {argument name=\"Language\"} placeholders.")
                        .foregroundStyle(Theme.Colors.textSecondary)
                } else {
                    ForEach(template.arguments) { argument in
                        HStack {
                            Text(argument.name)
                            Spacer()
                            Text(argument.detail)
                                .foregroundStyle(Theme.Colors.textSecondary)
                        }
                    }
                }
                if let issue = template.issue {
                    Text(issue.localizedDescription)
                        .foregroundStyle(.orange)
                }
            }
            .font(.caption)

            Text("Arguments are parsed from the prompt and inserted when you run this command.")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text("Default follows AI Settings; choosing a model pins this command to its provider and model.")
                .font(.caption)
                .foregroundStyle(.secondary)

            if let errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.orange)
            }

            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button("Save", action: save)
                    .keyboardShortcut(.defaultAction)
                    .disabled(!canSave)
            }
        }
        .padding(Theme.Spacing.xxl)
        .frame(width: Theme.Size.editorSheetWidth)
        .onChange(of: name) { errorMessage = nil }
        .onChange(of: prompt) { errorMessage = nil }
        .onChange(of: model) { errorMessage = nil }
        .onAppear { core.aiChatCoordinator.prepareModelSwitcher() }
    }

    private var defaultModelTitle: String {
        "Default · \(core.aiChatCoordinator.selectedModelTitle)"
    }

    private var template: AICommandTemplate { AICommandTemplate(prompt) }

    private var normalizedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var normalizedPrompt: String {
        prompt.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var canSave: Bool {
        guard !normalizedName.isEmpty, !normalizedPrompt.isEmpty, template.issue == nil else {
            return false
        }
        guard let command else { return true }
        return normalizedName != command.name || normalizedPrompt != command.prompt
            || model != command.model
    }

    private func save() {
        let draft = CustomAICommand(
            id: command?.id ?? UUID(), name: name, prompt: prompt, model: model)
        do {
            if command == nil {
                try core.aiChatCoordinator.addCustomAICommand(draft)
            } else {
                try core.aiChatCoordinator.updateCustomAICommand(draft)
            }
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
