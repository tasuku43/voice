SWIFT_PACKAGE_FLAGS ?= --disable-sandbox
CLANG_MODULE_CACHE_PATH ?= $(CURDIR)/.build/clang-module-cache
export CLANG_MODULE_CACHE_PATH

.PHONY: test eval check goal demo clean xcode-test-env

xcode-test-env:
	python3 scripts/require_xcode_xctest.py

test: xcode-test-env
	swift test $(SWIFT_PACKAGE_FLAGS)

eval: xcode-test-env
	swift test $(SWIFT_PACKAGE_FLAGS) --filter EvalHarnessTests

check: xcode-test-env
	swift test $(SWIFT_PACKAGE_FLAGS)
	swift build $(SWIFT_PACKAGE_FLAGS) --product voice-agent-input-app
	python3 scripts/build_app_bundle.py .
	python3 scripts/validate_required_files.py .

goal:
	cat .codex/goals/voice-agent-input-full-build.md

demo:
	swift run voice-agent-input-demo "くらのコードでタイプスクリプトエラーを直して"

clean:
	rm -rf .build
