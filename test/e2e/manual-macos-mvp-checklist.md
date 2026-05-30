# Manual macOS MVP checklist

Use this checklist on a real macOS desktop session after `make check` builds `.build/VoiceAgentInput.app`.

## Setup

1. Open `.build/VoiceAgentInput.app`.
2. Confirm the menu bar item titled `Voice` appears.
3. Open a text target such as TextEdit, Codex, Claude Code, Cursor, or a terminal prompt.

## Permission Status

1. Choose `Permission Status...`.
2. Verify the dialog reports:
   - `Microphone`
   - `Speech recognition`
   - `Accessibility paste`
3. Choose `Open Privacy Settings...` and verify macOS opens Privacy & Security settings.
4. If microphone or speech recognition is not authorized, continue to the recording flow and verify macOS prompts for the missing permission.
5. If Accessibility paste is not trusted, keep the fallback behavior expectation below.

## Recording Settings

1. Choose `Recording Settings...`.
2. Set recording duration to `4`.
3. Set Speech locale to `ja-JP`.
4. Save the dialog.
5. Reopen `Recording Settings...` and verify the saved values are shown.

## Mock Preview Safety

1. Choose `Mock Preview`.
2. Verify the preview shows both raw transcript and corrected prompt.
3. Edit the corrected prompt.
4. Confirm paste.
5. Verify no automatic submit happens in the target app.
6. Verify dictionary candidates are shown for approval when the edit creates candidates.

## Real Voice Input

1. Focus the target text app.
2. Trigger voice input with Command-Shift-Space or choose `Record Voice Input`.
3. Speak a short Japanese / mixed developer instruction such as `くらのコードでタイプスクリプトエラーを直して`.
4. Verify recording does not start again while already recording.
5. Verify the preview appears after transcription.
6. Verify raw transcript is visible.
7. Verify corrected prompt normalizes expected developer terms such as `Claude Code` and `TypeScript`.
8. Edit the corrected prompt if needed.
9. Confirm paste.
10. If Accessibility is trusted, verify the prompt is pasted into the focused target.
11. If Accessibility is not trusted, verify the app copies the prompt and asks the user to press Command-V.
12. Verify the prompt is not automatically submitted.

## Local Learning

1. Approve at least one non-dangerous candidate.
2. Run another mock or real preview using the same spoken form.
3. Verify the approved dictionary entry affects normalization.
4. Reject or leave unselected any dangerous command candidate and verify it is not auto-applied by default.

## Local Data Controls

1. Choose `Export Local Dictionary...` and save a JSON file.
2. Verify the exported JSON contains approved dictionary entries only.
3. Choose `Import Local Dictionary...` and import the JSON file.
4. Choose `Open Local Data Folder...` and verify the Application Support folder opens.
5. Choose `Delete Local Dictionary...`.
6. Verify later previews no longer use deleted local entries unless they come from seed or repository vocabulary.

## Repository Vocabulary

1. Choose `Set Repository Folder...`.
2. Select a Git repository folder.
3. Trigger a preview containing the repository name, branch name, or tracked file name.
4. Verify repository-scoped vocabulary can appear in the corrected prompt.

## Privacy

1. Verify no raw audio file remains in the selected repository after recording.
2. Verify raw transcripts are not written to Application Support by default.
3. Verify approved dictionary entries and settings are local files only.
