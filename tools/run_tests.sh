#!/usr/bin/env bash
# Runs the headless GDScript test suite. Override the engine path with GODOT=...
# Prints only failures, script errors and the summary; full log in .godot/test_output.log.
# Pass -v to print the full log instead.
set -uo pipefail
GODOT="${GODOT:-/c/GoDot/Godot_v4.7.2-stable_win64.exe}"
cd "$(dirname "$0")/.."
LOG=.godot/test_output.log
# --import refreshes the class_name cache so new scripts are visible to the runner.
"$GODOT" --headless --path . --import >/dev/null 2>&1
"$GODOT" --headless --path . --script res://tests/run_tests.gd >"$LOG" 2>&1
status=$?
if [[ "${1:-}" == "-v" ]]; then
	cat "$LOG"
else
	# First 8 distinct engine/script errors (context for failures), then every FAIL and the summary.
	grep -E 'SCRIPT ERROR|^ERROR' "$LOG" | sort -u | head -8
	grep -E '^(FAIL|    [^ ])|passed, [0-9]+ failed' "$LOG"
fi
exit $status
