.PHONY: test eval check goal demo clean xcode-test-env

xcode-test-env:
	python3 scripts/require_xcode_xctest.py

test: xcode-test-env
	swift test

eval: xcode-test-env
	swift test --filter EvalHarnessTests

check: xcode-test-env
	swift test
	python3 scripts/validate_required_files.py .

goal:
	cat .codex/goals/voice-agent-input-full-build.md

demo:
	swift run voice-agent-input-demo "くらのコードでタイプスクリプトエラーを直して"

clean:
	rm -rf .build
