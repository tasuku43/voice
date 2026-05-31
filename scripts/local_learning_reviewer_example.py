#!/usr/bin/env python3
"""Example local learning reviewer command.

The app sends JSON on stdin:
  {"candidates": [...], "diff": {...}}

The command must return JSON on stdout:
  {"candidates": [...]}

This sample is intentionally deterministic and local-only. Replace its body with
a trusted local model call if you want LLM-style candidate review.
"""

import json
import sys


def review_candidate(candidate: dict, diff: dict) -> dict:
    reviewed = dict(candidate)
    raw = reviewed.get("rawPhrase", "")
    corrected = reviewed.get("correctedPhrase", "")
    final_text = diff.get("finalEditedText", "")
    dangerous = bool(reviewed.get("dangerous", False))

    if raw and corrected and corrected in final_text:
        reviewed["confidence"] = min(0.9, max(float(reviewed.get("confidence", 0.0)), 0.78))
        reviewed["reason"] = (
            "Local reviewer: raw phrase appeared in the transcript and the "
            "corrected phrase appears in the confirmed prompt."
        )

    if dangerous:
        reviewed["confidence"] = min(0.4, float(reviewed.get("confidence", 0.0)))
        reviewed["autoApplyAllowed"] = False

    return reviewed


def main() -> int:
    payload = json.load(sys.stdin)
    diff = payload.get("diff", {})
    candidates = payload.get("candidates", [])
    reviewed = [review_candidate(candidate, diff) for candidate in candidates]
    json.dump({"candidates": reviewed}, sys.stdout, ensure_ascii=False)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
