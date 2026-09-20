import Foundation

struct AICommandArgument: Hashable, Identifiable, Sendable {
    let id: String
    let name: String
    let defaultValue: String?
    let options: [String]

    var isRequired: Bool { defaultValue == nil }
    var inputPlaceholder: String {
        if let defaultValue { return "\(name): \(defaultValue)" }
        if !options.isEmpty { return "\(name): \(options.joined(separator: " / "))" }
        return name
    }

    var detail: String {
        if let defaultValue { return "Default: \(defaultValue)" }
        if !options.isEmpty { return options.joined(separator: ", ") }
        return "Required"
    }
}

struct AICommandTemplate {
    static let maximumArgumentCount = 3

    enum Issue: LocalizedError, Equatable {
        case invalidArgument
        case tooManyArguments

        var errorDescription: String? {
            switch self {
            case .invalidArgument:
                return "Use {argument} or {argument name=\"Name\"}."
            case .tooManyArguments:
                return "AI commands support at most three arguments."
            }
        }
    }

    let prompt: String
    let arguments: [AICommandArgument]
    let issue: Issue?
    private let occurrences: [Occurrence]

    init(_ prompt: String) {
        var arguments: [AICommandArgument] = []
        var occurrences: [Occurrence] = []
        var issue: Issue?
        var cursor = prompt.startIndex
        var anonymousCount = 0

        while let opening = prompt.range(of: "{argument", range: cursor..<prompt.endIndex) {
            let bodyStart = opening.upperBound
            guard bodyStart < prompt.endIndex else {
                issue = .invalidArgument
                break
            }
            let next = prompt[bodyStart]
            guard next == "}" || next.isWhitespace || next == "|" else {
                cursor = bodyStart
                continue
            }
            guard let closing = prompt[bodyStart...].firstIndex(of: "}") else {
                issue = .invalidArgument
                break
            }

            let body = String(prompt[bodyStart..<closing])
            guard let specification = Self.specification(body) else {
                issue = .invalidArgument
                break
            }
            let id: String
            let name: String
            if let declaredName = specification.name {
                id = "named:\(declaredName)"
                name = declaredName
            } else {
                anonymousCount += 1
                id = "anonymous:\(anonymousCount)"
                name = "Argument \(anonymousCount)"
            }

            if !arguments.contains(where: { $0.id == id }) {
                arguments.append(
                    AICommandArgument(
                        id: id, name: name, defaultValue: specification.defaultValue,
                        options: specification.options))
                if arguments.count > Self.maximumArgumentCount {
                    issue = .tooManyArguments
                    break
                }
            }

            let end = prompt.index(after: closing)
            occurrences.append(
                Occurrence(range: opening.lowerBound..<end, argumentID: id, isRaw: specification.isRaw))
            cursor = end
        }

        self.prompt = prompt
        self.arguments = Array(arguments.prefix(Self.maximumArgumentCount))
        self.occurrences = occurrences
        self.issue = issue
    }

    func render(values: [String: String]) -> String {
        var rendered = prompt
        let byID = Dictionary(uniqueKeysWithValues: arguments.map { ($0.id, $0) })
        for occurrence in occurrences.reversed() {
            guard let argument = byID[occurrence.argumentID] else { continue }
            let value = values[argument.id] ?? argument.defaultValue ?? ""
            let replacement = occurrence.isRaw ? value : "\"\"\"\(value)\"\"\""
            rendered.replaceSubrange(occurrence.range, with: replacement)
        }
        return rendered
    }

    private struct Occurrence {
        let range: Range<String.Index>
        let argumentID: String
        let isRaw: Bool
    }

    private struct Specification {
        let name: String?
        let defaultValue: String?
        let options: [String]
        let isRaw: Bool
    }

    private static func specification(_ body: String) -> Specification? {
        let name = attribute("name", in: body)
        let defaultValue = attribute("default", in: body)
        let options =
            attribute("options", in: body)?
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty } ?? []
        guard !mentionsAttribute("name", in: body) || name?.isEmpty == false,
            !mentionsAttribute("default", in: body) || defaultValue != nil,
            !mentionsAttribute("options", in: body) || !options.isEmpty
        else { return nil }
        return Specification(
            name: name, defaultValue: defaultValue, options: options,
            isRaw: body.split(separator: "|").dropFirst().contains {
                $0.trimmingCharacters(in: .whitespacesAndNewlines) == "raw"
            })
    }

    private static func attribute(_ name: String, in body: String) -> String? {
        guard var cursor = valueStart(for: name, in: body), cursor < body.endIndex else { return nil }
        let openingQuote = body[cursor]
        let closingQuote: Character
        switch openingQuote {
        case "\"": closingQuote = "\""
        case "“", "”": closingQuote = "”"
        default: return nil
        }
        cursor = body.index(after: cursor)
        guard let end = body[cursor...].firstIndex(of: closingQuote) else { return nil }
        return String(body[cursor..<end])
    }

    private static func mentionsAttribute(_ name: String, in body: String) -> Bool {
        valueStart(for: name, in: body) != nil
    }

    private static func valueStart(for name: String, in body: String) -> String.Index? {
        var searchStart = body.startIndex
        while let range = body.range(of: name, range: searchStart..<body.endIndex) {
            let startsToken =
                range.lowerBound == body.startIndex
                || body[body.index(before: range.lowerBound)].isWhitespace
            var cursor = range.upperBound
            while cursor < body.endIndex, body[cursor].isWhitespace {
                cursor = body.index(after: cursor)
            }
            if startsToken, cursor < body.endIndex, body[cursor] == "=" {
                cursor = body.index(after: cursor)
                while cursor < body.endIndex, body[cursor].isWhitespace {
                    cursor = body.index(after: cursor)
                }
                return cursor
            }
            searchStart = range.upperBound
        }
        return nil
    }
}
