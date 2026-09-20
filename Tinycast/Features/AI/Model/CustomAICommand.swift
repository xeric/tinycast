import Foundation

struct CustomAICommand: Codable, Hashable, Identifiable, Sendable {
    static let entryIDPrefix = "ai-command:"
    static let sfSymbol = "sparkles"

    let id: UUID
    var name: String
    var prompt: String
    var model: AIModelSelection?

    init(
        id: UUID = UUID(), name: String, prompt: String,
        model: AIModelSelection? = nil
    ) {
        self.id = id
        self.name = name
        self.prompt = prompt
        self.model = model
    }

    var entryID: String { Self.entryIDPrefix + id.uuidString.lowercased() }
    var arguments: [AICommandArgument] { AICommandTemplate(prompt).arguments }

    func renderedPrompt(arguments values: [String: String]) -> String {
        AICommandTemplate(prompt).render(values: values)
    }

    func firstArgumentIDAfterSpace(previousQuery: String, newQuery: String) -> String? {
        guard let first = arguments.first, newQuery == previousQuery + " " else { return nil }
        let typedName = previousQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard typedName.compare(name, options: [.caseInsensitive, .diacriticInsensitive]) == .orderedSame
        else { return nil }
        return first.id
    }

    static func id(fromEntryID entryID: String) -> UUID? {
        guard entryID.hasPrefix(entryIDPrefix) else { return nil }
        return UUID(uuidString: String(entryID.dropFirst(entryIDPrefix.count)))
    }
}

enum CustomAICommandValidationError: LocalizedError {
    case emptyName
    case emptyPrompt
    case invalidArguments(String)
    case duplicateName
    case invalidCharacter

    var errorDescription: String? {
        switch self {
        case .emptyName: return "Enter a name for the AI command."
        case .emptyPrompt: return "Enter a prompt for the AI command."
        case .invalidArguments(let message): return message
        case .duplicateName: return "An AI command with this name already exists."
        case .invalidCharacter: return "Names and prompts cannot contain null characters."
        }
    }
}
