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
4. Choose `Open Privacy Settings...` and verify macOS opens Privacy & Security settings.
5. If microphone or speech recognition is not authorized, continue to the recording flow and verify macOS prompts for the missing permission.
6. If Accessibility paste is not trusted, keep the fallback behavior expectation below.

## Recording Settings

1. Choose `Recording Settings...`.
2. Set recording duration to `4`.
3. Set Speech locale to `ja-JP`.
4. Save the dialog.
5. Reopen `Recording Settings...` and verify the saved values are shown.
6. Choose `Voice Input Mode...`.
7. Verify the default mode is `Quick Paste`.
8. Switch to `Learning Preview`, save, reopen, and verify the saved mode is shown.
9. Switch back to `Quick Paste` before running the daily input flow below.
10. Choose `Hotkey Settings...`.
11. Change the voice input key to Control-Option-S, save, and verify the menu label updates.
12. Trigger voice input with Control-Option-S, then stop it with the Stop button.
13. Reopen `Hotkey Settings...`, switch trigger mode to `Toggle Recording`, and save.
14. Trigger voice input with Control-Option-S, then press Control-Option-S again and verify the toggle stop explicitly confirms paste.
15. Reopen `Hotkey Settings...` and restore Control-Option-Space with `Press and Hold` before the mode-specific flows below.

## Mock Preview Safety

1. Choose `Mock Preview`.
2. Verify the preview shows both raw transcript and corrected prompt.
3. Edit the corrected prompt.
4. Confirm paste.
5. Verify no automatic submit happens in the target app.
6. Verify dictionary candidates are shown for approval when the edit creates candidates.

## Quick Paste Voice Input

1. Focus the target text app.
2. Trigger voice input with Control-Option-Space or choose `Quick Paste Voice Input` while mode is `Quick Paste`.
3. Verify the cursor-adjacent recording HUD appears near the focused input when Accessibility can locate the caret, shows elapsed time, shows live input-level movement while speaking, and says `Release shortcut to paste` in press-and-hold mode.
4. Speak a short Japanese / mixed developer instruction such as `くらのコードでタイプスクリプトエラーを直して`.
5. Verify recording does not start again while already recording.
6. Release the push-to-talk shortcut or stop recording and verify that this explicit stop acts as the confirmation for paste.
7. Verify no raw/corrected preview window appears in `Quick Paste`.
8. Verify no dictionary candidate approval UI appears in `Quick Paste`.
9. Verify the pasted or copied prompt normalizes expected developer terms such as `Claude Code` and `TypeScript`.
10. Verify the debug log contains `mode=quickPaste` for the completed recording.
11. Run `python3 scripts/summarize_debug_log.py` and keep the `mode=quickPaste` summary for the report.
12. If Accessibility is trusted, verify the prompt is pasted into the focused target.
13. If Accessibility is not trusted, verify the app copies the prompt and asks the user to press Command-V.
14. Verify the prompt is not automatically submitted.
15. Switch to `Toggle Recording` in `Hotkey Settings...`, start with Control-Option-Space, verify the HUD says `Press shortcut again to paste`, press Control-Option-Space again, and verify the toggle stop acts as explicit paste confirmation.
16. Restore `Press and Hold` in `Hotkey Settings...`.

## Learning Preview Voice Input

1. Choose `Voice Input Mode...`, switch to `Learning Preview`, and focus the target text app.
2. Trigger voice input with Control-Option-Space or choose `Record Learning Preview`.
3. Speak a short Japanese / mixed developer instruction such as `くらのコードでタイプスクリプトエラーを直して`.
4. Verify the preview appears after transcription.
5. Verify raw transcript is visible.
6. Verify corrected prompt normalizes expected developer terms such as `Claude Code` and `TypeScript`.
7. Edit the corrected prompt if needed.
8. Confirm paste.
9. Verify dictionary candidates are shown for approval only after preview confirmation when the edit creates candidates.
10. Verify the debug log contains `mode=learningPreview` for the completed recording.
11. Run `python3 scripts/summarize_debug_log.py` and keep the `mode=learningPreview` summary for the report.
12. Verify the prompt is not automatically submitted.
13. Switch back to `Quick Paste` after the learning flow.

## Local Learning

1. Approve at least one non-dangerous candidate.
2. Run another mock or real preview using the same spoken form.
3. Verify the approved dictionary entry affects normalization.
4. Reject or leave unselected any dangerous command candidate and verify it is not auto-applied by default.
5. With a repository folder configured, edit a `Learning Preview` prompt so it creates a candidate and verify the candidate is still suggested with user scope by default.
6. Choose `Rebuild Local Context Model...`, select `Codex / Claude local sessions` and, when configured, `Git repository vocabulary`, then verify the model is rebuilt without opening candidate approval and the summary shows the rebuild time and source kinds.
7. Choose `Local Context Model Status...` and verify the saved status shows the last rebuild time, source kinds, source text counts, generated candidates, runtime entry count, and stale-source warnings without rebuilding.
8. Verify later Quick Paste runs can use entries from the rebuilt local context model without opening candidate approval.

## Local Data Controls

1. Choose `Export Local Dictionary...` and save a JSON file.
2. Verify the exported JSON contains approved dictionary entries only.
3. Choose `Import Local Dictionary...` and import the JSON file.
4. Choose `Export Local Context Model...` and save a JSON file.
5. Verify the exported JSON contains `schemaVersion`, `model`, `lastRebuiltAt`, and `sourceKinds`.
6. Choose `Import Local Context Model...` and import the JSON file.
7. Choose `Open Local Data Folder...` and verify the Application Support folder opens.
8. Choose `Delete Local Dictionary...`.
9. Choose `Delete Local Context Model...`.
10. Verify later previews no longer use deleted local entries unless they come from seed or a rebuilt local context model.

## Repository Vocabulary

1. Choose `Set Repository Folder...`.
2. Select a Git repository folder.
3. Trigger a preview containing the repository name, branch name, or tracked file name.
4. Verify repository vocabulary appears only after explicit learning approval, not merely because a repository folder is configured.

## Privacy

1. Verify no raw audio file remains in the selected repository after recording.
2. Verify raw transcripts are not written to Application Support by default.
3. Verify approved dictionary entries and settings are local files only.
4. Verify `debug.log` contains operational diagnostics only and does not become the local learning data source.
