import AppKit
import SwiftUI

/// A plain-text editor for prompts and templates: every character stays exactly as typed.
struct VerbatimTextEditor: NSViewRepresentable {
    @Binding var text: String

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text)
    }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.drawsBackground = false
        scrollView.hasVerticalScroller = true
        scrollView.scrollerStyle = .overlay
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder

        let textView = NSTextView(usingTextLayoutManager: true)
        textView.delegate = context.coordinator
        textView.isRichText = false
        textView.importsGraphics = false
        textView.drawsBackground = false
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]
        textView.minSize = .zero
        textView.maxSize = NSSize(
            width: CGFloat.greatestFiniteMagnitude,
            height: CGFloat.greatestFiniteMagnitude)
        textView.textContainerInset = .zero
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.lineFragmentPadding = 0
        textView.allowsUndo = true
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.isAutomaticSpellingCorrectionEnabled = false
        textView.isContinuousSpellCheckingEnabled = false
        textView.isGrammarCheckingEnabled = false
        textView.smartInsertDeleteEnabled = false
        scrollView.documentView = textView
        context.coordinator.textView = textView
        context.coordinator.install(text)
        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        context.coordinator.binding = $text
        guard let textView = context.coordinator.textView else { return }
        textView.font = NSFont.preferredFont(forTextStyle: .body)
        textView.textColor = NSColor(Theme.Colors.textPrimary)
        textView.insertionPointColor = NSColor(Theme.Colors.textPrimary)
        guard textView.string != text else { return }
        context.coordinator.install(text)
    }

    @MainActor
    final class Coordinator: NSObject, NSTextViewDelegate {
        var binding: Binding<String>
        weak var textView: NSTextView?
        private var isInstalling = false

        init(text: Binding<String>) {
            binding = text
        }

        func install(_ text: String) {
            guard let textView else { return }
            let selection = textView.selectedRange()
            isInstalling = true
            textView.string = text
            textView.setSelectedRange(
                NSRange(location: min(selection.location, (text as NSString).length), length: 0))
            isInstalling = false
        }

        func textDidChange(_ notification: Notification) {
            guard !isInstalling, let textView else { return }
            binding.wrappedValue = textView.string
        }
    }
}
