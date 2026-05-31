import AppKit
import VoiceAgentInputCore

@MainActor
final class CandidateApprovalDialogController {
    func approveCandidatesIfRequested(_ candidates: [CorrectionCandidate], maximumVisibleCandidates: Int = 8) throws {
        guard !candidates.isEmpty else {
            return
        }

        let limitedCandidates = Array(candidates.prefix(maximumVisibleCandidates))
        let alert = NSAlert()
        alert.messageText = "Approve dictionary candidates?"
        alert.informativeText = "Selected candidates will be reused in later prompts."

        let stack = NSStackView()
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 8

        let checkboxes = limitedCandidates.map { candidate in
            let candidateStack = NSStackView()
            candidateStack.orientation = .vertical
            candidateStack.alignment = .leading
            candidateStack.spacing = 2

            let checkbox = NSButton(
                checkboxWithTitle: "\(candidate.rawPhrase) -> \(candidate.correctedPhrase)",
                target: nil,
                action: nil
            )
            checkbox.state = candidate.dangerous ? .off : .on
            checkbox.toolTip = candidate.dangerous ? "Dangerous command candidates are not selected by default." : nil
            candidateStack.addArrangedSubview(checkbox)

            let detail = NSTextField(labelWithString: candidateDetailText(candidate))
            detail.font = .systemFont(ofSize: NSFont.smallSystemFontSize)
            detail.textColor = .secondaryLabelColor
            detail.lineBreakMode = .byWordWrapping
            detail.maximumNumberOfLines = 3
            detail.preferredMaxLayoutWidth = 480
            candidateStack.addArrangedSubview(detail)

            stack.addArrangedSubview(candidateStack)
            return checkbox
        }

        alert.accessoryView = stack
        alert.addButton(withTitle: "Save Selected")
        alert.addButton(withTitle: "Skip")

        guard alert.runModal() == .alertFirstButtonReturn else {
            return
        }

        let selectedIndexes = Set(checkboxes.enumerated().compactMap { index, checkbox in
            checkbox.state == .on ? index : nil
        })
        let store = LocalLearningDictionaryStore(directoryURL: try LocalLearningDictionaryStore.defaultDirectoryURL())
        let repository = try store.repository()
        _ = try LearningApprovalUseCase(repository: repository).approveSelectedCandidates(
            limitedCandidates,
            selectedIndexes: selectedIndexes
        )
    }

    private func candidateDetailText(_ candidate: CorrectionCandidate) -> String {
        let percent = Int((candidate.confidence * 100).rounded())
        let safety = candidate.dangerous ? "Dangerous, review manually" : "Auto-apply eligible"
        return "\(safety) · Confidence \(percent)% · \(candidate.reason)"
    }
}
