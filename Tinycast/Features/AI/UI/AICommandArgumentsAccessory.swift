import SwiftUI

@MainActor
enum AICommandArgumentsAccessory {
    static func make(
        command: CustomAICommand?, entry: AppEntry?,
        values: @escaping (AICommandArgument) -> Binding<String>,
        focus: FocusState<String?>.Binding, onSubmit: @escaping () -> Void
    ) -> PaletteHeaderAccessory? {
        guard let command, !command.arguments.isEmpty, let entry else { return nil }
        let arguments = command.arguments
        return PaletteHeaderAccessory(
            width: AICommandArgumentsRow.totalWidth(for: arguments),
            fieldNames: arguments.map(\.id),
            firstIncompleteField: arguments.first {
                $0.isRequired && values($0).wrappedValue.isEmpty
            }?.id,
            view: AnyView(
                AICommandArgumentsRow(
                    arguments: arguments, icon: entry.iconSource, value: values,
                    focused: focus, onSubmit: onSubmit)))
    }
}

private struct AICommandArgumentsRow: View {
    let arguments: [AICommandArgument]
    let icon: EntryIcon
    let value: (AICommandArgument) -> Binding<String>
    @FocusState.Binding var focused: String?
    let onSubmit: () -> Void

    var body: some View {
        HStack(spacing: Theme.Spacing.xs) {
            EntryIconView(source: icon).frame(width: Self.height, height: Self.height)
            ForEach(arguments) { argument in
                AICommandArgumentField(
                    argument: argument, text: value(argument),
                    isFocused: focused == argument.id, onSubmit: onSubmit
                )
                .focused($focused, equals: argument.id)
            }
        }
    }

    static let height: CGFloat = 26

    static func totalWidth(for arguments: [AICommandArgument]) -> CGFloat {
        let fields = arguments.reduce(0) { $0 + fieldWidth(for: $1) }
        return height + CGFloat(arguments.count) * Theme.Spacing.xs + fields
    }

    static func fieldWidth(for argument: AICommandArgument) -> CGFloat {
        min(max(CGFloat(argument.inputPlaceholder.count) * 7 + 28, 72), 150)
    }
}

private struct AICommandArgumentField: View {
    let argument: AICommandArgument
    @Binding var text: String
    let isFocused: Bool
    let onSubmit: () -> Void
    @State private var hovered = false

    var body: some View {
        TextField(
            "", text: $text,
            prompt: Text(argument.inputPlaceholder).foregroundStyle(Theme.Colors.textTertiary)
        )
        .textFieldStyle(.plain)
        .font(Theme.Typography.rowTrailing)
        .tint(Theme.Colors.textPrimary)
        .onSubmit(onSubmit)
        .multilineTextAlignment(.center)
        .frame(width: AICommandArgumentsRow.fieldWidth(for: argument))
        .padding(.horizontal, Theme.Spacing.sm)
        .frame(height: AICommandArgumentsRow.height)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.row, style: .continuous).fill(fill)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.row, style: .continuous)
                .strokeBorder(stroke, lineWidth: 1)
        )
        .onHover { hovered = $0 }
        .help(argument.isRequired ? "\(argument.name) — required" : argument.detail)
        .accessibilityLabel(argument.name)
    }

    private var fill: Color {
        if isFocused { return Theme.Colors.selection }
        if hovered { return Theme.Colors.rowHover }
        return Theme.Colors.cardFill
    }

    private var stroke: Color {
        if isFocused { return Theme.Colors.textPrimary.opacity(0.35) }
        if argument.isRequired && text.isEmpty { return Color.orange.opacity(0.45) }
        return Theme.Colors.cardStroke
    }
}
