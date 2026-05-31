SWIFT_PACKAGE_FLAGS ?= --disable-sandbox
CLANG_MODULE_CACHE_PATH ?= $(CURDIR)/.build/clang-module-cache
export CLANG_MODULE_CACHE_PATH

.PHONY: test eval check goal demo manual-e2e-report validate-manual-e2e-report clean xcode-test-env

xcode-test-env:
	python3 scripts/require_xcode_xctest.py

test: xcode-test-env
	swift test $(SWIFT_PACKAGE_FLAGS)

eval: xcode-test-env
	swift test $(SWIFT_PACKAGE_FLAGS) --filter EvalHarnessTests

check: xcode-test-env
	swift test $(SWIFT_PACKAGE_FLAGS)
	python3 scripts/smoke_demo_command.py .
	swift build $(SWIFT_PACKAGE_FLAGS) --product voice-agent-input-app
	python3 scripts/build_app_bundle.py .
	python3 scripts/smoke_launch_app_bundle.py .
	python3 scripts/validate_required_files.py .
	python3 scripts/validate_component_contracts.py .
	python3 scripts/validate_architecture_refactor.py .
	python3 scripts/validate_eval_coverage.py .
	python3 scripts/validate_architecture_boundaries.py .
	python3 scripts/validate_app_ui_split.py .
	python3 scripts/validate_app_contract.py .
	python3 scripts/validate_privacy_contract.py .
	python3 scripts/validate_mvp_coverage.py .
	python3 scripts/validate_learning_goal_audit.py .
	python3 scripts/validate_manual_e2e_checklist.py .

goal:
	cat .codex/goals/voice-agent-input-full-build.md

demo:
	swift run voice-agent-input-demo "くらのコードでタイプスクリプトエラーを直して"

manual-e2e-report:
	python3 scripts/create_manual_e2e_report.py .

validate-manual-e2e-report:
	@test -n "$(REPORT)" || (echo "usage: make validate-manual-e2e-report REPORT=test/e2e/reports/<report>.md" >&2; exit 1)
	python3 scripts/validate_manual_e2e_report.py "$(REPORT)"

clean:
	rm -rf .build
