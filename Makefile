.PHONY: test eval check goal demo clean

test:
	swift test

eval:
	swift test --filter EvalHarnessTests

check:
	swift test
	python3 scripts/validate_required_files.py .

goal:
	cat .codex/goals/voice-agent-input-full-build.md

demo:
	swift run voice-agent-input-demo "くらのコードでタイプスクリプトエラーを直して"

clean:
	rm -rf .build
