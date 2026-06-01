# Manual macOS MVP report

Copy this template when running `manual-macos-mvp-checklist.md` on a real macOS desktop session. Keep the completed report with release or PR evidence.

## Run Metadata

- Date:
- Tester:
- macOS version:
- Hardware:
- Build command: `make check`
- App path: `.build/VoiceAgentInput.app`
- Target text app:
- Accessibility trusted: yes/no
- Microphone status before run:
- Speech recognition status before run:

## Summary

- Overall result: pass/fail
- Blocking failures:
- Follow-up issues:

## Setup Evidence

- Voice menu bar item appears: pass/fail
- Target text app focused: pass/fail
- Debug launch used `--debug`: pass/fail
- Debug log created at `~/Library/Logs/VoiceAgentInput/debug.log`: pass/fail
- Notes:

## Permission Status Evidence

- `Permission Status...` opened: pass/fail
- Microphone shown: pass/fail
- Speech recognition shown: pass/fail
- Accessibility paste shown: pass/fail
- Input monitoring hotkeys shown: pass/fail
- `Open Voice Input Permissions...` opens missing permission settings: pass/fail
- `Open Privacy Settings...` opens Privacy & Security: pass/fail
- macOS permission prompts observed when needed: pass/fail/not applicable
- Notes:

## Recording Settings Evidence

- `Recording Settings...` opened: pass/fail
- Recording duration saved and reloaded: pass/fail
- Speech locale saved and reloaded: pass/fail
- `Voice Input Mode...` opened: pass/fail
- Default mode is Quick Paste: pass/fail
- Learning Preview mode saved and reloaded: pass/fail
- Mode switched back to Quick Paste before daily flow: pass/fail
- `Hotkey Settings...` opened: pass/fail
- Custom voice input hotkey saved and menu label updated: pass/fail
- Custom voice input hotkey starts recording: pass/fail
- Toggle Recording mode starts and stops from the same hotkey: pass/fail
- Default Control-Option-Space Press and Hold restored before mode flows: pass/fail
- Notes:

## Mock Preview Safety Evidence

- `Mock Preview` opened: pass/fail
- Raw transcript visible: pass/fail
- Corrected prompt visible: pass/fail
- Edited prompt inserted only after confirmation: pass/fail
- No automatic submit: pass/fail
- Dictionary candidates shown when expected: pass/fail
- Notes:

## Quick Paste Voice Input Evidence

- Control-Option-Space trigger works: pass/fail
- `Quick Paste Voice Input` menu action works: pass/fail
- Recording reentry is blocked while recording: pass/fail
- Speech transcription completes: pass/fail
- Push-to-talk release or stop explicitly confirms paste: pass/fail
- Toggle hotkey stop explicitly confirms paste: pass/fail
- No raw/corrected preview window appears in Quick Paste: pass/fail
- No dictionary candidate approval UI appears in Quick Paste: pass/fail
- Pasted or copied prompt contains expected developer terms: pass/fail
- Debug log contains mode=quickPaste for completed recording: pass/fail
- Debug log summary includes mode=quickPaste: pass/fail
- Confirm paste works with Accessibility trusted: pass/fail/not applicable
- Pasteboard fallback works without Accessibility trust: pass/fail/not applicable
- No automatic submit: pass/fail
- Notes:

## Learning Preview Voice Input Evidence

- Learning Preview mode selected: pass/fail
- Control-Option-Space trigger works in Learning Preview: pass/fail
- `Record Learning Preview` menu action works in Learning Preview: pass/fail
- Speech transcription completes: pass/fail
- Raw transcript visible: pass/fail
- Corrected prompt contains expected developer terms: pass/fail
- Edited prompt inserted only after preview confirmation: pass/fail
- Dictionary candidates shown only after preview confirmation when expected: pass/fail
- Debug log contains mode=learningPreview for completed recording: pass/fail
- Debug log summary includes mode=learningPreview: pass/fail
- No automatic submit: pass/fail
- Mode switched back to Quick Paste after learning flow: pass/fail
- Notes:

## Local Learning Evidence

- Non-dangerous candidate approved: pass/fail
- Approved candidate reused later: pass/fail
- Dangerous command candidate not auto-applied by default: pass/fail
- Learning Preview edit-derived candidate uses user scope by default even when repository folder is configured: pass/fail
- Rebuild Local Context Model works without candidate approval and shows rebuild metadata: pass/fail
- Local Context Model Status shows last rebuild metadata and stale-source warnings without rebuilding: pass/fail
- Rebuilt Local Context Model affects later Quick Paste normalization without candidate approval: pass/fail
- Notes:

## Local Data Controls Evidence

- Export Local Dictionary works: pass/fail
- Export contains approved dictionary entries only: pass/fail
- Import Local Dictionary works: pass/fail
- Export Local Context Model works: pass/fail
- Exported Local Context Model contains schemaVersion, model, lastRebuiltAt, and sourceKinds: pass/fail
- Import Local Context Model works: pass/fail
- Open Local Data Folder works: pass/fail
- Delete Local Dictionary works: pass/fail
- Delete Local Context Model works: pass/fail
- Deleted local entries no longer affect later previews: pass/fail
- Notes:

## Repository Vocabulary Evidence

- Set Repository Folder works: pass/fail
- Repository name, branch, or tracked file vocabulary appears: pass/fail
- Repository-scoped vocabulary does not require a broad recursive scan: pass/fail
- Notes:

## Privacy Evidence

- No raw audio remains in selected repository: pass/fail
- Raw transcripts are not written to Application Support by default: pass/fail
- Approved dictionary entries and settings are local files only: pass/fail
- Debug log is diagnostics only, not local learning data: pass/fail
- No network/cloud prompt observed: pass/fail
- Notes:

## Attachments

- Screenshots:
- Exported dictionary path:
- Completed checklist path:
- Related issue or PR:
