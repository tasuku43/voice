# Manual macOS MVP checklist

Use this checklist on a real macOS desktop session after `make check` builds `.build/VoiceAgentInput.app`.

## Setup

1. Open `.build/VoiceAgentInput.app` with debug logging enabled:
   `make manual-e2e-launch`
   or `open -n .build/VoiceAgentInput.app --args --debug`
2. Confirm the menu bar item titled `Voice` appears.
3. Open a text target such as TextEdit, Codex, Claude Code, Cursor, or a terminal prompt.
4. Confirm `~/Library/Logs/VoiceAgentInput/debug.log` is created.
5. Keep the debug log available for the mode-specific checks below.

## Permission Status

1. Choose `Permission Status...`.
2. Verify the dialog reports:
   - `Microphone`
   - `Speech recognition`
   - `Accessibility paste`
   - `Input monitoring hotkeys`
3. Choose `Open Voice Input Permissions...` and verify macOS opens the missing Accessibility and/or Input Monitoring settings.
4. If microphone or speech recognition is not authorized, continue to the recording flow and verify macOS prompts for the missing permission.
5. If Accessibility paste is not trusted, keep the fallback behavior expectation below.

## Hotkey Settings

1. Choose `Hotkey Settings...`.
2. Change the voice input key to Control-Option-S, save, and verify the menu label updates.
3. Trigger voice input with Control-Option-S, then release the shortcut or stop it with the Stop button.
4. Reopen `Hotkey Settings...` and restore Control-Option-Space before the Quick Paste flow below.

## Quick Paste Voice Input

1. Focus the target text app.
2. Trigger voice input with Control-Option-Space or choose `Quick Paste Voice Input`.
3. Verify the cursor-adjacent recording HUD appears near the focused input when Accessibility can locate the caret, shows elapsed time, shows live input-level movement while speaking, and says `Release shortcut to paste` in press-and-hold mode.
4. Speak a short Japanese / mixed developer instruction such as `くらのコードでタイプスクリプトエラーを直して`.
5. Verify recording does not start again while already recording.
6. Release the push-to-talk shortcut or stop recording and verify that this explicit stop acts as the confirmation for paste.
7. Verify no raw/corrected preview window appears in `Quick Paste`.
8. Verify no review/approval UI appears in `Quick Paste`.
9. Verify the pasted or copied prompt normalizes expected developer terms such as `Claude Code` and `TypeScript`.
10. Verify the debug log contains `mode=quickPaste` for the completed recording.
11. Run `python3 scripts/summarize_debug_log.py` and keep the `mode=quickPaste` summary for the report.
12. If Accessibility is trusted, verify the prompt is pasted into the focused target.
13. If Accessibility is not trusted, verify the app copies the prompt and asks the user to press Command-V.
14. Verify the prompt is not automatically submitted.

## Local Learning

1. Choose `Model Education` -> `Rebuild Local Context Model...`, select `Codex / Claude local sessions` and, when configured, `Git repository vocabulary`, then verify the model is rebuilt without opening review/approval UI and the summary shows the rebuild time and source kinds.
2. Verify the rebuild summary shows the last rebuild time, source kinds, source text counts, generated entries, and runtime entry count.
3. Verify later Quick Paste runs can use entries from the rebuilt local context model without opening review/approval UI.

## Local Data Controls

1. Choose `Model Education` -> `Export Local Context Model...` and save a JSON file.
2. Verify the exported JSON contains `schemaVersion`, `model`, `lastRebuiltAt`, and `sourceKinds`.
3. Choose `Model Education` -> `Import Local Context Model...` and import the JSON file.
4. Choose `Model Education` -> `Open Local Data Folder...` and verify the Application Support folder opens.
5. Choose `Model Education` -> `Delete Local Context Model...`.
6. Verify later Quick Paste runs no longer use deleted local model entries unless they come from seed terms or a rebuilt local context model.

## Repository Vocabulary

1. Choose `Model Education` -> `Set Repository Folder...`.
2. Select a Git repository folder.
3. Choose `Model Education` -> `Rebuild Local Context Model...` with `Git repository vocabulary` selected.
4. Trigger Quick Paste containing the repository name, branch name, or tracked file name.
5. Verify repository vocabulary appears only after an explicit model rebuild, not merely because a repository folder is configured.

## Privacy

1. Verify no raw audio file remains in the selected repository after recording.
2. Verify raw transcripts are not written to Application Support by default.
3. Verify settings and local context model data are local files only.
4. Verify `debug.log` contains operational diagnostics only and does not become the local learning data source.
5. Run `make manual-e2e-privacy-inspect` and keep the `manual E2E privacy inspection ok` output for the report.
