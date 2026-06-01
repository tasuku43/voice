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
        let accessory = makeAccessoryView(candidates: limitedCandidates)
        alert.accessoryView = accessory.view
        alert.addButton(withTitle: "Save Selected")
        alert.addButton(withTitle: "Skip")

        guard alert.runModal() == .alertFirstButtonReturn else {
            return
        }

        let selectedIndexes = Set(accessory.checkboxes.enumerated().compactMap { index, checkbox in
            checkbox.state == .on ? index : nil
        })
        let store = LocalLearningDictionaryStore(directoryURL: try LocalLearningDictionaryStore.defaultDirectoryURL())
        let repository = try store.repository()
        _ = try LearningApprovalUseCase(repository: repository).approveSelectedCandidates(
            limitedCandidates,
            selectedIndexes: selectedIndexes
        )
    }

    func makeAccessoryView(candidates: [CorrectionCandidate]) -> CandidateApprovalAccessoryView {
        let stack = AppLayout.formStack(width: AppLayout.accessoryWidth)

        let checkboxes = candidates.map { candidate in
            let candidateStack = NSStackView()
            candidateStack.orientation = .vertical
            candidateStack.alignment = .leading
            candidateStack.spacing = 4
            candidateStack.translatesAutoresizingMaskIntoConstraints = false
            candidateStack.widthAnchor.constraint(equalToConstant: AppLayout.accessoryWidth).isActive = true

            let checkbox = NSButton(
                checkboxWithTitle: "",
                target: nil,
                action: nil
            )
            checkbox.state = candidate.dangerous ? .off : .on
            checkbox.toolTip = candidate.dangerous ? "Dangerous command candidates are not selected by default." : nil

            let title = AppLayout.wrappingLabel(
                "\(candidate.rawPhrase) -> \(candidate.correctedPhrase)",
                width: AppLayout.accessoryWidth - 28,
                maximumLines: 2
            )
            title.font = .systemFont(ofSize: NSFont.systemFontSize, weight: .medium)
            title.lineBreakMode = .byCharWrapping

            let titleRow = NSStackView()
            titleRow.orientation = .horizontal
            titleRow.alignment = .firstBaseline
            titleRow.spacing = 6
            titleRow.translatesAutoresizingMaskIntoConstraints = false
            titleRow.addArrangedSubview(checkbox)
            titleRow.addArrangedSubview(title)
            candidateStack.addArrangedSubview(titleRow)

            let detail = NSTextField(labelWithString: candidateDetailText(candidate))
            detail.font = .systemFont(ofSize: NSFont.smallSystemFontSize)
            detail.textColor = .secondaryLabelColor
            detail.lineBreakMode = .byWordWrapping
            detail.maximumNumberOfLines = 4
            detail.preferredMaxLayoutWidth = AppLayout.accessoryWidth - 28
            detail.translatesAutoresizingMaskIntoConstraints = false
            detail.widthAnchor.constraint(equalToConstant: AppLayout.accessoryWidth - 28).isActive = true
            candidateStack.addArrangedSubview(detail)

            stack.addArrangedSubview(candidateStack)
            return checkbox
        }

        return CandidateApprovalAccessoryView(view: stack, checkboxes: checkboxes)
    }

    private func candidateDetailText(_ candidate: CorrectionCandidate) -> String {
        let percent = Int((candidate.confidence * 100).rounded())
        let safety = candidate.dangerous ? "Dangerous, review manually" : "Auto-apply eligible"
        return "\(safety) · Confidence \(percent)% · \(candidate.reason)"
    }
}

@MainActor
struct CandidateApprovalAccessoryView {
    var view: NSView
    var checkboxes: [NSButton]
}
